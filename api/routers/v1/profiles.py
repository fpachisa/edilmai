from fastapi import APIRouter
from services.container import PROFILES_REPO

router = APIRouter()


@router.get("/profile/{learner_id}")
def get_profile(learner_id: str):
    return PROFILES_REPO.get_profile(learner_id)
