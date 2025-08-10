from __future__ import annotations
from typing import Optional, Dict, Any
import firebase_admin
from firebase_admin import auth as fb_auth, credentials


_firebase_initialized = False


def init_firebase(project_id: Optional[str] = None) -> None:
    global _firebase_initialized
    if _firebase_initialized:
        return
    try:
        # Prefer Application Default Credentials via GOOGLE_APPLICATION_CREDENTIALS
        cred = credentials.ApplicationDefault()
        options = {"projectId": project_id} if project_id else None
        firebase_admin.initialize_app(cred, options)
        _firebase_initialized = True
    except Exception:
        # As a fallback, try default initialization (works if already initialized elsewhere)
        if not firebase_admin._apps:
            firebase_admin.initialize_app()
        _firebase_initialized = True


def verify_bearer_token(auth_header: Optional[str]) -> Optional[Dict[str, Any]]:
    if not auth_header or not auth_header.startswith("Bearer "):
        return None
    token = auth_header.split(" ", 1)[1].strip()
    try:
        decoded = fb_auth.verify_id_token(token)
        uid = decoded.get("uid")
        # Support either 'role' (string) or 'roles' (list)
        roles = decoded.get("roles") or decoded.get("role")
        if isinstance(roles, str):
            roles = [roles]
        return {"uid": uid, "roles": roles or [] , "claims": decoded}
    except Exception:
        return None

