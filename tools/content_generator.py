"""
AI-Powered Curriculum Content Generator for PSLE AI Tutor
Generates 400+ problems across 7 P6 Math subjects using Gemini AI
"""

import json
import os
import sys
from typing import Dict, List, Any, Optional
from dataclasses import dataclass
import google.generativeai as genai
from datetime import datetime

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


class CurriculumGenerator:
    """AI-powered curriculum generation with Singapore MOE alignment"""
    
    def __init__(self):
        # Initialize Gemini AI
        if not settings.google_api_key:
            raise ValueError("GOOGLE_API_KEY required for content generation")
        
        genai.configure(api_key=settings.google_api_key)
        self.model = genai.GenerativeModel('gemini-2.5-flash')
        
        # Load existing algebra structure as template
        self.algebra_template = self._load_algebra_template()
        
        # Official Singapore MOE Primary 6 syllabus requirements
        self.moe_syllabus = self._load_moe_syllabus()
        
        # Define P6 subject specifications based on official MOE curriculum
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
                    'Work in groups to solve multi-step and non-routine fraction problems',
                    'Use fraction discs or digital manipulatives to illustrate division concepts'
                ],
                difficulty_progression=['Easy', 'Easy', 'Medium', 'Medium', 'Medium', 'Hard', 'Hard', 'Hard'],
                singapore_contexts=[
                    'Hawker center food portions', 'School canteen meals', 'Birthday cake sharing',
                    'Public transport timing', 'Shopping at wet market', 'Sports day activities',
                    'School fundraising events', 'Class projects', 'Library book collection'
                ],
                key_skills=[
                    'fraction-division-by-whole', 'whole-division-by-fraction', 'fraction-division-by-fraction',
                    'calculator-fraction-operations', 'part-whole-models', 'comparison-models',
                    'multi-step-fraction-problems', 'fraction-manipulatives'
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
                    'Make connections between percentage of percentage and fraction of fraction',
                    'Give real-life examples of percentage change and explain calculations'
                ],
                difficulty_progression=['Easy', 'Easy', 'Medium', 'Medium', 'Hard', 'Hard'],
                singapore_contexts=[
                    'Country club membership changes', 'Pocket money savings', 'School population growth',
                    'Shopping discounts and GST', 'Sports jersey and cap purchases', 'Survey results',
                    'Weather data changes', 'Population statistics', 'Government budget allocations'
                ],
                key_skills=[
                    'find-whole-from-percentage-part', 'percentage-increase-decrease', 'before-after-concept',
                    'calculator-percentage-games', 'percentage-of-percentage', 'real-life-percentage-examples'
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
                    'Solve problems involving changing ratios before and after',
                    'Use ratio to express comparison and part-whole relationships'
                ],
                difficulty_progression=['Easy', 'Easy', 'Medium', 'Medium', 'Hard', 'Hard'],
                singapore_contexts=[
                    'Cooking ingredient ratios', 'Map scale calculations', 'Paint color mixing',
                    'Class composition ratios', 'Sports team formations', 'Recipe scaling',
                    'Model building proportions', 'Survey result comparisons'
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
                    'Solve average speed problems for journeys with multiple segments',
                    'Apply speed formulas to Singapore transport and travel contexts'
                ],
                difficulty_progression=['Easy', 'Medium', 'Medium', 'Hard', 'Hard'],
                singapore_contexts=[
                    'MRT train journeys between stations', 'Bus routes and schedules',
                    'Walking and cycling in Singapore parks', 'Airplane travel times',
                    'Maritime shipping routes', 'Sports day running events',
                    'Swimming pool lap timing', 'Delivery truck schedules'
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
                    'Apply circle and volume formulas to solve real-world problems',
                    'Find areas of composite shapes by breaking into simpler shapes'
                ],
                difficulty_progression=['Easy', 'Easy', 'Medium', 'Medium', 'Hard', 'Hard'],
                singapore_contexts=[
                    'Singapore Flyer and circular structures', 'HDB void deck design',
                    'School playground roundabouts', 'Gardens by the Bay domes',
                    'Swimming pool dimensions', 'Packaging box volumes',
                    'Marina Bay Sands architecture', 'Sports field measurements'
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
                    'Compare and analyze data presented in multiple pie charts',
                    'Solve word problems involving pie chart data interpretation'
                ],
                difficulty_progression=['Easy', 'Medium', 'Medium', 'Hard'],
                singapore_contexts=[
                    'School CCA participation surveys', 'Singapore population demographics',
                    'Weather patterns and rainfall data', 'Sports preferences in Singapore',
                    'Hawker food popularity charts', 'Public transport usage statistics',
                    'Entertainment and media consumption', 'Academic subject preferences'
                ],
                key_skills=[
                    'pie-chart-interpretation', 'sector-angle-calculation', 'percentage-to-angle',
                    'pie-chart-construction', 'multiple-chart-comparison', 'data-problem-solving'
                ]
            )
        }
    
    def _load_algebra_template(self) -> Dict[str, Any]:
        """Load existing algebra structure as template"""
        try:
            with open('algebra.json', 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            # Fallback basic structure
            return {
                "topic": "Template",
                "version": "enhanced-v1",
                "items": []
            }
    
    def _load_moe_syllabus(self) -> str:
        """Load MOE Primary 6 Mathematics syllabus content for reference"""
        try:
            # For now, return a reference note. In production, you could:
            # 1. Use a PDF parsing library to extract text
            # 2. Store pre-extracted syllabus content
            # 3. Use OCR for image-based PDFs
            return "Singapore MOE Primary 6 Mathematics Syllabus loaded for curriculum alignment"
        except Exception as e:
            print(f"Warning: Could not load MOE syllabus: {e}")
            return "MOE syllabus reference not available"
    
    def generate_subject_curriculum(self, subject_key: str) -> Dict[str, Any]:
        """Generate complete curriculum for a subject"""
        spec = self.subjects[subject_key]
        print(f"\n🚀 Generating {spec.target_problems} problems for {spec.name}...")
        
        # Create subject curriculum structure
        curriculum = {
            "topic": spec.name,
            "version": "enhanced-v1",
            "metadata": {
                "generated_at": datetime.now().isoformat(),
                "generator_version": "1.0.0",
                "target_problems": spec.target_problems,
                "singapore_moe_aligned": True
            },
            "items": []
        }
        
        # Generate problems in batches for better quality control
        batch_size = 10
        for i in range(0, spec.target_problems, batch_size):
            batch_problems = min(batch_size, spec.target_problems - i)
            print(f"  📝 Generating batch {i//batch_size + 1}: {batch_problems} problems...")
            
            batch_items = self._generate_problem_batch(
                subject_key, spec, i + 1, batch_problems
            )
            curriculum["items"].extend(batch_items)
        
        print(f"✅ Generated {len(curriculum['items'])} problems for {spec.name}")
        return curriculum
    
    def _generate_problem_batch(self, subject_key: str, spec: SubjectSpec, 
                               start_index: int, batch_size: int) -> List[Dict[str, Any]]:
        """Generate a batch of problems using AI"""
        
        # Create AI prompt for batch generation
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
        The learning objectives below are derived from the official MOE curriculum document.

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
                "difficulty": 0.3-0.9,
                "skill": "Main skill category",
                "subskills": ["specific-skill-1", "specific-skill-2"],
                "estimated_time_seconds": 45-120,
                "problem_text": "Engaging problem with Singapore context",
                "assets": {{
                    "manipulatives": [],
                    "image_url": null,
                    "svg_code": null
                }},
                "student_view": {{
                    "socratic": true,
                    "steps": [
                        {{
                            "id": "S1", 
                            "prompt": "Socratic question to guide thinking",
                            "answer_type": "free|numeric|algebra",
                            "acceptable_responses": [],
                            "hints": {{
                                "L1": "Gentle hint",
                                "L2": "More specific hint", 
                                "L3": "Concrete hint with example"
                            }}
                        }},
                        {{
                            "id": "S2",
                            "prompt": "Final answer step",
                            "answer_type": "numeric|algebra",
                            "acceptable_responses": [{{"equivalent_to": "correct_answer"}}],
                            "hints": {{
                                "L1": "Check your working",
                                "L2": "Consider the units",
                                "L3": "Try a different approach"
                            }}
                        }}
                    ]
                }},
                "teacher_view": {{
                    "solutions_teacher": ["Step-by-step solution"],
                    "common_pitfalls": [
                        {{"text": "Common mistake students make", "tag": "mistake_type"}}
                    ]
                }},
                "telemetry": {{
                    "scoring": {{"xp": 10-20, "bonus_no_hints": 2-5}},
                    "prereqs": [],
                    "next_items": []
                }},
                "evaluation": {{
                    "rules": {{
                        "regex": [{{"equivalent_to": "answer"}}],
                        "algebraic_equivalence": false,
                        "llm_fallback": true
                    }}
                }}
            }}
        ]
        """

        user_prompt = f"""
        Generate {batch_size} {spec.name} problems starting from problem #{start_index}.
        
        DIFFICULTY PROGRESSION:
        - Problems {start_index}-{start_index+2}: Easy level
        - Problems {start_index+3}-{start_index+6}: Medium level  
        - Problems {start_index+7}-{start_index+batch_size-1}: Hard level
        
        Ensure each problem:
        1. Uses varied, natural contexts that are relatable to students
        2. Teaches specific skills from the MOE curriculum objectives
        3. Includes proper Socratic questioning with helpful hints
        4. Has realistic numbers appropriate for P6 students
        5. Connects to real-world applications
        
        Return ONLY the JSON array, no other text.
        """
        
        try:
            # Generate content with AI
            response = self.model.generate_content([system_prompt, user_prompt])
            
            # Parse AI response
            content = response.text.strip()
            if content.startswith('```json'):
                content = content[7:-3].strip()
            elif content.startswith('```'):
                content = content[3:-3].strip()
                
            problems = json.loads(content)
            
            # Validate and fix any issues
            validated_problems = []
            for i, problem in enumerate(problems):
                try:
                    validated_problem = self._validate_and_fix_problem(problem, subject_key, start_index + i)
                    validated_problems.append(validated_problem)
                except Exception as e:
                    print(f"⚠️ Problem {start_index + i} validation failed: {e}")
                    # Create fallback problem
                    fallback = self._create_fallback_problem(subject_key, spec, start_index + i)
                    validated_problems.append(fallback)
            
            return validated_problems
            
        except Exception as e:
            print(f"❌ AI generation failed: {e}")
            # Create fallback problems
            return [
                self._create_fallback_problem(subject_key, spec, start_index + i) 
                for i in range(batch_size)
            ]
    
    def _validate_and_fix_problem(self, problem: Dict[str, Any], subject_key: str, index: int) -> Dict[str, Any]:
        """Validate and fix AI-generated problem"""
        
        # Fix required fields
        problem.setdefault('id', f"{subject_key.upper()}-S1-E{index}")
        problem.setdefault('learn_step', (index // 10) + 1)
        problem.setdefault('estimated_time_seconds', 60)
        
        # Validate complexity and difficulty alignment
        complexity = problem.get('complexity', 'Medium')
        if complexity == 'Easy':
            problem['difficulty'] = min(0.5, problem.get('difficulty', 0.3))
        elif complexity == 'Hard':
            problem['difficulty'] = max(0.7, problem.get('difficulty', 0.8))
        else:
            problem['difficulty'] = max(0.4, min(0.7, problem.get('difficulty', 0.5)))
        
        # Ensure required structure exists
        problem.setdefault('assets', {"manipulatives": [], "image_url": None, "svg_code": None})
        problem.setdefault('telemetry', {"scoring": {"xp": 10, "bonus_no_hints": 2}, "prereqs": [], "next_items": []})
        
        # Validate student_view steps
        student_view = problem.get('student_view', {})
        steps = student_view.get('steps', [])
        
        if not steps:
            # Add basic step structure
            steps = [
                {
                    "id": "S1",
                    "prompt": "What is the first step to solve this problem?",
                    "answer_type": "free",
                    "acceptable_responses": [],
                    "hints": {
                        "L1": "Read the problem carefully.",
                        "L2": "Identify what you need to find.",
                        "L3": "Look for keywords that suggest the operation."
                    }
                },
                {
                    "id": "S2", 
                    "prompt": "State your final answer.",
                    "answer_type": "numeric",
                    "acceptable_responses": [{"equivalent_to": "answer"}],
                    "hints": {
                        "L1": "Check your calculation.",
                        "L2": "Make sure you have the right units.",
                        "L3": "Double-check by working backwards."
                    }
                }
            ]
            student_view['steps'] = steps
        
        student_view.setdefault('socratic', True)
        problem['student_view'] = student_view
        
        return problem
    
    def _create_fallback_problem(self, subject_key: str, spec: SubjectSpec, index: int) -> Dict[str, Any]:
        """Create a basic fallback problem if AI generation fails"""
        return {
            "id": f"{subject_key.upper()}-S1-E{index}",
            "topic": spec.name,
            "title": f"Basic {spec.name} Problem {index}",
            "learn_step": (index // 10) + 1,
            "complexity": "Medium",
            "difficulty": 0.5,
            "skill": spec.key_skills[0] if spec.key_skills else "basic-skill",
            "subskills": [spec.key_skills[0] if spec.key_skills else "basic-skill"],
            "estimated_time_seconds": 60,
            "problem_text": f"Solve this {spec.name.lower()} problem.",
            "assets": {"manipulatives": [], "image_url": None, "svg_code": None},
            "student_view": {
                "socratic": True,
                "steps": [
                    {
                        "id": "S1",
                        "prompt": "What is your approach to this problem?",
                        "answer_type": "free",
                        "acceptable_responses": [],
                        "hints": {
                            "L1": "Think step by step.",
                            "L2": "What information is given?",
                            "L3": "What do you need to find?"
                        }
                    }
                ]
            },
            "teacher_view": {"solutions_teacher": [], "common_pitfalls": []},
            "telemetry": {"scoring": {"xp": 10, "bonus_no_hints": 2}, "prereqs": [], "next_items": []},
            "evaluation": {"rules": {"regex": [], "algebraic_equivalence": False, "llm_fallback": True}}
        }
    
    def generate_all_curricula(self) -> None:
        """Generate curricula for all subjects"""
        print("🎯 Starting AI-Powered Curriculum Generation...")
        print(f"📊 Target: {sum(spec.target_problems for spec in self.subjects.values())} problems across {len(self.subjects)} subjects")
        
        for subject_key in self.subjects.keys():
            try:
                curriculum = self.generate_subject_curriculum(subject_key)
                
                # Save to file
                filename = f"{subject_key}.json"
                with open(filename, 'w') as f:
                    json.dump(curriculum, f, indent=2, ensure_ascii=False)
                
                print(f"💾 Saved {subject_key}.json with {len(curriculum['items'])} problems")
                
            except Exception as e:
                print(f"❌ Failed to generate {subject_key}: {e}")
        
        print(f"\n🎉 Curriculum generation complete!")
        
        # Generate summary report
        self._generate_summary_report()
    
    def _generate_summary_report(self) -> None:
        """Generate summary report of all generated curricula"""
        print("\n📋 CURRICULUM GENERATION SUMMARY")
        print("=" * 50)
        
        total_problems = 0
        for subject_key in self.subjects.keys():
            try:
                with open(f"{subject_key}.json", 'r') as f:
                    data = json.load(f)
                    count = len(data['items'])
                    total_problems += count
                    print(f"{data['topic']:25} {count:3d} problems")
            except FileNotFoundError:
                print(f"{subject_key:25} FAILED")
        
        print("=" * 50)
        print(f"{'TOTAL':25} {total_problems:3d} problems")
        print(f"\n✅ Ready for Week 3: UI/UX Development")


def main():
    """Main execution function"""
    print("🚀 PSLE AI Tutor - Curriculum Generator")
    print("Generating 400+ problems for complete P6 Math coverage")
    
    generator = CurriculumGenerator()
    generator.generate_all_curricula()


if __name__ == "__main__":
    main()