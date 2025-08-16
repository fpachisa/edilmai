from fastapi import APIRouter, Request, HTTPException
from api.models.schemas import CreateLearnerRequest, LearnerSummary
from api.services.container import PROFILES_REPO, PARENTS_REPO

router = APIRouter()


def _require_user(request: Request) -> dict:
    user = getattr(request.state, "user", None)
    if not user or not user.get("uid"):
        raise HTTPException(status_code=401, detail="Unauthorized")
    return user


@router.post("/parents/learners", response_model=LearnerSummary)
def create_learner(req: CreateLearnerRequest, request: Request):
    user = _require_user(request)
    parent_uid = user["uid"]
    learner_id = PROFILES_REPO.create_learner(name=req.name, grade_level=req.grade_level, subjects=req.subjects)
    PARENTS_REPO.add_child(parent_uid, learner_id)
    prof = PROFILES_REPO.get_profile(learner_id)
    return LearnerSummary(learner_id=learner_id, name=prof.get("name", req.name), grade_level=prof.get("grade_level", req.grade_level), subjects=prof.get("subjects", req.subjects))


@router.get("/parents/learners", response_model=list[LearnerSummary])
def list_learners(request: Request):
    user = _require_user(request)
    parent_uid = user["uid"]
    children = PARENTS_REPO.list_children(parent_uid)
    out = []
    for lid in children:
        p = PROFILES_REPO.get_profile(lid)
        out.append(LearnerSummary(learner_id=lid, name=p.get("name", "Learner"), grade_level=p.get("grade_level", "P6"), subjects=p.get("subjects", ["maths"])) )
    return out

