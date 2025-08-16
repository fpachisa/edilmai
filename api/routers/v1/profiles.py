from fastapi import APIRouter
from api.services.container import PROFILES_REPO

router = APIRouter()


@router.get("/profile/{learner_id}")
def get_profile(learner_id: str):
    p = PROFILES_REPO.get_profile(learner_id)
    # Ensure metadata keys exist for client hydration
    p.setdefault("name", "Your Learner")
    p.setdefault("grade_level", "P6")
    p.setdefault("subjects", ["maths"])
    # Optionally compute mastery_pct later. For now, return empty map.
    p.setdefault("mastery_pct", {})
    return p
