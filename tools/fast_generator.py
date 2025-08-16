"""
Fast AI-Powered Curriculum Content Generator for PSLE AI Tutor
Optimized version: smaller batches, incremental saves, progress tracking
"""

import json
import os
import sys
from typing import Dict, List, Any, Optional
from dataclasses import dataclass
import google.generativeai as genai
from datetime import datetime
import time

# Add parent directory to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from api.core.config import settings


@dataclass
class SubjectSpec:
    """Specification for each P6 Math subject"""
    name: str
    target_problems: int
    learning_objectives: List[str]
    difficulty_progression: List[str]
    singapore_contexts: List[str]
    key_skills: List[str]


class FastCurriculumGenerator:
    """Optimized AI-powered curriculum generation"""
    
    def __init__(self):
        # Initialize Gemini AI
        if not settings.google_api_key:
            raise ValueError("GOOGLE_API_KEY required for content generation")
        
        genai.configure(api_key=settings.google_api_key)
        self.model = genai.GenerativeModel('gemini-2.5-flash')
        
        # Define P6 subject specifications (MOE-aligned)
        self.subjects = {
            'fractions': SubjectSpec(
                name='Fractions',
                target_problems=80,
                learning_objectives=[
                    'Divide proper fraction by whole number without calculator',
                    'Divide whole number by proper fraction without calculator', 
                    'Divide proper fraction by proper fraction without calculator',
                    'Use calculator for 4 operations with fractions including mixed numbers',
                    'Solve problems using part-whole and comparison models',
                    'Work in groups to solve multi-step and non-routine fraction problems'
                ],
                difficulty_progression=['Easy', 'Easy', 'Medium', 'Medium', 'Medium', 'Hard', 'Hard', 'Hard'],
                singapore_contexts=[
                    'Food portions and sharing', 'Birthday celebrations', 'School activities',
                    'Shopping and markets', 'Sports and games', 'Cooking and recipes',
                    'Art and craft projects', 'Library activities'
                ],
                key_skills=[
                    'fraction-division-by-whole', 'whole-division-by-fraction', 'fraction-division-by-fraction',
                    'calculator-fraction-operations', 'part-whole-models', 'comparison-models'
                ]
            ),
            
            'percentage': SubjectSpec(
                name='Percentage',
                target_problems=60,
                learning_objectives=[
                    'Find the whole given a part and the percentage using pictorial model',
                    'Find percentage increase/decrease and calculate percentage change',
                    'Solve word problems involving percentage using before-after concept',
                    'Use calculator to find percentage change through games and activities',
                    'Make connections between percentage of percentage and fraction of fraction'
                ],
                difficulty_progression=['Easy', 'Easy', 'Medium', 'Medium', 'Hard', 'Hard'],
                singapore_contexts=[
                    'Club membership changes', 'Savings and pocket money', 'School populations',
                    'Shopping discounts and taxes', 'Survey results', 'Weather data',
                    'Sports statistics', 'Academic performance'
                ],
                key_skills=[
                    'find-whole-from-percentage-part', 'percentage-increase-decrease', 'before-after-concept',
                    'calculator-percentage-games', 'percentage-of-percentage'
                ]
            ),
            
            'ratio': SubjectSpec(
                name='Ratio and Proportion',
                target_problems=60,
                learning_objectives=[
                    'Express ratio in its simplest form using HCF method',
                    'Solve 2-term and 3-term ratio problems using unitary method',
                    'Find equivalent ratios and use them to solve word problems',
                    'Apply ratio concepts to real-world situations with bar models',
                    'Solve problems involving changing ratios before and after'
                ],
                difficulty_progression=['Easy', 'Easy', 'Medium', 'Medium', 'Hard', 'Hard'],
                singapore_contexts=[
                    'Cooking ingredient ratios', 'Map scale calculations', 'Paint color mixing',
                    'Class compositions', 'Sports team formations', 'Recipe scaling',
                    'Model building', 'Survey comparisons'
                ],
                key_skills=[
                    'ratio-simplest-form', '2-term-ratio-problems', '3-term-ratio-problems',
                    'equivalent-ratios', 'unitary-method', 'changing-ratios', 'bar-model-ratios'
                ]
            ),
            
            'speed': SubjectSpec(
                name='Speed, Distance and Time',
                target_problems=50,
                learning_objectives=[
                    'Use formula Speed = Distance ÷ Time to solve problems',
                    'Calculate distance using Distance = Speed × Time formula',
                    'Calculate time using Time = Distance ÷ Speed formula',
                    'Convert between km/h and m/s using conversion factors',
                    'Solve average speed problems for journeys with multiple segments'
                ],
                difficulty_progression=['Easy', 'Medium', 'Medium', 'Hard', 'Hard'],
                singapore_contexts=[
                    'Train journeys', 'Bus routes and schedules', 'Walking and cycling',
                    'Airplane travel times', 'Swimming competitions', 'Running events',
                    'Delivery schedules', 'Traffic situations'
                ],
                key_skills=[
                    'speed-distance-time-formula', 'distance-calculation', 'time-calculation',
                    'kmh-to-ms-conversion', 'average-speed-calculation', 'multi-segment-journeys'
                ]
            ),
            
            'geometry': SubjectSpec(
                name='Geometry',
                target_problems=60,
                learning_objectives=[
                    'Calculate circumference of circles using C = πd or C = 2πr',
                    'Calculate area of circles using A = πr² with calculator',
                    'Find volume of cubes using V = a³ and cuboids using V = l×w×h',
                    'Identify and construct nets of cubes, cuboids, and triangular prisms',
                    'Apply circle and volume formulas to solve real-world problems'
                ],
                difficulty_progression=['Easy', 'Easy', 'Medium', 'Medium', 'Hard', 'Hard'],
                singapore_contexts=[
                    'Circular structures and designs', 'Playground equipment', 'Architecture',
                    'Swimming pools', 'Packaging boxes', 'Sports field measurements',
                    'Garden designs', 'Construction projects'
                ],
                key_skills=[
                    'circle-circumference-formula', 'circle-area-formula', 'cube-volume',
                    'cuboid-volume', 'nets-construction', 'composite-shape-areas'
                ]
            ),
            
            'statistics': SubjectSpec(
                name='Statistics and Pie Charts',
                target_problems=40,
                learning_objectives=[
                    'Read and interpret pie charts with sector angles and percentages',
                    'Calculate angles in pie charts using proportional reasoning',
                    'Convert between fractions, decimals and percentages in pie charts',
                    'Draw pie charts using protractor and compass for given data',
                    'Compare and analyze data presented in multiple pie charts'
                ],
                difficulty_progression=['Easy', 'Medium', 'Medium', 'Hard'],
                singapore_contexts=[
                    'School survey results', 'Population demographics', 'Weather patterns',
                    'Sports preferences', 'Food choices', 'Transport usage',
                    'Entertainment preferences', 'Academic subjects'
                ],
                key_skills=[
                    'pie-chart-interpretation', 'sector-angle-calculation', 'percentage-to-angle',
                    'pie-chart-construction', 'multiple-chart-comparison', 'data-problem-solving'
                ]
            )
        }
    
    def generate_problem_batch(self, subject_key: str, spec: SubjectSpec, 
                              start_index: int, batch_size: int = 5) -> List[Dict[str, Any]]:
        """Generate a small batch of problems (default 5)"""
        
        system_prompt = f"""
        You are an expert curriculum designer for Singapore Primary 6 Mathematics.
        Generate {batch_size} high-quality math problems for the topic: {spec.name}

        CRITICAL REQUIREMENTS:
        1. STRICTLY follow Singapore MOE Primary 6 Mathematics syllabus
        2. Align with official MOE learning objectives and outcomes
        3. Use natural, relatable contexts from everyday life
        4. Progressive difficulty: Easy → Medium → Hard
        5. Include Socratic questioning steps for guided learning
        6. Each problem must address specific MOE curriculum outcomes
        7. Problems must be culturally appropriate for Singapore P6 students

        MOE CURRICULUM ALIGNMENT FOR {spec.name}:
        These problems must align with the official Singapore Ministry of Education Primary 6 Mathematics syllabus.

        OFFICIAL MOE LEARNING OBJECTIVES FOR {spec.name}:
        {chr(10).join(f"- {obj}" for obj in spec.learning_objectives)}

        KEY SKILLS TO COVER (MOE-aligned):
        {chr(10).join(f"- {skill}" for skill in spec.key_skills)}

        CONTEXTUAL SETTINGS TO USE (vary naturally):
        {chr(10).join(f"- {context}" for context in spec.singapore_contexts)}

        OUTPUT FORMAT: Return ONLY valid JSON array with this exact structure:
        [
            {{
                "id": "{subject_key.upper()}-S1-E{start_index}",
                "topic": "{spec.name}",
                "title": "Clear descriptive title",
                "learn_step": 1,
                "complexity": "Easy|Medium|Hard",
                "difficulty": 0.3,
                "skill": "Main skill category",
                "subskills": ["specific-skill-1"],
                "estimated_time_seconds": 60,
                "problem_text": "Engaging problem with natural context",
                "student_view": {{
                    "socratic": true,
                    "steps": [
                        {{
                            "id": "S1",
                            "prompt": "Socratic question to guide thinking",
                            "answer_type": "free|numeric",
                            "acceptable_responses": [],
                            "hints": {{
                                "L1": "Gentle hint",
                                "L2": "More specific hint",
                                "L3": "Concrete hint with example"
                            }}
                        }}
                    ]
                }}
            }}
        ]
        """

        user_prompt = f"""
        Generate {batch_size} {spec.name} problems starting from problem #{start_index}.
        
        DIFFICULTY PROGRESSION:
        - Problems {start_index}-{start_index+1}: Easy level
        - Problems {start_index+2}-{start_index+3}: Medium level  
        - Problems {start_index+4}: Hard level
        
        Ensure each problem:
        1. Uses varied, natural contexts that are relatable to students
        2. Teaches specific skills from the MOE curriculum objectives
        3. Includes proper Socratic questioning with helpful hints
        4. Has realistic numbers appropriate for P6 students
        5. Connects to real-world applications
        
        Return ONLY the JSON array, no other text.
        """
        
        try:
            print(f"    🤖 Generating problems {start_index}-{start_index+batch_size-1}...")
            response = self.model.generate_content([system_prompt, user_prompt])
            
            # Parse response
            content = response.text.strip()
            if content.startswith('```json'):
                content = content[7:-3].strip()
            elif content.startswith('```'):
                content = content[3:-3].strip()
                
            problems = json.loads(content)
            
            # Basic validation
            validated_problems = []
            for i, problem in enumerate(problems):
                # Ensure required fields
                problem.setdefault('id', f"{subject_key.upper()}-S1-E{start_index + i}")
                problem.setdefault('learn_step', ((start_index + i) // 10) + 1)
                problem.setdefault('estimated_time_seconds', 60)
                
                validated_problems.append(problem)
            
            return validated_problems
            
        except Exception as e:
            print(f"    ❌ Batch generation failed: {e}")
            return []
    
    def generate_subject_fast(self, subject_key: str) -> Dict[str, Any]:
        """Generate curriculum for one subject with progress tracking"""
        spec = self.subjects[subject_key]
        print(f"\n🚀 Generating {spec.name} ({spec.target_problems} problems)...")
        
        curriculum = {
            "topic": spec.name,
            "version": "enhanced-v1",
            "metadata": {
                "generated_at": datetime.now().isoformat(),
                "generator_version": "fast-v1.0",
                "target_problems": spec.target_problems,
                "singapore_moe_aligned": True
            },
            "items": []
        }
        
        batch_size = 5  # Smaller batches for faster generation
        generated_count = 0
        
        for start_idx in range(1, spec.target_problems + 1, batch_size):
            current_batch_size = min(batch_size, spec.target_problems - generated_count)
            
            batch_problems = self.generate_problem_batch(
                subject_key, spec, start_idx, current_batch_size
            )
            
            if batch_problems:
                curriculum["items"].extend(batch_problems)
                generated_count += len(batch_problems)
                print(f"    ✅ Generated {generated_count}/{spec.target_problems} problems")
                
                # Save progress incrementally every 10 problems
                if generated_count % 10 == 0:
                    with open(f"{subject_key}_progress.json", 'w') as f:
                        json.dump(curriculum, f, indent=2, ensure_ascii=False)
                    print(f"    💾 Progress saved: {generated_count} problems")
            else:
                print(f"    ⚠️ Batch failed, retrying...")
                time.sleep(2)  # Brief pause before retry
            
            # Brief pause between batches to avoid rate limits
            time.sleep(1)
        
        # Final save
        filename = f"{subject_key}.json"
        with open(filename, 'w') as f:
            json.dump(curriculum, f, indent=2, ensure_ascii=False)
        
        print(f"✅ {spec.name} complete: {len(curriculum['items'])} problems saved to {filename}")
        
        # Clean up progress file
        progress_file = f"{subject_key}_progress.json"
        if os.path.exists(progress_file):
            os.remove(progress_file)
        
        return curriculum
    
    def generate_all_fast(self) -> None:
        """Generate all subjects with progress tracking"""
        print("🎯 Fast AI-Powered Curriculum Generation Starting...")
        print(f"📊 Target: {sum(spec.target_problems for spec in self.subjects.values())} problems across {len(self.subjects)} subjects")
        
        start_time = time.time()
        total_generated = 0
        
        for subject_key in self.subjects.keys():
            try:
                curriculum = self.generate_subject_fast(subject_key)
                total_generated += len(curriculum['items'])
                
                elapsed = time.time() - start_time
                print(f"⏱️  Running time: {elapsed/60:.1f} minutes")
                
            except KeyboardInterrupt:
                print(f"\n🛑 Generation stopped by user. Generated {total_generated} problems so far.")
                break
            except Exception as e:
                print(f"❌ Failed to generate {subject_key}: {e}")
        
        total_time = time.time() - start_time
        print(f"\n🎉 Generation Complete!")
        print(f"📊 Total problems generated: {total_generated}")
        print(f"⏱️  Total time: {total_time/60:.1f} minutes")
        print(f"🚀 Average: {total_generated/(total_time/60):.1f} problems/minute")


def main():
    """Run fast curriculum generation"""
    generator = FastCurriculumGenerator()
    generator.generate_all_fast()


if __name__ == "__main__":
    main()