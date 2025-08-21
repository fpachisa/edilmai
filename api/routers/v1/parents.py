from fastapi import APIRouter, Request, HTTPException
from pydantic import BaseModel
from models.schemas import CreateLearnerRequest, LearnerSummary
from services.container import PROFILES_REPO, PARENTS_REPO
from services.firestore_repository import get_firestore_repository

router = APIRouter()


class UserRegistrationRequest(BaseModel):
    email: str
    name: str
    role: str = "parent"


class UserRegistrationResponse(BaseModel):
    user_id: str
    message: str


def _require_user(request: Request) -> dict:
    user = getattr(request.state, "user", None)
    if not user or not user.get("uid"):
        raise HTTPException(status_code=401, detail="Unauthorized")
    return user


@router.post("/auth/register", response_model=UserRegistrationResponse)
async def register_user_profile(req: UserRegistrationRequest, request: Request):
    """
    Create user profile in Firestore after Firebase Auth registration
    This endpoint is called after the client successfully registers with Firebase Auth
    """
    user = _require_user(request)
    user_id = user["uid"]
    
    try:
        # Get Firestore repository
        firestore_repo = get_firestore_repository()
        
        # Create user profile in Firestore
        firestore_repo.create_user(
            user_id=user_id,
            email=req.email,
            name=req.name,
            role=req.role
        )
        
        return UserRegistrationResponse(
            user_id=user_id,
            message=f"User profile created successfully for {req.name}"
        )
        
    except Exception as e:
        print(f"🚨 REGISTER ERROR: {type(e).__name__}: {str(e)}")
        import traceback
        print(f"🚨 REGISTER TRACEBACK: {traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=f"Failed to create user profile: {str(e)}")


@router.get("/auth/profile")
def get_user_profile(request: Request):
    """Get current user's profile from Firestore"""
    user = _require_user(request)
    user_id = user["uid"]
    
    try:
        firestore_repo = get_firestore_repository()
        user_profile = firestore_repo.get_user(user_id)
        
        print(f"DEBUG: Checking profile for user {user_id}")
        print(f"DEBUG: Profile result: {user_profile}")
        
        if not user_profile:
            print(f"DEBUG: No profile found for user {user_id} - returning 404")
            raise HTTPException(status_code=404, detail="User profile not found")
            
        print(f"DEBUG: Profile found for user {user_id}")
        return user_profile.__dict__
        
    except HTTPException:
        # Re-raise HTTP exceptions (like 404)
        raise
    except Exception as e:
        print(f"DEBUG: Exception in get_user_profile: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get user profile: {str(e)}")


@router.post("/parents/learners", response_model=LearnerSummary)
async def create_learner(req: CreateLearnerRequest, request: Request):
    """Create new learner profile in Firestore"""
    user = _require_user(request)
    parent_uid = user["uid"]
    
    try:
        # Create in Firestore (production-ready persistence)
        firestore_repo = get_firestore_repository()
        learner = firestore_repo.create_learner(
            parent_id=parent_uid,
            name=req.name,
            grade_level=req.grade_level
        )
        
        # Local repo creation is handled by Firestore - no need for backward compatibility
        
        return LearnerSummary(
            learner_id=learner.learner_id,
            name=learner.name,
            grade_level=learner.grade_level,
            subjects=learner.subjects
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create learner: {str(e)}")


@router.get("/parents/learners", response_model=list[LearnerSummary])  
def list_learners(request: Request):
    """List all learners for the authenticated parent"""
    user = _require_user(request)
    parent_uid = user["uid"]
    
    try:
        # Get from Firestore (production data)
        firestore_repo = get_firestore_repository()
        learners = firestore_repo.get_learners_by_parent(parent_uid)
        
        print(f"🔍 DEBUG: Found {len(learners)} learners for parent {parent_uid}")
        
        return [
            LearnerSummary(
                learner_id=learner.learner_id,
                name=learner.name,
                grade_level=learner.grade_level,
                subjects=learner.subjects
            )
            for learner in learners
        ]
        
    except Exception as e:
        print(f"🚨 DEBUG: Learners query failed for parent {parent_uid}: {e}")
        # Return empty list instead of fallback - we want to use Firestore exclusively
        return []
