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
    
    def generate_question_batch(self, subject_data: Dict[str, Any], 
                               subtopic_data: Dict[str, Any], 
                               batch_number: int, batch_size: int = 5) -> List[Dict[str, Any]]:
        """Generate a batch of questions for a specific subtopic"""
        
        subject_id = subject_data['id']
        subject_name = subject_data['display_name']
        subtopic_id = subtopic_data['id']
        subtopic_name = subtopic_data['display_name']
        syllabus_points = subtopic_data.get('syllabus', [])
        
        # Determine difficulty distribution for this batch
        start_question = (batch_number - 1) * batch_size + 1
        end_question = start_question + batch_size - 1
        
        # Create difficulty distribution for batch
        difficulties = []
        for q_num in range(start_question, end_question + 1):
            if q_num <= 7:
                difficulties.append("Easy")
            elif q_num <= 14:
                difficulties.append("Medium")
            else:
                difficulties.append("Hard")
        
        difficulty_counts = {d: difficulties.count(d) for d in set(difficulties)}
        difficulty_desc = ", ".join([f"{count} {diff}" for diff, count in difficulty_counts.items()])
        
        # Create system prompt for batch generation
        system_prompt = f"""
        You are an expert curriculum designer for Singapore Primary 6 Mathematics.
        Generate {batch_size} diverse, high-quality math problems for the subtopic: {subtopic_name}
        
        CRITICAL REQUIREMENTS:
        1. STRICTLY follow Singapore MOE Primary 6 Mathematics syllabus
        2. Address these specific syllabus points:
           {chr(10).join(f"   - {point}" for point in syllabus_points)}
        3. Each question must be different from the others
        4. Use varied contexts, scenarios, and problem structures
        5. Distribute difficulty: {difficulty_desc}
        6. Include proper AI guidance with hints and misconception handling
        7. Return ONLY a JSON array of {batch_size} question objects
        
        DIVERSITY REQUIREMENTS:
        - Use different real-world contexts for each question
        - Vary the mathematical operations and problem types
        - Test different aspects of the syllabus points
        - Ensure no two questions are similar in structure or context
        
        OUTPUT FORMAT: Return ONLY a valid JSON array with {batch_size} objects, each with this structure:
        {{
            "id": "WILL_BE_SET_AUTOMATICALLY",
            "sub_topic": "{subtopic_name}",
            "title": "Unique descriptive title",
            "complexity": "Easy|Medium|Hard",
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
        Generate {batch_size} diverse questions for {subtopic_name}.
        
        This is batch #{batch_number} (questions {start_question}-{end_question} of 20).
        Difficulty distribution: {difficulty_desc}
        
        SYLLABUS FOCUS:
        Each question should address different aspects of these MOE syllabus points:
        {chr(10).join(f"- {point}" for point in syllabus_points)}
        
        DIVERSITY REQUIREMENTS:
        - Question 1: Use one context/scenario type
        - Question 2: Use a completely different context
        - Question 3: Test a different mathematical aspect
        - Question 4: Use different problem structure
        - Question 5: Apply different real-world application
        
        CONTEXT REQUIREMENTS:
        - Use varied, relatable settings appropriate to children
        - Appropriate for Primary 6 students (age 11-12)
        - Different real-world applications that make sense
        
        Return ONLY the JSON array of {batch_size} objects, no other text, no explanations.
        """
        
        try:
            print(f"    🤖 Generating batch {batch_number} ({batch_size} questions) for {subtopic_name}...")
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
                questions_array = json.loads(content)
                if not isinstance(questions_array, list):
                    print(f"    ❌ Expected JSON array, got {type(questions_array)}")
                    return []
                    
            except json.JSONDecodeError as json_error:
                batch_id = f"{subject_id.upper()}-{subtopic_id.upper()}-BATCH{batch_number}"
                print(f"    ❌ JSON parsing error for {batch_id}: {json_error}")
                
                # Save debug file with batch ID
                debug_filename = f"debug_{batch_id.replace('-', '_').lower()}.txt"
                with open(debug_filename, "w") as debug_file:
                    debug_file.write(f"Batch ID: {batch_id}\n")
                    debug_file.write(f"Subtopic: {subtopic_name}\n")
                    debug_file.write(f"Expected: {batch_size} questions\n")
                    debug_file.write(f"Error: {json_error}\n")
                    debug_file.write(f"Content:\n{content}")
                print(f"    📄 Debug saved to: {debug_filename}")
                return []
            
            # Validate and fix each question in the batch
            validated_questions = []
            for i, question in enumerate(questions_array):
                if not isinstance(question, dict):
                    print(f"    ⚠️  Skipping non-dict question {i+1}")
                    continue
                    
                # Set question ID based on batch position
                question_number = start_question + i
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
                
                validated_questions.append(question)
                print(f"    ✅ Question {question_number}: {question.get('title', 'No title')}")
            
            print(f"    📊 Batch complete: {len(validated_questions)}/{batch_size} questions generated")
            return validated_questions
            
        except Exception as e:
            batch_id = f"{subject_id.upper()}-{subtopic_id.upper()}-BATCH{batch_number}"
            print(f"    ❌ Batch generation failed for {batch_id}: {e}")
            return []
    
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
            
            # Generate 20 questions in batches of 5
            batch_size = 5
            total_batches = 4  # 20 questions / 5 per batch = 4 batches
            
            for batch_num in range(1, total_batches + 1):
                batch_questions = self.generate_question_batch(
                    subject_data, 
                    subtopic_data, 
                    batch_num,
                    batch_size
                )
                
                if batch_questions:
                    subtopic_questions.extend(batch_questions)
                    total_questions += len(batch_questions)
                    print(f"    ✅ Batch {batch_num}/4: Generated {len(batch_questions)} questions")
                else:
                    print(f"    ❌ Failed to generate batch {batch_num}/4")
                
                # Brief pause between batches
                time.sleep(2)
                
                # Save progress after each batch
                if batch_questions:
                    curriculum["questions"].extend(batch_questions)
                    progress_filename = f"{subject_id}_progress.json"
                    with open(progress_filename, 'w', encoding='utf-8') as f:
                        json.dump(curriculum, f, indent=2, ensure_ascii=False)
                    print(f"    💾 Progress saved: {total_questions} total questions")
            
            # All questions already added to curriculum during batch processing
            
            print(f"    📊 Subtopic complete: {len(subtopic_questions)}/20 questions generated")
            
            # Validate we got exactly 20 questions
            if len(subtopic_questions) < 20:
                print(f"    ⚠️  Warning: Only generated {len(subtopic_questions)} questions instead of 20")
            
            # Longer pause between subtopics (reduced since we have fewer API calls)
            time.sleep(5)
        
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