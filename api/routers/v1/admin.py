"""
Admin endpoints for curriculum management
Provides secure endpoints for syncing curriculum and managing content
"""

from fastapi import APIRouter, HTTPException, Request
from typing import Dict, Any
import logging

from services.curriculum_sync import sync_curriculum_to_firestore
from core.config import settings
from models.curriculum_models import COLLECTIONS
from services.firestore_repository import get_firestore_repository

logger = logging.getLogger(__name__)

router = APIRouter()


def _check_admin(request: Request):
    """Require admin access in production: either admin role or valid admin API key header."""
    # Allow freely in dev/stub environments
    if settings.auth_stub or settings.env.lower() in ("dev", "development"):
        return
    # Bootstrap allowance: if no curriculum exists yet, allow first sync
    try:
        repo = get_firestore_repository()
        any_question = next(iter(repo.db.collection(COLLECTIONS["curriculum_questions"]).limit(1).get()), None)
        if any_question is None:
            return
    except Exception:
        pass
    # Header-based key for production
    admin_key = request.headers.get("x-admin-key") or request.headers.get("X-Admin-Key")
    if settings.admin_api_key and admin_key == settings.admin_api_key:
        return
    # If Firebase auth is enabled and user roles attached, allow 'admin'
    user = getattr(request.state, "user", None)
    roles = (user or {}).get("roles", []) if isinstance(user, dict) else []
    if roles and ("admin" in roles or "author" in roles):
        return
    raise HTTPException(status_code=403, detail="Admin access required")


@router.post("/admin/curriculum/sync")
def sync_curriculum(request: Request):
    _check_admin(request)
    """
    Sync curriculum from JSON files to Firestore
    This should be called after updating curriculum JSON files
    
    Returns sync statistics
    """
    try:
        logger.info("Starting curriculum sync via admin endpoint")
        stats = sync_curriculum_to_firestore()
        
        if stats["errors"] > 0:
            logger.warning(f"Curriculum sync completed with errors: {stats}")
            return {
                "status": "partial_success", 
                "message": f"Synced with {stats['errors']} errors",
                "stats": stats
            }
        else:
            logger.info(f"Curriculum sync completed successfully: {stats}")
            return {
                "status": "success",
                "message": f"Successfully synced {stats['questions_synced']} questions and {stats['progressions_synced']} progressions",
                "stats": stats
            }
            
    except Exception as e:
        logger.error(f"Curriculum sync failed: {e}")
        raise HTTPException(
            status_code=500, 
            detail=f"Curriculum sync failed: {str(e)}"
        )


@router.get("/admin/curriculum/status")
def get_curriculum_status(request: Request):
    _check_admin(request)
    """
    Get curriculum sync status and metadata
    """
    try:
        from services.firestore_repository import get_firestore_repository
        from models.curriculum_models import COLLECTIONS
        
        firestore_repo = get_firestore_repository()
        
        # Get sync metadata
        metadata_collection = firestore_repo.db.collection(COLLECTIONS["curriculum_metadata"])
        metadata_doc = metadata_collection.document("sync_history").get()
        
        sync_info = metadata_doc.to_dict() if metadata_doc.exists else {}
        
        # Get collection counts
        questions_count = len(list(firestore_repo.db.collection(COLLECTIONS["curriculum_questions"]).get()))
        progressions_count = len(list(firestore_repo.db.collection(COLLECTIONS["topic_progressions"]).get()))
        
        return {
            "questions_in_database": questions_count,
            "progressions_in_database": progressions_count,
            "last_sync": sync_info.get("last_sync", "Never"),
            "last_sync_stats": {
                "questions_synced": sync_info.get("questions_synced", 0),
                "progressions_synced": sync_info.get("progressions_synced", 0),
                "errors": sync_info.get("errors", 0),
                "status": sync_info.get("status", "unknown")
            }
        }
        
    except Exception as e:
        logger.error(f"Error getting curriculum status: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get curriculum status: {str(e)}"
        )
