from fastapi import APIRouter, HTTPException
from api.models.schemas import (
    SessionStartRequest,
    AdaptiveSessionStartRequest,
    SessionStartResponse,
    SessionStepRequest,
    SessionStepResponse,
    SessionEndRequest,
)
from api.services.container import ITEMS_REPO, SESSIONS_REPO, PROFILES_REPO
from api.services.orchestrator import SimpleOrchestrator
from api.services.progression import PROGRESSION_SERVICE

router = APIRouter()
_ORCH = SimpleOrchestrator()


def _map_legacy_item_id(legacy_id: str) -> str:
    """Map old-style item IDs to new question IDs."""
    # Map subtopic names to their first question ID
    legacy_mapping = {
        "introduction-to-algebra": "ALGEBRA-INTRODUCTION-TO-ALGEBRA-Q1",
        "simplifying-algebraic-expressions": "ALGEBRA-SIMPLIFYING-ALGEBRAIC-EXPRESSIONS-Q1",
        "evaluating-algebraic-expressions": "ALGEBRA-EVALUATING-ALGEBRAIC-EXPRESSIONS-Q1",
        "algebra-word-problems": "ALGEBRA-ALGEBRA-WORD-PROBLEMS-Q1",
        "algebra": "ALGEBRA-INTRODUCTION-TO-ALGEBRA-Q1",  # Default algebra start
    }
    
    return legacy_mapping.get(legacy_id.lower(), legacy_id)


@router.post("/session/start", response_model=SessionStartResponse)
def start_session(req: SessionStartRequest):
    item = ITEMS_REPO.get_item(req.item_id)
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    sid = SESSIONS_REPO.create_session(req.learner_id, req.item_id)
    
    # Track session in learner profile
    PROFILES_REPO.set_current_session(req.learner_id, sid)
    
    # Pure problem presentation - let AI handle all context and guidance
    problem_text = item.get('problem_text', 'No problem description available.')
    title = item.get('title', 'Practice Problem')
    
    # Clean, minimal prompt - AI will provide all tutoring context
    clean_prompt = f"{title}\n\n{problem_text}"
    
    return SessionStartResponse(session_id=sid, step_id="main", prompt=clean_prompt)


@router.get("/session/{session_id}", response_model=SessionStartResponse)
def get_session(session_id: str):
    """Resume an existing session by returning the current step and prompt."""
    session = SESSIONS_REPO.get(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    item = ITEMS_REPO.get_item(session.get("item_id"))
    if not item:
        raise HTTPException(status_code=404, detail="Item not found for session")
    
    # Pure problem presentation - let AI handle all context and guidance
    problem_text = item.get('problem_text', 'No problem description available.')
    title = item.get('title', 'Practice Problem')
    
    # Clean, minimal prompt - AI will provide all tutoring context
    clean_prompt = f"{title}\n\n{problem_text}"
    return SessionStartResponse(session_id=session_id, step_id="main", prompt=clean_prompt)


@router.post("/session/start-adaptive", response_model=SessionStartResponse)
def start_adaptive_session(req: AdaptiveSessionStartRequest):
    """Start an adaptive session that progresses through algebra topics."""
    learner_profile = PROFILES_REPO.get_profile(req.learner_id)
    
    # If item_id is provided, use it; otherwise find next in progression
    item_id = req.item_id
    if item_id:
        # Handle old-style item_id mapping (e.g., "introduction-to-algebra" -> actual question ID)
        item_id = _map_legacy_item_id(item_id)
    
    if not item_id:
        item_id = PROGRESSION_SERVICE.recommend_next_session(learner_profile)
        if not item_id:
            raise HTTPException(status_code=404, detail="No more items available in progression")
    
    item = ITEMS_REPO.get_item(item_id)
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    
    sid = SESSIONS_REPO.create_session(req.learner_id, item_id)
    PROFILES_REPO.set_current_session(req.learner_id, sid)
    
    # Add system message about progression
    progression_status = PROGRESSION_SERVICE.get_progression_status(learner_profile["completed_items"])
    SESSIONS_REPO.add_to_conversation(sid, "system", 
                                    f"Starting adaptive session. Progress: {progression_status['completed_count']}/{progression_status['total_items']} items completed.",
                                    {"progression_status": progression_status})
    
    # Pure problem presentation - let AI handle all context and guidance
    problem_text = item.get('problem_text', 'No problem description available.')
    title = item.get('title', 'Practice Problem')
    
    # Clean, minimal prompt - AI will provide all tutoring context
    clean_prompt = f"{title}\n\n{problem_text}"
    
    return SessionStartResponse(session_id=sid, step_id="main", prompt=clean_prompt)


@router.post("/session/step", response_model=SessionStepResponse)
def do_step(req: SessionStepRequest):
    session = SESSIONS_REPO.get(req.session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    item = ITEMS_REPO.get_item(session["item_id"]) or {}
    
    finished = session.get("finished", False)
    if finished:
        return SessionStepResponse(correctness=True, next_prompt=None, hint=None, updates={}, finished=True, step_id=None)
    
    # Add student response to conversation history
    SESSIONS_REPO.add_to_conversation(req.session_id, "student", req.user_response, 
                                    {"step_id": "main", "attempt": session.get("attempts_current", 0) + 1})
    
    # Evaluate using new simplified structure
    correctness, next_prompt, hint, evaluation_data = _ORCH.evaluate_simplified(req.user_response, item, 
                                                                               session.get("attempts_current", 0), session)
    SESSIONS_REPO.append_step(req.session_id, {"step_id": "main", "response": req.user_response, "correct": correctness})
    
    # Store learning insight if provided
    learning_insight = evaluation_data.get("learning_insight", "")
    if learning_insight and learning_insight.strip():
        SESSIONS_REPO.add_learning_insight(req.session_id, learning_insight.strip())
    
    # Store misconceptions if identified
    misconception_tags = evaluation_data.get("misconception_tags", [])
    confidence_level = evaluation_data.get("confidence_level", 1.0)
    if misconception_tags:
        SESSIONS_REPO.record_misconceptions(req.session_id, misconception_tags, confidence_level)
    
    # Handle AI evaluation failure
    if correctness is None:
        # AI evaluation failed - return transparent error
        ai_error_msg = evaluation_data.get("error", "AI evaluation system temporarily unavailable")
        return SessionStepResponse(
            correctness=None, 
            next_prompt=None, 
            hint=hint or "Oops! I need a moment to think about your answer. Please try submitting it again!", 
            tutor_message="I'm taking a moment to process your answer. Please try again!",
            updates={"ai_error": ai_error_msg}, 
            finished=False, 
            step_id="main"
        )
    
    if correctness is True:
        # Add tutor response to conversation history
        tutor_response = next_prompt or "Great job!"
        SESSIONS_REPO.add_to_conversation(req.session_id, "tutor", tutor_response, 
                                        {"type": "success", "step_id": "main"})
        
        # Check if this is the final answer (based on AI evaluation, not step count)
        # If AI says should_advance and correctness is True, complete the item
        SESSIONS_REPO.mark_finished(req.session_id)
        
        # Mark item as completed in learner profile
        learner_id = session["learner_id"]
        item_id = session["item_id"]
        PROFILES_REPO.mark_item_completed(learner_id, item_id)
        PROFILES_REPO.clear_current_session(learner_id)
        
        # Add XP for completion (base XP on complexity and marks)
        complexity = item.get("complexity", "Easy")
        marks = item.get("marks", 1)
        base_xp = {"Easy": 10, "Medium": 15, "Hard": 20}.get(complexity, 10)
        total_xp = base_xp * marks
        PROFILES_REPO.add_xp(learner_id, total_xp)
        
        # Check if there's a next item in progression
        learner_profile = PROFILES_REPO.get_profile(learner_id)
        next_item_id = PROGRESSION_SERVICE.recommend_next_session(learner_profile)
        
        if next_item_id:
            next_item = ITEMS_REPO.get_item(next_item_id)
            completion_message = f"🎉 Perfect! You've completed '{item.get('title', 'this problem')}'!\n\n" + \
                               f"Ready for the next challenge? Let's move on to: '{next_item.get('title', 'Next Problem')}'"
            return SessionStepResponse(
                correctness=True, 
                next_prompt=completion_message, 
                hint=None, 
                tutor_message=completion_message, 
                updates={
                    "item_completed": True,
                    "next_item_available": True,
                    "next_item_id": next_item_id,
                    "next_item_title": next_item.get('title', 'Next Problem'),
                    "xp_earned": item.get("telemetry", {}).get("scoring", {}).get("xp", 10)
                }, 
                finished=True, 
                step_id=None
            )
        else:
            completion_message = f"🎉 Congratulations! You've completed '{item.get('title', 'this problem')}' and finished all available algebra topics!\n\n" + \
                               f"You're now an algebra expert! 🌟"
            return SessionStepResponse(
                correctness=True, 
                next_prompt=completion_message, 
                hint=None, 
                tutor_message=completion_message, 
                updates={
                    "item_completed": True,
                    "progression_completed": True,
                    "xp_earned": item.get("telemetry", {}).get("scoring", {}).get("xp", 10)
                }, 
                finished=True, 
                step_id=None
            )
    else:
        # Add tutor hint to conversation history
        tutor_hint = hint or "Let me help you think through this."
        SESSIONS_REPO.add_to_conversation(req.session_id, "tutor", tutor_hint, 
                                        {"type": "hint", "step_id": "main", "attempt": session.get("attempts_current", 0) + 1})
        
        # Incorrect/uncertain: increment attempts and provide hint
        SESSIONS_REPO.inc_attempt(req.session_id)
        return SessionStepResponse(correctness=False, next_prompt=None, hint=hint, tutor_message=hint, 
                                 updates={}, finished=False, step_id="main")


@router.post("/session/continue-progression", response_model=SessionStartResponse)
def continue_progression(req: SessionEndRequest):
    """Continue with next item in algebra progression."""
    session = SESSIONS_REPO.get(req.session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    
    learner_id = session["learner_id"]
    learner_profile = PROFILES_REPO.get_profile(learner_id)
    
    # Get next item in progression
    next_item_id = PROGRESSION_SERVICE.recommend_next_session(learner_profile)
    if not next_item_id:
        raise HTTPException(status_code=404, detail="No more items available in progression")
    
    # Start new session with next item
    return start_adaptive_session(AdaptiveSessionStartRequest(learner_id=learner_id, item_id=next_item_id))


@router.get("/session/progression-status/{learner_id}")
def get_progression_status(learner_id: str):
    """Get learner's progression status through algebra topics."""
    learner_profile = PROFILES_REPO.get_profile(learner_id)
    progression_status = PROGRESSION_SERVICE.get_progression_status(learner_profile["completed_items"])
    
    return {
        **progression_status,
        "learner_profile": {
            "xp": learner_profile["xp"],
            "completed_items": learner_profile["completed_items"],
            "current_session_id": learner_profile["current_session_id"]
        }
    }


@router.post("/session/end")
def end_session(req: SessionEndRequest):
    if not SESSIONS_REPO.get(req.session_id):
        raise HTTPException(status_code=404, detail="Session not found")
    return {"session_id": req.session_id, "status": "ended"}
