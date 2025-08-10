from fastapi import APIRouter, HTTPException
from models.schemas import (
    SessionStartRequest,
    SessionStartResponse,
    SessionStepRequest,
    SessionStepResponse,
    SessionEndRequest,
)
from services.container import ITEMS_REPO, SESSIONS_REPO
from services.orchestrator import SimpleOrchestrator

router = APIRouter()
_ORCH = SimpleOrchestrator()


@router.post("/session/start", response_model=SessionStartResponse)
def start_session(req: SessionStartRequest):
    item = ITEMS_REPO.get_item(req.item_id)
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    sid = SESSIONS_REPO.create_session(req.learner_id, req.item_id)
    steps = (item.get("student_view") or {}).get("steps") or []
    if not steps:
        raise HTTPException(status_code=422, detail="Item has no steps")
    first = steps[0]
    return SessionStartResponse(session_id=sid, step_id=first.get("id", "s1"), prompt=first.get("prompt", "Let's begin."))


@router.post("/session/step", response_model=SessionStepResponse)
def do_step(req: SessionStepRequest):
    session = SESSIONS_REPO.get(req.session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    item = ITEMS_REPO.get_item(session["item_id"]) or {}
    steps = (item.get("student_view") or {}).get("steps") or []
    idx = session.get("current_step_idx", 0)
    finished = session.get("finished", False)
    if finished:
        return SessionStepResponse(correctness=True, next_prompt=None, hint=None, updates={}, finished=True, step_id=None)
    if idx >= len(steps):
        SESSIONS_REPO.mark_finished(req.session_id)
        return SessionStepResponse(correctness=True, next_prompt=None, hint=None, updates={}, finished=True, step_id=None)
    current = steps[idx]
    # Evaluate
    correctness, next_prompt, hint = _ORCH.evaluate(req.user_response, item, current, session.get("attempts_current", 0))
    SESSIONS_REPO.append_step(req.session_id, {"step_id": current.get("id"), "response": req.user_response, "correct": correctness})
    if correctness is True:
        # Advance to next step
        SESSIONS_REPO.advance_step(req.session_id)
        next_idx = session.get("current_step_idx", 0)
        if next_idx >= len(steps):
            SESSIONS_REPO.mark_finished(req.session_id)
            return SessionStepResponse(correctness=True, next_prompt=next_prompt or "All steps complete!", hint=None, tutor_message=next_prompt, updates={}, finished=True, step_id=None)
        next_step = steps[next_idx]
        nm = next_prompt or next_step.get("prompt")
        return SessionStepResponse(correctness=True, next_prompt=nm, hint=None, tutor_message=nm, updates={}, finished=False, step_id=next_step.get("id"))
    else:
        # Incorrect/uncertain: increment attempts and provide hint
        SESSIONS_REPO.inc_attempt(req.session_id)
        return SessionStepResponse(correctness=False, next_prompt=None, hint=hint, tutor_message=hint, updates={}, finished=False, step_id=current.get("id"))


@router.post("/session/end")
def end_session(req: SessionEndRequest):
    if not SESSIONS_REPO.get(req.session_id):
        raise HTTPException(status_code=404, detail="Session not found")
    return {"session_id": req.session_id, "status": "ended"}
