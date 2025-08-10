from __future__ import annotations
from typing import Tuple, Optional, Dict, Any
import re
from sympy import sympify, Eq

from core.config import settings
from .llm import build_llm, LLMClient


def regex_match(user: str, patterns) -> bool:
    if not patterns:
        return False
    normalized = user.replace(" ", "").lower()
    for p in patterns:
        eq = p.get("equivalent_to")
        if not eq:
            continue
        if normalized == eq.replace(" ", "").lower():
            return True
        if re.fullmatch(eq, normalized):
            return True
    return False


def cas_equivalent(user: str, target: str) -> bool:
    try:
        return bool(Eq(sympify(user), sympify(target)))
    except Exception:
        return False


class SimpleOrchestrator:
    def __init__(self, llm: LLMClient | None = None):
        self._llm = llm or build_llm()

    def evaluate(self, user_response: str, item: dict, step: dict, attempts_so_far: int) -> Tuple[Optional[bool], Optional[str], Optional[str]]:
        """Evaluate response against rules and return (correctness, next_prompt, hint).

        - correctness True: caller should advance to next step and show next prompt (if any)
        - correctness None/False: keep same step; provide hint based on attempts
        """
        rules = (item.get("evaluation") or {}).get("rules") or {}
        # 1) Regex exact/normalised
        if settings.regex_enabled and regex_match(user_response, rules.get("regex")):
            return True, "Great! Let's go to the next step.", None
        # 2) CAS equivalence if enabled
        if settings.cas_enabled and rules.get("algebraic_equivalence"):
            targets = [r.get("equivalent_to") for r in (rules.get("regex") or []) if r.get("equivalent_to")]
            for t in targets:
                if cas_equivalent(user_response, t):
                    return True, "Nice work. Next step coming up.", None
        # 3) Not correct → prefer human-like Socratic nudge via LLM
        if self._llm:
            msg = self._llm.generate_socratic(
                problem_text=item.get("problem_text", ""),
                step_prompt=step.get("prompt", ""),
                user_response=user_response,
                attempts=attempts_so_far,
            )
            if msg:
                return None, None, msg
        # Fallback: choose a concise hint from the ladder
        hint_text = self._pick_hint(step, attempts_so_far)
        return None, None, hint_text

    def _pick_hint(self, step: Dict[str, Any], attempts_so_far: int) -> str:
        hints = step.get("hints") or []
        # Map attempts 0→L1, 1→L2, 2+→L3 (cap)
        desired_level = min(3, attempts_so_far + 1)
        # try exact level, else the highest available below desired, else any
        for level in (desired_level, desired_level - 1, desired_level + 1):
            for h in hints:
                if h.get("level") == level:
                    return h.get("text") or "Think about the operation needed."
        return (hints[0].get("text") if hints else None) or "Let's break it down: what changes from b when 4 are added?"
