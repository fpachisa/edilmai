from __future__ import annotations
from typing import Tuple, Optional, Dict, Any, List
from sympy import sympify, Eq

from core.config import settings
from .llm import build_llm, LLMClient


def cas_equivalent(user: str, target: str) -> bool:
    """Fallback CAS check for complex algebraic expressions."""
    try:
        return bool(Eq(sympify(user), sympify(target)))
    except Exception:
        return False


class SimpleOrchestrator:
    def __init__(self, llm: LLMClient | None = None):
        self._llm = llm or build_llm()

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

        # Additional CAS check as fallback for complex algebraic expressions
        if not is_correct and settings.cas_enabled and expected_answers:
            for expected in expected_answers:
                if cas_equivalent(user_response.strip(), expected.strip()):
                    is_correct = True
                    should_advance = True
                    response_text = "Excellent! That's mathematically equivalent. Let's move on."
                    break

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
