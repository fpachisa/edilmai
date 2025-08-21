from fastapi import APIRouter, HTTPException
from typing import Optional
from models.schemas import (
    SessionStartRequest,
    AdaptiveSessionStartRequest,
    SessionStartResponse,
    SessionStepRequest,
    SessionStepResponse,
    SessionEndRequest,
)
from services.container import ITEMS_REPO, SESSIONS_REPO, PROFILES_REPO, PROGRESSION_SERVICE
from services.orchestrator import SimpleOrchestrator

router = APIRouter()
_ORCH = SimpleOrchestrator()




def _extract_topic_from_request(req) -> str:
    """Extract topic from request item_id - FAIL if not found."""
    print(f"🔍 DEBUG: Request has item_id: {getattr(req, 'item_id', 'NO ITEM_ID')}")
    
    if not hasattr(req, 'item_id') or not req.item_id:
        print(f"🔍 DEBUG: No item_id provided in request")
        raise HTTPException(status_code=400, detail="item_id is required")
    
    return _extract_topic_from_item_id(req.item_id)


def _extract_subtopic_from_item_id(item_id: str) -> Optional[str]:
    """Extract subtopic identifier from item_id if it's a subtopic (not a specific question)."""
    if not item_id:
        return None
        
    # Check if this looks like a subtopic identifier (kebab-case, no question numbers)
    # Examples: "dividing-whole-by-proper-fractions", "introduction-to-algebra"
    if "-" in item_id and not item_id.startswith(("ALGEBRA-", "FRACTIONS-", "GEOMETRY-", "PERCENTAGE-", "RATIO-", "SPEED-", "STATISTICS-")):
        # This looks like a subtopic identifier
        return item_id.lower()
        
    return None


def _extract_topic_from_item_id(item_id: str) -> str:
    """Extract topic from item_id using curriculum service."""
    if not item_id:
        raise HTTPException(status_code=400, detail="item_id cannot be empty")
        
    item_id_lower = item_id.lower()
    print(f"🔍 DEBUG: Looking up topic for item_id '{item_id_lower}'")
    
    try:
        # Get the question from hybrid ITEMS_REPO (loaded from Firestore at startup)
        question = ITEMS_REPO.get_item(item_id)
        if question:
            topic = question.get("topic", "")
            print(f"🔍 DEBUG: Found topic from hybrid repo: '{item_id}' → '{topic}'")
            return topic
        
        # If question not found, try to infer topic from item_id patterns
        # This handles legacy item_ids and subtopic mapping
        topic_patterns = {
            'algebra': ['algebra', 'algebraic', 'equation', 'expression'],
            'fractions': ['fraction', 'mixed', 'numerator', 'denominator'],
            'percentage': ['percent', '%', 'increase', 'decrease'],
            'ratio': ['ratio', 'proportion', 'equivalent'],
            'speed': ['speed', 'distance', 'time', 'velocity'],
            'geometry': ['area', 'perimeter', 'angle', 'shape', 'measurement'],
            'data-analysis': ['graph', 'chart', 'data', 'bar', 'pie', 'line']
        }
        
        # Check if item_id contains any topic keywords
        for topic, keywords in topic_patterns.items():
            for keyword in keywords:
                if keyword in item_id_lower:
                    print(f"🔍 DEBUG: Inferred topic from pattern: '{item_id}' → '{topic}'")
                    return topic
        
        # Last resort: check if it's a direct topic match
        known_topics = list(topic_patterns.keys())
        for topic in known_topics:
            if topic.replace('-', '') in item_id_lower or topic in item_id_lower:
                print(f"🔍 DEBUG: Direct topic match: '{item_id}' → '{topic}'")
                return topic
    
    except Exception as e:
        print(f"🔍 DEBUG: Error looking up topic: {e}")
    
    # Fail clearly if topic can't be determined
    print(f"🔍 DEBUG: Could not determine topic from item_id '{item_id}'")
    raise HTTPException(status_code=400, detail=f"Cannot determine topic from item_id: {item_id}. Question may not exist in curriculum database.")




@router.post("/session/start", response_model=SessionStartResponse)
def start_session(req: SessionStartRequest):
    curriculum_service = get_curriculum_service()
    item = curriculum_service.get_question(req.item_id)
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
    
    # Include assets from the item data
    assets = None
    if 'assets' in item:
        assets = item['assets']
    elif 'asset' in item:  # Handle different naming conventions
        assets = item['asset']
    
    return SessionStartResponse(session_id=sid, step_id="main", prompt=clean_prompt, assets=assets)


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
    
    # Include assets from the item data
    assets = None
    if 'assets' in item:
        assets = item['assets']
    elif 'asset' in item:  # Handle different naming conventions
        assets = item['asset']
    
    return SessionStartResponse(session_id=session_id, step_id="main", prompt=clean_prompt, assets=assets)


@router.post("/session/start-adaptive", response_model=SessionStartResponse)
def start_adaptive_session(req: AdaptiveSessionStartRequest):
    """Start an adaptive session that progresses through any math topic."""
    print(f"🔍 DEBUG: start_adaptive_session called with learner_id={req.learner_id}, item_id={getattr(req, 'item_id', None)}")
    
    learner_profile = PROFILES_REPO.get_profile(req.learner_id)
    
    # Detect topic from request
    topic_name = _extract_topic_from_request(req)
    print(f"🔍 DEBUG: Detected topic: {topic_name}")
    
    # Try both lowercase and capitalized versions for Firestore query
    topic_variations = [topic_name, topic_name.capitalize(), topic_name.upper()]
    print(f"🔍 DEBUG: Will try topic variations: {topic_variations}")
    
    # If item_id is provided, use it; otherwise find next in progression
    item_id = req.item_id
    print(f"🔍 DEBUG: Original item_id from request: {item_id}")
    
    # FIRST: Check if item_id is a subtopic identifier BEFORE any legacy mapping
    subtopic_filter = None
    if item_id:
        subtopic_filter = _extract_subtopic_from_item_id(item_id)
        if subtopic_filter:
            print(f"🔍 DEBUG: Detected subtopic identifier '{item_id}' -> filter: '{subtopic_filter}'")
            # Get first question from this specific subtopic
            item_id = PROGRESSION_SERVICE.recommend_next_session(learner_profile, topic_name, subtopic_filter)
            print(f"🔍 DEBUG: Recommended item_id for subtopic '{subtopic_filter}': {item_id}")
            if not item_id:
                raise HTTPException(status_code=404, detail=f"No more items available in {topic_name} subtopic '{subtopic_filter}' progression")
        else:
            # No subtopic filter detected, continue with original item_id
            print(f"🔍 DEBUG: No subtopic detected, using original item_id: {item_id}")
    
    if not item_id:
        print(f"🔍 DEBUG: No item_id, getting recommendation for topic '{topic_name}' with subtopic_filter '{subtopic_filter}'")
        # Use progression service to get next question in progression (more reliable than curriculum service)
        # CRITICAL FIX: Pass subtopic_filter to maintain subtopic filtering context
        item_id = PROGRESSION_SERVICE.recommend_next_session(learner_profile, topic_name, subtopic_filter)
        print(f"🔍 DEBUG: Recommended item_id: {item_id}")
        if not item_id:
            raise HTTPException(status_code=404, detail=f"No more items available in {topic_name} progression")
    
    item = ITEMS_REPO.get_item(item_id)
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    
    sid = SESSIONS_REPO.create_session(req.learner_id, item_id)
    PROFILES_REPO.set_current_session(req.learner_id, sid)
    
    # Add system message about progression
    progression_status = PROGRESSION_SERVICE.get_progression_status(learner_profile["completed_items"], topic_name)
    SESSIONS_REPO.add_to_conversation(sid, "system", 
                                    f"Starting {topic_name} session. Progress: {progression_status['completed_count']}/{progression_status['total_items']} items completed.",
                                    {"progression_status": progression_status})
    
    # Pure problem presentation - let AI handle all context and guidance
    problem_text = item.get('problem_text', 'No problem description available.')
    title = item.get('title', 'Practice Problem')
    
    # Clean, minimal prompt - AI will provide all tutoring context
    clean_prompt = f"{title}\n\n{problem_text}"
    
    # Include assets from the item data
    assets = None
    if 'assets' in item:
        assets = item['assets']
    elif 'asset' in item:  # Handle different naming conventions
        assets = item['asset']
    
    return SessionStartResponse(session_id=sid, step_id="main", prompt=clean_prompt, assets=assets)


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
        # Extract topic from current item to find next item in same topic progression
        topic_name = _extract_topic_from_item_id(session["item_id"])
        # CRITICAL FIX: Extract subtopic from completed item to stay within same subtopic
        # Now using hybrid repo which loads from Firestore at startup
        completed_item = ITEMS_REPO.get_item(item_id)
        subtopic_filter = completed_item.get("subtopic") if completed_item else None
        print(f"🔍 DEBUG: Looking for next item in topic '{topic_name}' subtopic '{subtopic_filter}' after completing '{item_id}'")
        print(f"🔍 DEBUG: Learner completed items: {learner_profile.get('completed_items', [])}")
        next_item_id = PROGRESSION_SERVICE.recommend_next_session(learner_profile, topic_name, subtopic_filter)
        print(f"🔍 DEBUG: Progression service recommended: {next_item_id}")
        
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
            completion_message = f"🎉 Congratulations! You've completed '{item.get('title', 'this problem')}' and finished all available {topic_name} topics!\n\n" + \
                               f"You're now a {topic_name} expert! 🌟"
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
    """Continue with next item in progression."""
    session = SESSIONS_REPO.get(req.session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    
    learner_id = session["learner_id"]
    current_item_id = session["item_id"]
    learner_profile = PROFILES_REPO.get_profile(learner_id)
    
    # Get next item in progression
    # Extract topic from current session to continue in same topic
    topic_name = _extract_topic_from_item_id(current_item_id)
    # CRITICAL FIX: Extract subtopic from current item to maintain subtopic filtering
    current_item = ITEMS_REPO.get_item(current_item_id)
    subtopic_filter = current_item.get("subtopic") if current_item else None
    print(f"🔍 DEBUG: continue-progression topic '{topic_name}' subtopic '{subtopic_filter}'")
    next_item_id = PROGRESSION_SERVICE.recommend_next_session(learner_profile, topic_name, subtopic_filter)
    if not next_item_id:
        raise HTTPException(status_code=404, detail="No more items available in progression")
    
    # Start new session with next item
    return start_adaptive_session(AdaptiveSessionStartRequest(learner_id=learner_id, item_id=next_item_id))


@router.get("/session/progression-status/{learner_id}/{topic_name}")
def get_progression_status(learner_id: str, topic_name: str):
    """Get learner's progression status through any topic."""
    learner_profile = PROFILES_REPO.get_profile(learner_id)
    progression_status = PROGRESSION_SERVICE.get_progression_status(learner_profile["completed_items"], topic_name)
    
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
