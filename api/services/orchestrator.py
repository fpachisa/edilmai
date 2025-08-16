from __future__ import annotations
from typing import Tuple, Optional, Dict, Any, List
from sympy import sympify, Eq

from api.core.config import settings
from api.services.llm import build_llm, LLMClient


def cas_equivalent(user: str, target: str) -> bool:
    """Fallback CAS check for complex algebraic expressions."""
    try:
        return bool(Eq(sympify(user), sympify(target)))
    except Exception:
        return False


class SimpleOrchestrator:
    def __init__(self, llm: LLMClient | None = None):
        self._llm = llm or build_llm()

    def evaluate_simplified(self, user_response: str, item: dict, attempts_so_far: int, 
                          session: dict = None) -> Tuple[Optional[bool], Optional[str], Optional[str], dict]:
        """Evaluate response using new simplified structure with answer_details and ai_guidance.
        
        Returns: (correctness, next_prompt, hint, evaluation_data)
        """
        if not self._llm:
            return None, None, "I need to think about this. Let's try again.", {}

        # Extract answer details and AI guidance from new structure
        answer_details = item.get("answer_details", {})
        ai_guidance = item.get("ai_guidance", {})
        
        correct_answer = answer_details.get("correct_answer", "")
        alternative_answers = answer_details.get("alternative_answers", [])
        all_accepted_answers = [correct_answer] + alternative_answers
        
        # Get AI guidance information
        evaluation_strategy = ai_guidance.get("evaluation_strategy", "Direct comparison")
        keywords = ai_guidance.get("keywords", [])
        misconceptions = ai_guidance.get("common_misconceptions", {})
        hints = ai_guidance.get("hints", [])
        full_solution = ai_guidance.get("full_solution", "")

        # TRUE AI-FIRST: No hardcoded evaluations - AI handles all assessment
        # Extract context for AI evaluation
        answer_format = answer_details.get("answer_format", "text")

        # Get conversation context
        conversation_history = []
        if session:
            conversation_history = session.get("conversation_history", [])

        # Build AI evaluation prompt using the simplified, focused structure
        system_prompt = f"""You are a patient Primary 6 Mathematics tutor in a learning app designed specifically for Singapore primary school students. Stay focused on helping with mathematics learning only.

PROBLEM: {item.get('problem_text', '')}
CORRECT ANSWER: {correct_answer}
STUDENT ANSWERED: "{user_response}"

TEACHING RESOURCES (use these to guide your response):
{ai_guidance}

EVALUATION RULES:
1. If the answer is exactly correct → praise and confirm
2. If the answer is partially correct → acknowledge what's right, then guide toward what's missing  
3. If the answer is wrong → check if it matches a common mistake, then give an appropriate hint
4. Always be encouraging and use simple language appropriate for Primary 6 students
5. Stay focused on mathematics learning - do not discuss other topics

RESPONSE FORMAT (JSON only):
{{
    "is_correct": true/false,
    "feedback": "Your encouraging message to the student",
    "should_advance": true/false
}}

Example responses:
- Correct: "Perfect! That's exactly right! 🎉"
- Partially correct: "Good start! You got the teams part (5g) right. Now what about the reserve students?"
- Wrong: "I can see your thinking, but let's look at this part of the problem again..."
"""

        try:
            response = self._llm.generate(system_prompt, max_tokens=500)
            result = self._llm.parse_json_response(response, {
                "is_correct": False,
                "feedback": "Let me think about that...",
                "should_advance": False
            })

            correctness = result.get("is_correct", False)
            feedback = result.get("feedback", "")
            should_advance = result.get("should_advance", False)
            
            # Use feedback as both next_prompt and hint for the simplified structure
            next_prompt = feedback if correctness else None
            hint = feedback if not correctness else None
            
            # Prepare evaluation data
            evaluation_data = {
                "learning_insight": feedback,
                "misconception_tags": [],  # Simplified - no longer extracting specific misconceptions
                "confidence_level": 0.9 if correctness else 0.7
            }

            return correctness, next_prompt, hint, evaluation_data

        except Exception as e:
            print(f"AI evaluation failed: {e}")
            # TRUE AI-FIRST: No fallback evaluation - transparent failure
            return None, None, "Oops! I need a moment to think about your answer. Please try submitting it again!", {
                "error": f"AI_EVALUATION_FAILED: {str(e)}"
            }

    def evaluate(self, user_response: str, item: dict, step: dict, attempts_so_far: int, 
                session: dict = None) -> Tuple[Optional[bool], Optional[str], Optional[str], Optional[str]]:
        """Evaluate response using AI tutor and return (correctness, next_prompt, hint, learning_insight).

        - correctness True: caller should advance to next step and show next prompt (if any)
        - correctness None/False: keep same step; provide hint based on attempts
        """
        if not self._llm:
            # Fallback if LLM is not available
            return None, None, "I need to think about this. Let's try again.", None

        # Extract hints from step to use as guidelines
        hints_guidelines = step.get("hints", [])
        
        # Extract expected answers from evaluation rules
        expected_answers = []
        rules = (item.get("evaluation") or {}).get("rules") or {}
        regex_patterns = rules.get("regex", [])
        for pattern in regex_patterns:
            if pattern.get("equivalent_to"):
                expected_answers.append(pattern["equivalent_to"])

        # Get conversation context if session is provided
        conversation_history = []
        learning_insights = []
        if session:
            conversation_history = session.get("conversation_history", [])
            learning_insights = session.get("learning_insights", [])
            # Add misconception context to insights
            misconception_summary = session.get("misconceptions", {})
            if misconception_summary:
                misconception_text = "Past misconceptions: " + ", ".join([
                    f"{tag} ({data['count']}x)" for tag, data in misconception_summary.items()
                ])
                learning_insights.append({"insight": misconception_text, "confidence": 1.0})

        # Use AI to evaluate and respond
        ai_response = self._llm.evaluate_and_respond(
            problem_text=item.get("problem_text", ""),
            step_prompt=step.get("prompt", ""),
            user_response=user_response,
            attempts=attempts_so_far,
            hints_guidelines=hints_guidelines,
            expected_answers=expected_answers,
            conversation_history=conversation_history,
            learning_insights=learning_insights
        )

        is_correct = ai_response.get("is_correct", False)
        response_text = ai_response.get("response", "Let's try again.")
        should_advance = ai_response.get("should_advance", False)
        learning_insight = ai_response.get("learning_insight", "")
        misconception_tags = ai_response.get("misconception_tags", [])
        confidence_level = ai_response.get("confidence_level", 1.0)

        # TRUE AI-FIRST: No CAS fallback - AI handles all mathematical reasoning

        # Return results with misconception data
        result = {
            "learning_insight": learning_insight,
            "misconception_tags": misconception_tags,
            "confidence_level": confidence_level
        }
        
        if is_correct and should_advance:
            return True, response_text, None, result
        else:
            # Return as hint for incorrect responses
            return None, None, response_text, result
