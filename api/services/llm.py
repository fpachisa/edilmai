from __future__ import annotations
from typing import Optional, Dict, List, Any
from core.config import settings


class LLMClient:
    def evaluate_and_respond(self, *, problem_text: str, step_prompt: str, user_response: str, 
                           attempts: int, hints_guidelines: List[Dict[str, Any]], 
                           expected_answers: List[str], conversation_history: List[Dict[str, Any]] = None,
                           learning_insights: List[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        Evaluate student response and generate tutoring response.
        
        Returns:
            {
                "is_correct": bool,
                "response": str,
                "should_advance": bool,
                "learning_insight": str (optional),
                "misconception_tags": list (optional),
                "confidence_level": float (optional)
            }
        """
        raise NotImplementedError


class GeminiLLM(LLMClient):
    def __init__(self, model_name: Optional[str] = None):
        self.model_name = model_name or "gemini-2.5-flash"
        
        # Try Google AI Studio API first if API key is available
        if settings.google_api_key:
            try:
                import google.generativeai as genai
                
                genai.configure(api_key=settings.google_api_key)
                self._model = genai.GenerativeModel(self.model_name)
                self._use_vertex = False
                print(f"Initialized Gemini with Google AI Studio API")  # Debug logging
                return
            except Exception as e:
                print(f"Google AI Studio initialization failed: {e}")  # Debug logging
        
        # Fallback to Vertex AI if project ID is configured
        if settings.vertex_project_id:
            try:
                import vertexai
                from vertexai.generative_models import GenerativeModel
                
                vertexai.init(project=settings.vertex_project_id, location=settings.vertex_location)
                self._model = GenerativeModel(self.model_name)
                self._use_vertex = True
                print(f"Initialized Gemini with Vertex AI")  # Debug logging
                return
            except Exception as e:
                print(f"Vertex AI initialization failed: {e}")  # Debug logging
        
        raise ValueError("Failed to initialize Gemini: Need either GOOGLE_API_KEY or valid VERTEX_PROJECT_ID")

    def evaluate_and_respond(self, *, problem_text: str, step_prompt: str, user_response: str, 
                           attempts: int, hints_guidelines: List[Dict[str, Any]], 
                           expected_answers: List[str], conversation_history: List[Dict[str, Any]] = None,
                           learning_insights: List[Dict[str, Any]] = None) -> Dict[str, Any]:
        try:
            # Build conversation history context
            context_text = ""
            if conversation_history:
                context_text = "\nCONVERSATION HISTORY (recent exchanges):\n"
                for entry in conversation_history[-5:]:  # Last 5 exchanges
                    role = entry.get("role", "").title()
                    message = entry.get("message", "")
                    context_text += f"{role}: {message}\n"
            
            # Build learning insights context
            insights_text = ""
            if learning_insights:
                insights_text = "\nLEARNING INSIGHTS (student patterns observed):\n"
                for insight in learning_insights[-3:]:  # Last 3 insights
                    insights_text += f"- {insight.get('insight', '')}\n"

            # Build hint guidelines text
            hints_text = ""
            if hints_guidelines:
                hints_text = "\nHint Guidelines (for your reference only - do not copy these directly):\n"
                for hint in hints_guidelines:
                    level = hint.get("level", "")
                    text = hint.get("text", "")
                    hints_text += f"- Level {level}: {text}\n"

            # Build expected answers text
            expected_text = ""
            if expected_answers:
                expected_text = f"\nExpected correct answers: {', '.join(expected_answers)}"

            system_prompt = (
                "You are an expert Socratic math tutor for Primary 6 students (Singapore PSLE level). "
                "Your role is to:\n"
                "1. EVALUATE if the student's answer is mathematically correct\n"
                "2. RESPOND with contextually appropriate tutoring guidance\n"
                "3. IDENTIFY specific misconceptions and learning patterns\n\n"
                "EVALUATION RULES:\n"
                "- Check for mathematical equivalence (e.g., 'b+4', '4+b', 'b + 4' are all correct)\n"
                "- Accept different valid forms of the same answer\n"
                "- Be flexible with formatting and spacing\n\n"
                "MISCONCEPTION DETECTION:\n"
                "When the answer is incorrect, identify specific misconception tags from these common PSLE algebra errors:\n"
                "- 'variable_confusion': mixing up variables or treating them as regular numbers\n"
                "- 'operation_error': wrong operation (addition instead of multiplication, etc.)\n"
                "- 'order_of_operations': incorrect precedence (PEMDAS/BODMAS errors)\n"
                "- 'missing_variable': forgetting to include variables in expression\n"
                "- 'coefficient_error': wrong coefficient or missing coefficient\n"
                "- 'sign_error': positive/negative sign mistakes\n"
                "- 'distributive_error': incorrect distribution over parentheses\n"
                "- 'combine_like_terms': incorrectly combining or not combining like terms\n"
                "- 'substitution_error': wrong substitution of values\n"
                "- 'word_problem_translation': misinterpreting the word problem\n\n"
                "CONTEXTUAL TUTORING:\n"
                "- Use conversation history to build on previous exchanges\n"
                "- Reference past mistakes or successes when relevant\n"
                "- Adapt your approach based on observed misconception patterns\n"
                "- Don't repeat identical guidance - vary your teaching approach\n\n"
                "TUTORING STYLE:\n"
                "- Use encouraging, patient language\n"
                "- Ask Socratic questions to guide thinking\n"
                "- Give hints that build understanding, don't give direct answers\n"
                "- Keep responses short and focused (1-2 sentences)\n"
                "- Address misconceptions without explicitly stating them\n\n"
                "RESPONSE FORMAT:\n"
                "Always respond with exactly this JSON format:\n"
                '{"is_correct": true/false, "response": "your tutoring message", "should_advance": true/false, "learning_insight": "optional insight", "misconception_tags": ["tag1", "tag2"], "confidence_level": 0.8}\n\n'
                "- is_correct: true if answer is mathematically correct, false otherwise\n"
                "- response: your contextual tutoring message to the student\n"
                "- should_advance: true if student should move to next step, false to retry current step\n"
                "- learning_insight: observation about student's learning pattern\n"
                "- misconception_tags: array of identified misconception tags (empty if correct)\n"
                "- confidence_level: your confidence in the evaluation (0.0 to 1.0)"
            )

            user_message = (
                f"PROBLEM: {problem_text}\n\n"
                f"CURRENT STEP: {step_prompt}\n\n"
                f"STUDENT ANSWER: '{user_response}'\n\n"
                f"ATTEMPT NUMBER: {attempts + 1}\n"
                f"{expected_text}"
                f"{context_text}"
                f"{insights_text}"
                f"{hints_text}\n"
                "Using the conversation context and learning insights, evaluate the student's answer and provide "
                "a contextually appropriate tutoring response in JSON format."
            )

            if self._use_vertex:
                resp = self._model.generate_content([system_prompt, user_message])
                text = getattr(resp, "text", None) or (resp.candidates[0].content.parts[0].text if resp.candidates else None)
            else:
                # Google AI Studio API
                resp = self._model.generate_content([system_prompt, user_message])
                text = resp.text if hasattr(resp, 'text') else None
            
            if text:
                print(f"Gemini raw response: {text}")  # Debug logging
                import json
                # Try to extract JSON from response
                text = text.strip()
                if text.startswith("```json"):
                    text = text[7:]
                if text.endswith("```"):
                    text = text[:-3]
                text = text.strip()
                
                print(f"Processed text for JSON: {text}")  # Debug logging
                
                try:
                    result = json.loads(text)
                    print(f"Parsed JSON result: {result}")  # Debug logging
                    # Validate required fields
                    required_fields = ["is_correct", "response", "should_advance"]
                    if all(key in result for key in required_fields):
                        # Ensure optional fields are present
                        if "learning_insight" not in result:
                            result["learning_insight"] = ""
                        if "misconception_tags" not in result:
                            result["misconception_tags"] = []
                        if "confidence_level" not in result:
                            result["confidence_level"] = 1.0
                        return result
                    else:
                        print(f"Missing required fields in result: {result}")  # Debug logging
                except json.JSONDecodeError as e:
                    print(f"JSON decode error: {e}")  # Debug logging
            else:
                print("No text received from Gemini")  # Debug logging
            
            # Fallback response
            return {
                "is_correct": False,
                "response": "Let me help you think through this step by step. What operation do you think we need here?",
                "should_advance": False
            }
        except Exception as e:
            # Fallback response on error
            print(f"LLM Error: {e}")  # Debug logging
            import traceback
            traceback.print_exc()  # Debug logging
            return {
                "is_correct": False,
                "response": f"I'm having trouble right now. Let me try to help: What operation do you think we need here? (Debug: {str(e)[:100]})",
                "should_advance": False
            }


def build_llm() -> Optional[LLMClient]:
    if not settings.enable_llm:
        return None
    prov = (settings.llm_provider or "").lower()
    if prov in ("vertex", "gemini", "google"):
        return GeminiLLM(model_name=settings.llm_model or "gemini-2.5-flash-lite")
    # Other providers can be added here
    return None

