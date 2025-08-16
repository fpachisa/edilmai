"""
Complete all remaining subjects: percentage, ratio, speed, geometry, statistics
"""

import json
import os
import sys
from typing import Dict, List, Any
import google.generativeai as genai
from datetime import datetime
import time

# Add parent directory to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from api.core.config import settings

def generate_subject(subject_key: str, spec: Dict[str, Any]) -> Dict[str, Any]:
    """Generate complete curriculum for one subject"""
    
    genai.configure(api_key=settings.google_api_key)
    model = genai.GenerativeModel('gemini-2.5-flash')
    
    print(f"\n🚀 Generating {spec['name']} ({spec['target_problems']} problems)...")
    
    curriculum = {
        "topic": spec['name'],
        "version": "enhanced-v1",
        "metadata": {
            "generated_at": datetime.now().isoformat(),
            "generator_version": "complete-v1.0",
            "target_problems": spec['target_problems'],
            "singapore_moe_aligned": True
        },
        "items": []
    }
    
    batch_size = 5
    generated_count = 0
    start_time = time.time()
    
    for start_idx in range(1, spec['target_problems'] + 1, batch_size):
        current_batch_size = min(batch_size, spec['target_problems'] - generated_count)
        
        print(f"  🤖 Generating problems {start_idx}-{start_idx + current_batch_size - 1}...")
        
        # Create AI prompt
        system_prompt = f"""
        You are an expert curriculum designer for Singapore Primary 6 Mathematics.
        Generate {current_batch_size} high-quality math problems for the topic: {spec['name']}

        CRITICAL REQUIREMENTS:
        1. STRICTLY follow Singapore MOE Primary 6 Mathematics syllabus
        2. Use natural, relatable contexts from everyday life
        3. Progressive difficulty: Easy → Medium → Hard
        4. Include Socratic questioning steps for guided learning
        5. Problems must be appropriate for Singapore P6 students

        OFFICIAL MOE LEARNING OBJECTIVES FOR {spec['name']}:
        {chr(10).join(f"- {obj}" for obj in spec['learning_objectives'])}

        KEY SKILLS TO COVER:
        {chr(10).join(f"- {skill}" for skill in spec['key_skills'])}

        CONTEXTUAL SETTINGS (vary naturally):
        {chr(10).join(f"- {context}" for context in spec['contexts'])}

        OUTPUT FORMAT: Return ONLY valid JSON array with problems numbered starting from {start_idx}.
        Each problem should have: id, topic, title, complexity, difficulty, skill, subskills, 
        estimated_time_seconds, problem_text, student_view with socratic steps and hints.
        """

        user_prompt = f"""
        Generate {current_batch_size} {spec['name']} problems #{start_idx} to #{start_idx + current_batch_size - 1}.
        
        Ensure variety in:
        - Contexts (use different scenarios from the list)
        - Skills covered (cycle through different operations)
        - Difficulty levels (appropriate progression)
        
        Return ONLY the JSON array, no other text.
        """
        
        try:
            response = model.generate_content([system_prompt, user_prompt])
            content = response.text.strip()
            
            # Clean up response
            if content.startswith('```json'):
                content = content[7:-3].strip()
            elif content.startswith('```'):
                content = content[3:-3].strip()
                
            batch_problems = json.loads(content)
            
            # Basic validation and fix IDs
            for i, problem in enumerate(batch_problems):
                problem['id'] = f"{subject_key.upper()}-S1-E{start_idx + i}"
                problem['topic'] = spec['name']
                problem.setdefault('learn_step', ((start_idx + i - 1) // 10) + 1)
                problem.setdefault('estimated_time_seconds', 60)
            
            curriculum['items'].extend(batch_problems)
            generated_count += len(batch_problems)
            
            print(f"    ✅ Generated {generated_count}/{spec['target_problems']} problems")
            
            # Brief pause between batches
            time.sleep(1.2)
            
        except Exception as e:
            print(f"    ❌ Batch failed: {e}")
            # Continue with next batch
    
    # Final save
    curriculum['metadata']['completed_at'] = datetime.now().isoformat()
    curriculum['metadata']['total_problems'] = len(curriculum['items'])
    
    with open(f'{subject_key}.json', 'w') as f:
        json.dump(curriculum, f, indent=2, ensure_ascii=False)
    
    generation_time = time.time() - start_time
    estimated_cost = (generated_count / 5) * 0.0027
    
    print(f"  🎉 {spec['name']} COMPLETE!")
    print(f"  📊 Problems: {len(curriculum['items'])}")
    print(f"  ⏱️  Time: {generation_time/60:.1f} minutes")
    print(f"  💰 Cost: ${estimated_cost:.4f}")
    
    return curriculum

def main():
    """Generate all remaining subjects"""
    
    # Define all remaining subjects with MOE-aligned specifications
    subjects = {
        'percentage': {
            'name': 'Percentage',
            'target_problems': 60,
            'learning_objectives': [
                'Find the whole given a part and the percentage using pictorial model',
                'Find percentage increase/decrease and calculate percentage change',
                'Solve word problems involving percentage using before-after concept',
                'Use calculator to find percentage change through games and activities',
                'Make connections between percentage of percentage and fraction of fraction'
            ],
            'key_skills': [
                'find-whole-from-percentage-part', 'percentage-increase-decrease', 'before-after-concept',
                'calculator-percentage-games', 'percentage-of-percentage'
            ],
            'contexts': [
                'Club membership changes', 'Savings and pocket money', 'School populations',
                'Shopping discounts and taxes', 'Survey results', 'Weather data',
                'Sports statistics', 'Academic performance'
            ]
        },
        
        'ratio': {
            'name': 'Ratio and Proportion',
            'target_problems': 60,
            'learning_objectives': [
                'Express ratio in its simplest form using HCF method',
                'Solve 2-term and 3-term ratio problems using unitary method',
                'Find equivalent ratios and use them to solve word problems',
                'Apply ratio concepts to real-world situations with bar models',
                'Solve problems involving changing ratios before and after'
            ],
            'key_skills': [
                'ratio-simplest-form', '2-term-ratio-problems', '3-term-ratio-problems',
                'equivalent-ratios', 'unitary-method', 'changing-ratios', 'bar-model-ratios'
            ],
            'contexts': [
                'Cooking ingredient ratios', 'Map scale calculations', 'Paint color mixing',
                'Class compositions', 'Sports team formations', 'Recipe scaling',
                'Model building', 'Survey comparisons'
            ]
        },
        
        'speed': {
            'name': 'Speed, Distance and Time',
            'target_problems': 50,
            'learning_objectives': [
                'Use formula Speed = Distance ÷ Time to solve problems',
                'Calculate distance using Distance = Speed × Time formula',
                'Calculate time using Time = Distance ÷ Speed formula',
                'Convert between km/h and m/s using conversion factors',
                'Solve average speed problems for journeys with multiple segments'
            ],
            'key_skills': [
                'speed-distance-time-formula', 'distance-calculation', 'time-calculation',
                'kmh-to-ms-conversion', 'average-speed-calculation', 'multi-segment-journeys'
            ],
            'contexts': [
                'Train journeys', 'Bus routes and schedules', 'Walking and cycling',
                'Airplane travel times', 'Swimming competitions', 'Running events',
                'Delivery schedules', 'Traffic situations'
            ]
        },
        
        'geometry': {
            'name': 'Geometry',
            'target_problems': 60,
            'learning_objectives': [
                'Calculate circumference of circles using C = πd or C = 2πr',
                'Calculate area of circles using A = πr² with calculator',
                'Find volume of cubes using V = a³ and cuboids using V = l×w×h',
                'Identify and construct nets of cubes, cuboids, and triangular prisms',
                'Apply circle and volume formulas to solve real-world problems'
            ],
            'key_skills': [
                'circle-circumference-formula', 'circle-area-formula', 'cube-volume',
                'cuboid-volume', 'nets-construction', 'composite-shape-areas'
            ],
            'contexts': [
                'Circular structures and designs', 'Playground equipment', 'Architecture',
                'Swimming pools', 'Packaging boxes', 'Sports field measurements',
                'Garden designs', 'Construction projects'
            ]
        },
        
        'statistics': {
            'name': 'Statistics and Pie Charts',
            'target_problems': 40,
            'learning_objectives': [
                'Read and interpret pie charts with sector angles and percentages',
                'Calculate angles in pie charts using proportional reasoning',
                'Convert between fractions, decimals and percentages in pie charts',
                'Draw pie charts using protractor and compass for given data',
                'Compare and analyze data presented in multiple pie charts'
            ],
            'key_skills': [
                'pie-chart-interpretation', 'sector-angle-calculation', 'percentage-to-angle',
                'pie-chart-construction', 'multiple-chart-comparison', 'data-problem-solving'
            ],
            'contexts': [
                'School survey results', 'Population demographics', 'Weather patterns',
                'Sports preferences', 'Food choices', 'Transport usage',
                'Entertainment preferences', 'Academic subjects'
            ]
        }
    }
    
    print("🎯 Completing All Remaining Curriculum Content")
    print(f"📊 Total target: {sum(spec['target_problems'] for spec in subjects.values())} problems across {len(subjects)} subjects")
    
    total_start_time = time.time()
    total_problems = 0
    total_cost = 0
    
    # Generate each subject
    for subject_key, spec in subjects.items():
        try:
            curriculum = generate_subject(subject_key, spec)
            total_problems += len(curriculum['items'])
            total_cost += (len(curriculum['items']) / 5) * 0.0027
            
        except KeyboardInterrupt:
            print(f"\n🛑 Generation stopped by user.")
            break
        except Exception as e:
            print(f"❌ Failed to generate {subject_key}: {e}")
    
    total_time = time.time() - total_start_time
    
    print(f"\n🎉 ALL SUBJECTS GENERATION COMPLETE!")
    print(f"📊 Total problems generated: {total_problems}")
    print(f"⏱️  Total time: {total_time/60:.1f} minutes") 
    print(f"💰 Total estimated cost: ${total_cost:.4f}")
    print(f"🚀 Average rate: {total_problems/(total_time/60):.1f} problems/minute")
    
    # List all generated files
    print(f"\n📁 Generated Files:")
    for subject_key in subjects.keys():
        if os.path.exists(f"{subject_key}.json"):
            with open(f"{subject_key}.json", 'r') as f:
                data = json.load(f)
                print(f"  ✅ {subject_key}.json - {len(data['items'])} problems")

if __name__ == "__main__":
    main()