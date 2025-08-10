from __future__ import annotations
from typing import Optional
from core.config import settings


class LLMClient:
    def generate_socratic(self, *, problem_text: str, step_prompt: str, user_response: str, attempts: int) -> Optional[str]:
        raise NotImplementedError


class GeminiLLM(LLMClient):
    def __init__(self, model_name: Optional[str] = None):
        self.model_name = model_name or "gemini-1.5-flash"
        # Lazy import to avoid heavy import on cold paths
        from google.cloud import aiplatform  # noqa: F401
        from vertexai import init as vx_init
        from vertexai.generative_models import GenerativeModel

        vx_init(project=settings.vertex_project_id or settings.env, location=settings.vertex_location)
        self._model = GenerativeModel(self.model_name)

    def generate_socratic(self, *, problem_text: str, step_prompt: str, user_response: str, attempts: int) -> Optional[str]:
        try:
            sys = (
                "You are a patient, engaging Socratic math tutor for Primary 6 (Singapore). "
                "Speak in short, friendly sentences. Ask one question at a time. "
                "Never reveal the final answer. Encourage the learner."
            )
            user_msg = (
                f"Problem: {problem_text}\n"
                f"Current step: {step_prompt}\n"
                f"Learner answer: {user_response}\n"
                f"Attempts on this step: {attempts}.\n"
                "Respond with a single Socratic question or nudge to guide them."
            )
            resp = self._model.generate_content([sys, user_msg])
            text = getattr(resp, "text", None) or (resp.candidates[0].content.parts[0].text if resp.candidates else None)  # type: ignore[attr-defined]
            if text:
                # Trim to keep concise
                return text.strip()
            return None
        except Exception:
            return None


def build_llm() -> Optional[LLMClient]:
    if not settings.enable_llm:
        return None
    prov = (settings.llm_provider or "").lower()
    if prov in ("vertex", "gemini", "google"):
        return GeminiLLM(model_name=settings.llm_model or "gemini-1.5-flash")
    # Other providers can be added here
    return None

