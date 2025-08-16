# 🎓 SIMPLIFIED PROBLEM STRUCTURE GUIDELINES

## 📋 **MULTI-EXPERT DESIGN PRINCIPLES**

### **Educational Technology Specialist**
- **Problem Context First**: Always show complete `problem_text` before step-by-step guidance
- **Clear Learning Progression**: Each step builds understanding systematically
- **Real-World Relevance**: Problems use familiar contexts (cakes, pizza, ribbons)

### **Technical Lead** 
- **Flat Structure**: Minimal nesting for performance and maintainability
- **Consistent Naming**: Standard field names across all problems
- **Efficient Processing**: Fast JSON parsing and API responses

### **UX Researcher**
- **Child-Friendly Language**: Age-appropriate vocabulary and scenarios
- **Progressive Hints**: L1 (gentle nudge) → L2 (more specific) → L3 (almost the answer)
- **Clear Instructions**: Unambiguous prompts that children can understand

## 🏗️ **CORE STRUCTURE**

```json
{
  "id": "SUBJECT-STEP-DIFFICULTY",
  "topic": "Subject Name",
  "title": "Engaging Problem Title",
  "learn_step": 1,
  "complexity": "Easy|Medium|Hard",
  "difficulty": 0.1-1.0,
  "skill": "primary-skill-tag",
  "subskills": ["specific-skill-1", "specific-skill-2"],
  "estimated_time_seconds": 60-180,
  "problem_text": "Complete, engaging problem description with context",
  "student_view": {
    "socratic": true,
    "steps": [
      {
        "id": "S1",
        "prompt": "First guiding question",
        "answer_type": "numeric|free|fraction|multiple_choice",
        "acceptable_responses": ["answer1", "answer2", "variant3"],
        "hints": {
          "L1": "Gentle nudge in right direction",
          "L2": "More specific guidance",
          "L3": "Almost gives away the answer"
        }
      }
    ]
  }
}
```

## ✅ **REQUIRED FIELDS**

### **Core Metadata**
- `id`: Unique identifier (SUBJECT-STEP-DIFFICULTY format)
- `topic`: Subject area (Fractions, Algebra, etc.)
- `title`: Engaging, child-friendly title
- `problem_text`: **MOST IMPORTANT** - Complete problem description

### **Learning Classification**
- `learn_step`: Sequential learning progression (1, 2, 3...)
- `complexity`: Human-readable difficulty (Easy, Medium, Hard)
- `difficulty`: Numeric difficulty (0.1-1.0)
- `skill`: Primary skill being taught
- `subskills`: Specific sub-skills array

### **Student Experience**
- `student_view.socratic`: Always true for guided learning
- `student_view.steps`: Array of guided questions
- `acceptable_responses`: **CRITICAL** - AI needs these for evaluation
- `hints`: Three-level progressive support system

## 🎯 **BEST PRACTICES**

### **Problem Text Writing**
- **Start with Context**: "Sarah has...", "The class is planning..."
- **Include All Details**: Numbers, units, relationships
- **End with Clear Question**: "What fraction...", "How many..."
- **Use Singapore Context**: Local names, familiar situations

### **Step Design**
- **3-5 Steps Maximum**: Avoid cognitive overload
- **Build Sequentially**: Each step uses previous answers
- **Ask One Thing**: Single concept per step
- **Guide Discovery**: Let students figure it out

### **Answer Types**
- `numeric`: Whole numbers (3, 15, 42)
- `fraction`: Fraction format (1/2, 3/4, 5/8)
- `free`: Open text (division, multiply, explanation)
- `multiple_choice`: Future expansion

### **Acceptable Responses**
- **Multiple Formats**: ["1/4", "0.25", "one quarter"]
- **Common Variants**: ["divide", "division", "÷"]
- **Mathematical Expressions**: ["3/4 ÷ 3", "(3/4) × (1/3)"]

### **Hint Progression**
- **L1 (Gentle)**: "Think about...", "What operation..."
- **L2 (Specific)**: "Remember that division...", "Look at the numbers..."
- **L3 (Almost Answer)**: "The calculation is...", "Step by step: ..."

## 🚫 **AVOID THESE MISTAKES**

### **Technical Issues**
- ❌ Empty `acceptable_responses` arrays
- ❌ Complex nested structures
- ❌ Inconsistent field naming
- ❌ Missing `problem_text`

### **Educational Issues**
- ❌ Showing steps before problem context
- ❌ Too many steps (cognitive overload)
- ❌ Abstract problems without context
- ❌ Hints that give away answers immediately

### **UX Issues**
- ❌ Adult language in child problems
- ❌ Unclear or ambiguous questions
- ❌ Missing progressive hint structure
- ❌ No real-world connections

## 🎨 **EXAMPLE IMPROVEMENT**

### **Before (Overcomplicated)**
```json
{
  "complex_nested_structure": {
    "metadata": { "deep": { "nesting": "bad" }},
    "student_interface": {
      "interaction_patterns": {
        "step_sequence": [
          {
            "prompt": "Confusing technical question",
            "acceptable_responses": [],
            "evaluation_criteria": { "complex": "logic" }
          }
        ]
      }
    }
  }
}
```

### **After (Clean & Educational)**
```json
{
  "id": "FRACTIONS-S1-E1",
  "title": "Sharing a Delicious Cake",
  "problem_text": "Mei Ling had 3/4 of a cake left after her birthday party. She wanted to share this remaining cake equally among herself and 2 friends. What fraction of the original cake did each person receive?",
  "student_view": {
    "steps": [{
      "prompt": "How many people are sharing the cake in total?",
      "acceptable_responses": ["3"],
      "hints": {
        "L1": "Read the problem carefully. Who is sharing the cake?",
        "L2": "It's Mei Ling AND 2 friends. How many does that make?",
        "L3": "Mei Ling (1 person) + 2 friends = 3 people."
      }
    }]
  }
}
```

## 🎯 **IMPLEMENTATION STATUS**

✅ **Backend Fixed**: Now shows `problem_text` before first step  
✅ **Sample Updated**: First fractions problem has proper `acceptable_responses`  
✅ **Structure Validated**: Follows all multi-expert guidelines  
✅ **AI Compatible**: Clean structure for LLM processing  

## 🚀 **NEXT STEPS**

1. **Content Generation**: Use this template for all new problems
2. **Existing Migration**: Gradually update current JSON files
3. **AI Training**: Feed clean structure to improve response quality
4. **Educator Review**: Have Singapore teachers validate problem contexts

---

**This structure ensures beautiful UI, functional AI tutoring, and effective learning outcomes! 🌟**