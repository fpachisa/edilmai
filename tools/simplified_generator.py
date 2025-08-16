"""
Simplified Problem Generator for PSLE AI Tutor
Generates 20 questions per subtopic using simplified_problem_structure.json format
Uses p6_maths_topics.json for syllabus data and subtopic definitions
"""

import json
import os
import sys
from typing import Dict, List, Any, Optional
import google.generativeai as genai
from datetime import datetime
import time
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()


class SimplifiedProblemGenerator:
    """Generate problems using simplified structure from p6_maths_topics.json"""
    
    def __init__(self):
        # Initialize Gemini AI
        google_api_key = os.getenv('GOOGLE_API_KEY')
        if not google_api_key:
            raise ValueError("GOOGLE_API_KEY not found in .env file")
        
        genai.configure(api_key=google_api_key)
        self.model = genai.GenerativeModel('gemini-2.5-flash')
        
        # Load syllabus data
        self.topics_data = self._load_topics_data()
        
        # Load simplified structure template
        self.structure_template = self._load_structure_template()
    
    def _load_topics_data(self) -> Dict[str, Any]:
        """Load p6_maths_topics.json"""
        topics_path = os.path.join(os.path.dirname(__file__), '..', 'client', 'assets', 'p6_maths_topics.json')
        try:
            with open(topics_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except FileNotFoundError:
            raise FileNotFoundError(f"p6_maths_topics.json not found at {topics_path}")
    
    def _load_structure_template(self) -> Dict[str, Any]:
        """Load simplified_problem_structure.json template"""
        template_path = os.path.join(os.path.dirname(__file__), '..', 'simplified_problem_structure.json')
        try:
            with open(template_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except FileNotFoundError:
            raise FileNotFoundError(f"simplified_problem_structure.json not found at {template_path}")
    
    def generate_single_question(self, subject_data: Dict[str, Any], 
                               subtopic_data: Dict[str, Any], 
                               question_number: int) -> Optional[Dict[str, Any]]:
        """Generate a single question for a specific subtopic"""
        
        subject_id = subject_data['id']
        subject_name = subject_data['display_name']
        subtopic_id = subtopic_data['id']
        subtopic_name = subtopic_data['display_name']
        syllabus_points = subtopic_data.get('syllabus', [])
        
        # Determine difficulty based on question number
        if question_number <= 7:
            difficulty = "Easy"
        elif question_number <= 14:
            difficulty = "Medium"
        else:
            difficulty = "Hard"
        
        # Create system prompt for single question
        system_prompt = f"""
        You are an expert curriculum designer for Singapore Primary 6 Mathematics.
        Generate 1 high-quality math problem for the subtopic: {subtopic_name}
        
        CRITICAL REQUIREMENTS:
        1. STRICTLY follow Singapore MOE Primary 6 Mathematics syllabus
        2. Address these specific syllabus points:
           {chr(10).join(f"   - {point}" for point in syllabus_points)}
        3. Use natural, relatable contexts
        4. Difficulty level: {difficulty}
        5. Include proper AI guidance with hints and misconception handling
        6. Return ONLY a single JSON object (NOT an array)
        
        SUBJECT CONTEXT: {subject_name}
        SUBTOPIC: {subtopic_name}
        QUESTION NUMBER: {question_number} (of 20)
        DIFFICULTY: {difficulty}
        
        SYLLABUS REQUIREMENTS TO COVER:
        {chr(10).join(f"- {point}" for point in syllabus_points)}
        
        OUTPUT FORMAT: Return ONLY a single valid JSON object with this exact structure:
        {{
            "id": "{subject_id.upper()}-{subtopic_id.upper()}-Q{question_number}",
            "sub_topic": "{subtopic_name}",
            "title": "Descriptive title",
            "complexity": "{difficulty}",
            "problem_text": "Clear problem statement with child friendly context",
            "asset": {{
                "image_url": null,
                "svg_code": null
            }},
            "marks": 1,
            "answer_details": {{
                "correct_answer": "primary answer",
                "alternative_answers": [
                    "alternative format 1",
                    "alternative format 2"
                ],
                "answer_format": "numeric|expression|text"
            }},
            "ai_guidance": {{
                "evaluation_strategy": "How to evaluate student answers",
                "keywords": ["relevant", "terms", "for", "topic"],
                "common_misconceptions": {{
                    "wrong_answer_1": "Explanation why this is wrong",
                    "wrong_answer_2": "Explanation why this is wrong"
                }},
                "hints": [
                    {{
                        "step": 1,
                        "hint_text": "First level hint"
                    }},
                    {{
                        "step": 2,
                        "hint_text": "Second level hint"
                    }},
                    {{
                        "step": 3,
                        "hint_text": "Final hint with answer guidance"
                    }}
                ],
                "full_solution": "Complete step-by-step solution"
            }}
        }}
        """
        
        user_prompt = f"""
        Generate 1 question for {subtopic_name}.
        
        This is question #{question_number} of 20.
        Difficulty level: {difficulty}
        
        SYLLABUS FOCUS:
        Address at least one of these MOE syllabus points:
        {chr(10).join(f"- {point}" for point in syllabus_points)}
        
        CONTEXT REQUIREMENTS:
        - Use relatable general settings appropriate to children
        - Appropriate for Primary 6 students (age 11-12)
        - Real-world applications that make sense
        
        Return ONLY the single JSON object, no other text, no explanations.
        """
        
        try:
            print(f"    🤖 Generating question {question_number} for {subtopic_name}...")
            response = self.model.generate_content([system_prompt, user_prompt])
            
            # Parse response
            content = response.text.strip()
            if content.startswith('```json'):
                content = content[7:-3].strip()
            elif content.startswith('```'):
                content = content[3:-3].strip()
            
            # Clean up common JSON issues more thoroughly
            import re
            # Remove trailing commas before closing brackets/braces (with possible whitespace)
            content = re.sub(r',\s*]', ']', content)  # Remove trailing commas before ]
            content = re.sub(r',\s*}', '}', content)  # Remove trailing commas before }
            # Remove any trailing commas at end of lines
            content = re.sub(r',\s*\n\s*([}\]])', r'\n\1', content)
            
            try:
                question = json.loads(content)
            except json.JSONDecodeError as json_error:
                question_id = f"{subject_id.upper()}-{subtopic_id.upper()}-Q{question_number}"
                print(f"    ❌ JSON parsing error for {question_id}: {json_error}")
                
                # Save debug file with question ID
                debug_filename = f"debug_{question_id.replace('-', '_').lower()}.txt"
                with open(debug_filename, "w") as debug_file:
                    debug_file.write(f"Question ID: {question_id}\n")
                    debug_file.write(f"Subtopic: {subtopic_name}\n")
                    debug_file.write(f"Error: {json_error}\n")
                    debug_file.write(f"Content:\n{content}")
                print(f"    📄 Debug saved to: {debug_filename}")
                return None
            
            # Validate and fix question structure
            question_id = f"{subject_id.upper()}-{subtopic_id.upper()}-Q{question_number}"
            question['id'] = question_id
            question.setdefault('marks', 1)
            question.setdefault('asset', {"image_url": None, "svg_code": None})
            
            # Validate answer_details structure
            if 'answer_details' not in question:
                question['answer_details'] = {
                    "correct_answer": "Answer needed",
                    "alternative_answers": [],
                    "answer_format": "text"
                }
            
            # Validate ai_guidance structure
            if 'ai_guidance' not in question:
                question['ai_guidance'] = {
                    "evaluation_strategy": "Direct comparison",
                    "keywords": [],
                    "common_misconceptions": {},
                    "hints": [],
                    "full_solution": "Solution needed"
                }
            
            print(f"    ✅ Generated: {question.get('title', 'No title')}")
            return question
            
        except Exception as e:
            question_id = f"{subject_id.upper()}-{subtopic_id.upper()}-Q{question_number}"
            print(f"    ❌ Question generation failed for {question_id}: {e}")
            return None
    
    def generate_subject_curriculum(self, subject_id: str) -> Dict[str, Any]:
        """Generate complete curriculum for one subject"""
        
        # Find subject data
        subject_data = None
        for subject in self.topics_data['subjects']:
            if subject['id'] == subject_id:
                subject_data = subject
                break
        
        if not subject_data:
            raise ValueError(f"Subject '{subject_id}' not found in p6_maths_topics.json")
        
        subject_name = subject_data['display_name']
        subtopics = subject_data['subtopics']
        
        print(f"\\n🚀 Generating {subject_name} curriculum...")
        print(f"📊 Subtopics: {len(subtopics)} | Questions per subtopic: 20")
        
        # Create curriculum structure
        curriculum = {
            "curriculum": "Singapore PSLE Mathematics",
            "topic": subject_name,
            "metadata": {
                "generated_at": datetime.now().isoformat(),
                "generator_version": "simplified-v1.0",
                "subject_id": subject_id,
                "total_subtopics": len(subtopics),
                "questions_per_subtopic": 20,
                "singapore_moe_aligned": True
            },
            "questions": []
        }
        
        total_questions = 0
        
        # Generate questions for each subtopic (one at a time)
        for subtopic_index, subtopic_data in enumerate(subtopics):
            subtopic_name = subtopic_data['display_name']
            print(f"\\n  📚 Processing: {subtopic_name}")
            
            subtopic_questions = []
            
            # Generate 20 questions one by one
            for question_num in range(1, 21):
                question = self.generate_single_question(
                    subject_data, 
                    subtopic_data, 
                    question_num
                )
                
                if question:
                    subtopic_questions.append(question)
                    total_questions += 1
                    print(f"    ✅ Question {question_num}/20: {question.get('title', 'Generated')}")
                else:
                    print(f"    ❌ Failed to generate question {question_num}/20")
                
                # Brief pause between questions
                time.sleep(1)
                
                # Save progress every 5 questions
                if len(subtopic_questions) % 5 == 0:
                    curriculum["questions"].extend(subtopic_questions[-5:])
                    progress_filename = f"{subject_id}_progress.json"
                    with open(progress_filename, 'w', encoding='utf-8') as f:
                        json.dump(curriculum, f, indent=2, ensure_ascii=False)
                    print(f"    💾 Progress saved: {total_questions} total questions")
            
            # Add remaining questions to curriculum
            remaining = len(subtopic_questions) % 5
            if remaining > 0:
                curriculum["questions"].extend(subtopic_questions[-remaining:])
            
            print(f"    📊 Subtopic complete: {len(subtopic_questions)}/20 questions generated")
            
            # Longer pause between subtopics
            time.sleep(3)
        
        # Update metadata with final counts
        curriculum["metadata"]["total_questions"] = total_questions
        curriculum["metadata"]["completed_at"] = datetime.now().isoformat()
        
        # Final save
        final_filename = f"{subject_id}_simplified.json"
        with open(final_filename, 'w', encoding='utf-8') as f:
            json.dump(curriculum, f, indent=2, ensure_ascii=False)
        
        print(f"\\n✅ {subject_name} complete!")
        print(f"📊 Total questions: {total_questions}")
        print(f"💾 Saved to: {final_filename}")
        
        # Clean up progress file
        progress_file = f"{subject_id}_progress.json"
        if os.path.exists(progress_file):
            os.remove(progress_file)
        
        return curriculum
    
    def generate_all_subjects(self) -> None:
        """Generate curriculum for all subjects"""
        subjects = [subject['id'] for subject in self.topics_data['subjects']]
        
        print("🎯 Simplified Problem Generation Starting...")
        print(f"📊 Subjects: {len(subjects)} | Questions per subtopic: 20")
        print(f"🎯 Subjects to process: {', '.join(subjects)}")
        
        start_time = time.time()
        total_questions = 0
        completed_subjects = 0
        
        for subject_id in subjects:
            try:
                print(f"\\n{'='*60}")
                curriculum = self.generate_subject_curriculum(subject_id)
                total_questions += len(curriculum['questions'])
                completed_subjects += 1
                
                elapsed = time.time() - start_time
                print(f"⏱️  Elapsed time: {elapsed/60:.1f} minutes")
                print(f"📈 Progress: {completed_subjects}/{len(subjects)} subjects")
                
            except KeyboardInterrupt:
                print(f"\\n🛑 Generation stopped by user.")
                print(f"📊 Completed: {completed_subjects}/{len(subjects)} subjects")
                print(f"📊 Total questions: {total_questions}")
                break
            except Exception as e:
                print(f"❌ Failed to generate {subject_id}: {e}")
                continue
        
        total_time = time.time() - start_time
        print(f"\\n🎉 Generation Complete!")
        print(f"📊 Subjects completed: {completed_subjects}/{len(subjects)}")
        print(f"📊 Total questions generated: {total_questions}")
        print(f"⏱️  Total time: {total_time/60:.1f} minutes")
        if total_questions > 0:
            print(f"🚀 Average: {total_questions/(total_time/60):.1f} questions/minute")


def main():
    """Run simplified problem generation"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Generate simplified math problems')
    parser.add_argument('--subject', type=str, help='Generate for specific subject only')
    parser.add_argument('--list-subjects', action='store_true', help='List available subjects')
    
    args = parser.parse_args()
    
    generator = SimplifiedProblemGenerator()
    
    if args.list_subjects:
        print("Available subjects:")
        for subject in generator.topics_data['subjects']:
            subtopic_count = len(subject['subtopics'])
            print(f"  {subject['id']}: {subject['display_name']} ({subtopic_count} subtopics)")
        return
    
    if args.subject:
        generator.generate_subject_curriculum(args.subject)
    else:
        generator.generate_all_subjects()


if __name__ == "__main__":
    main()