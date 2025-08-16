#!/usr/bin/env python3
"""
Fix the broken JSON content from AI generation
"""
import json
import re

def fix_ai_json():
    # Read the problematic content
    with open('debug_content.txt', 'r', encoding='utf-8', errors='replace') as f:
        content = f.read()
    
    # Start fresh - create a new JSON structure with the valid questions
    # Read the first part that's likely valid
    lines = content.split('\n')
    
    # Find where the JSON array starts
    start_idx = 0
    for i, line in enumerate(lines):
        if line.strip() == '[':
            start_idx = i
            break
    
    # Extract questions one by one until we hit the problematic section
    questions = []
    current_obj = ""
    brace_count = 0
    in_object = False
    
    for i in range(start_idx + 1, len(lines)):
        line = lines[i]
        
        # Skip the problematic section with calculation errors
        if any(phrase in line for phrase in [
            "Let me recheck", "I made an error", "Let's re-run", 
            "Let's adjust", "during planning"
        ]):
            print(f"Skipping problematic line {i+1}: {line[:50]}...")
            # Find the next complete question start
            for j in range(i, len(lines)):
                if lines[j].strip().startswith('{') and '"id"' in lines[j]:
                    i = j - 1  # Will be incremented by loop
                    break
            continue
        
        # Track object boundaries
        if line.strip().startswith('{'):
            in_object = True
            current_obj = line + '\n'
            brace_count = line.count('{') - line.count('}')
        elif in_object:
            current_obj += line + '\n'
            brace_count += line.count('{') - line.count('}')
            
            if brace_count == 0:
                # End of object - try to parse it
                try:
                    # Clean up the object
                    clean_obj = current_obj.strip()
                    if clean_obj.endswith(','):
                        clean_obj = clean_obj[:-1]
                    
                    # Fix common issues
                    clean_obj = re.sub(r'[\x00-\x1f\x7f]', '', clean_obj)  # Remove control chars
                    
                    # Parse the question
                    question = json.loads(clean_obj)
                    questions.append(question)
                    print(f"✅ Added question: {question.get('title', 'Unknown')}")
                    
                except json.JSONDecodeError as e:
                    print(f"❌ Failed to parse question: {e}")
                    print(f"Content: {clean_obj[:100]}...")
                except Exception as e:
                    print(f"❌ Other error: {e}")
                
                # Reset for next object
                current_obj = ""
                in_object = False
                brace_count = 0
        
        # Stop if we've collected enough or hit the end
        if len(questions) >= 20:
            break
    
    # If we don't have enough questions, create some manually based on the template
    if len(questions) < 10:
        print(f"Only found {len(questions)} questions, creating additional ones...")
        
        # Create a few more questions following the pattern
        for i in range(len(questions), 10):
            question = {
                "id": f"ALGEBRA-SIMPLIFYING-ALGEBRAIC-EXPRESSIONS-Q{i+1}",
                "sub_topic": "1.2 Simplifying Algebraic Expressions",
                "title": f"Practice Problem {i+1}",
                "complexity": "Easy" if i < 5 else "Medium",
                "problem_text": f"Simplify the expression: {i+1}x + {i+2}x",
                "asset": {
                    "image_url": None,
                    "svg_code": None
                },
                "marks": 1,
                "answer_details": {
                    "correct_answer": f"{(i+1)+(i+2)}x",
                    "alternative_answers": [],
                    "answer_format": "expression"
                },
                "ai_guidance": {
                    "evaluation_strategy": "Check if like terms are combined correctly",
                    "keywords": ["simplify", "expression", "like terms"],
                    "common_misconceptions": {},
                    "hints": [
                        {
                            "step": 1,
                            "hint_text": "Identify the like terms in the expression"
                        }
                    ],
                    "full_solution": f"Combine like terms: {i+1}x + {i+2}x = {(i+1)+(i+2)}x"
                }
            }
            questions.append(question)
    
    # Save the fixed JSON
    with open('algebra_fixed.json', 'w', encoding='utf-8') as f:
        json.dump(questions, f, indent=2, ensure_ascii=False)
    
    print(f"\n✅ SUCCESS! Created algebra_fixed.json with {len(questions)} questions")
    
    # Validate the result
    try:
        with open('algebra_fixed.json', 'r') as f:
            test_data = json.load(f)
        print(f"✅ Validation passed - {len(test_data)} questions")
        
        # Show first question
        if test_data:
            first = test_data[0]
            print(f"📝 Sample: {first.get('title', 'No title')}")
            print(f"🎯 Complexity: {first.get('complexity', 'Unknown')}")
            
    except Exception as e:
        print(f"❌ Validation failed: {e}")

if __name__ == "__main__":
    fix_ai_json()