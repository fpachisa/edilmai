"""
Production Firebase Authentication for PSLE AI Tutor
Handles user authentication, role management, and custom claims
"""

from __future__ import annotations
from typing import Optional, Dict, Any, List
import firebase_admin
from firebase_admin import auth as fb_auth, credentials
import logging
from datetime import datetime, timezone

logger = logging.getLogger(__name__)

_firebase_initialized = False


def init_firebase(project_id: Optional[str] = None) -> None:
    """Initialize Firebase Admin SDK with proper error handling"""
    global _firebase_initialized
    if _firebase_initialized:
        return
        
    try:
        # Check if already initialized
        if firebase_admin._apps:
            _firebase_initialized = True
            return
            
        # Prefer Application Default Credentials via GOOGLE_APPLICATION_CREDENTIALS
        cred = credentials.ApplicationDefault()
        options = {"projectId": project_id} if project_id else None
        firebase_admin.initialize_app(cred, options)
        _firebase_initialized = True
        logger.info(f"Firebase Admin initialized for project: {project_id}")
        
    except Exception as e:
        logger.error(f"Firebase initialization failed: {e}")
        # As a fallback, try default initialization
        try:
            if not firebase_admin._apps:
                firebase_admin.initialize_app()
            _firebase_initialized = True
            logger.info("Firebase Admin initialized with default credentials")
        except Exception as e2:
            logger.error(f"Firebase default initialization failed: {e2}")
            raise


def verify_bearer_token(auth_header: Optional[str]) -> Optional[Dict[str, Any]]:
    """
    Verify Firebase ID token and extract user info with roles
    Returns user data with uid, roles, and full claims
    """
    if not auth_header or not auth_header.startswith("Bearer "):
        return None
        
    token = auth_header.split(" ", 1)[1].strip()
    
    try:
        # Verify the ID token
        decoded = fb_auth.verify_id_token(token, check_revoked=True)
        
        uid = decoded.get("uid")
        email = decoded.get("email", "")
        name = decoded.get("name", "")
        
        # Extract role from custom claims (set by admin)
        role = decoded.get("role", "parent")  # Default to parent role
        
        # Support legacy 'roles' array format
        roles = decoded.get("roles")
        if roles and isinstance(roles, list):
            role = roles[0] if roles else "parent"
        elif isinstance(role, list):
            role = role[0] if role else "parent"
            
        # Extract additional custom claims
        custom_claims = {
            k: v for k, v in decoded.items() 
            if k not in ['iss', 'aud', 'auth_time', 'user_id', 'sub', 'iat', 'exp', 'firebase']
        }
        
        return {
            "uid": uid,
            "email": email,
            "name": name,
            "role": role,
            "roles": [role],  # For backward compatibility
            "custom_claims": custom_claims,
            "claims": decoded,
            "auth_time": decoded.get("auth_time"),
            "verified_at": datetime.now(timezone.utc).isoformat()
        }
        
    except fb_auth.ExpiredIdTokenError:
        logger.warning(f"Expired ID token")
        return None
    except fb_auth.RevokedIdTokenError:
        logger.warning(f"Revoked ID token")
        return None
    except fb_auth.InvalidIdTokenError as e:
        logger.warning(f"Invalid ID token: {e}")
        return None
    except Exception as e:
        logger.error(f"Token verification failed: {e}")
        return None


async def set_user_role(uid: str, role: str, additional_claims: Optional[Dict[str, Any]] = None) -> bool:
    """
    Set custom claims for a user (role and additional metadata)
    Roles: 'parent', 'teacher', 'admin', 'author', 'service'
    """
    try:
        claims = {"role": role}
        if additional_claims:
            claims.update(additional_claims)
            
        # Add timestamp for claim tracking
        claims["role_set_at"] = datetime.now(timezone.utc).isoformat()
        
        fb_auth.set_custom_user_claims(uid, claims)
        logger.info(f"Set role '{role}' for user {uid}")
        return True
        
    except Exception as e:
        logger.error(f"Failed to set role for user {uid}: {e}")
        return False


async def get_user_info(uid: str) -> Optional[Dict[str, Any]]:
    """Get complete user information from Firebase Auth"""
    try:
        user_record = fb_auth.get_user(uid)
        return {
            "uid": user_record.uid,
            "email": user_record.email,
            "email_verified": user_record.email_verified,
            "display_name": user_record.display_name,
            "photo_url": user_record.photo_url,
            "disabled": user_record.disabled,
            "custom_claims": user_record.custom_claims or {},
            "creation_time": user_record.user_metadata.creation_timestamp,
            "last_sign_in": user_record.user_metadata.last_sign_in_timestamp,
            "provider_data": [
                {
                    "uid": provider.uid,
                    "email": provider.email,
                    "provider_id": provider.provider_id,
                    "display_name": provider.display_name,
                    "photo_url": provider.photo_url
                }
                for provider in user_record.provider_data
            ]
        }
    except Exception as e:
        logger.error(f"Failed to get user info for {uid}: {e}")
        return None


async def create_user_with_role(email: str, password: str, display_name: str, 
                                role: str = "parent") -> Optional[str]:
    """
    Create new user with specified role
    Used for admin-created accounts (teachers, etc.)
    """
    try:
        user_record = fb_auth.create_user(
            email=email,
            password=password,
            display_name=display_name,
            email_verified=False
        )
        
        # Set role immediately
        await set_user_role(user_record.uid, role)
        
        logger.info(f"Created user {user_record.uid} with role {role}")
        return user_record.uid
        
    except Exception as e:
        logger.error(f"Failed to create user {email}: {e}")
        return None


async def disable_user(uid: str, reason: str = "Account disabled") -> bool:
    """Disable user account with logging"""
    try:
        fb_auth.update_user(uid, disabled=True)
        
        # Add disabled reason to custom claims
        current_user = await get_user_info(uid)
        if current_user:
            claims = current_user.get("custom_claims", {})
            claims.update({
                "disabled_at": datetime.now(timezone.utc).isoformat(),
                "disabled_reason": reason
            })
            fb_auth.set_custom_user_claims(uid, claims)
        
        logger.info(f"Disabled user {uid}: {reason}")
        return True
        
    except Exception as e:
        logger.error(f"Failed to disable user {uid}: {e}")
        return False


async def list_users_by_role(role: str, limit: int = 100) -> List[Dict[str, Any]]:
    """
    List users with specific role
    Note: This requires iterating through all users as Firebase doesn't support custom claim queries
    Use sparingly and with pagination for large user bases
    """
    try:
        users_with_role = []
        page = fb_auth.list_users(max_results=limit)
        
        for user in page.users:
            custom_claims = user.custom_claims or {}
            if custom_claims.get("role") == role:
                users_with_role.append({
                    "uid": user.uid,
                    "email": user.email,
                    "display_name": user.display_name,
                    "disabled": user.disabled,
                    "custom_claims": custom_claims,
                    "last_sign_in": user.user_metadata.last_sign_in_timestamp
                })
        
        return users_with_role
        
    except Exception as e:
        logger.error(f"Failed to list users with role {role}: {e}")
        return []


def require_role(required_role: str):
    """
    Decorator to require specific role for API endpoints
    Usage: @require_role('admin')
    """
    def decorator(func):
        def wrapper(*args, **kwargs):
            # This would be used with FastAPI dependency injection
            # Implementation depends on your API structure
            pass
        return wrapper
    return decorator


# Service account operations
async def create_service_token() -> Optional[str]:
    """
    Create a service account token for API-to-API communication
    This would typically use a service account key
    """
    try:
        # This is a placeholder - implement based on your service account setup
        # You would typically use the Firebase Admin SDK to create custom tokens
        # for service-to-service communication
        pass
    except Exception as e:
        logger.error(f"Failed to create service token: {e}")
        return None


# Health check for authentication system
async def auth_health_check() -> Dict[str, Any]:
    """Check Firebase Auth connectivity and basic functionality"""
    try:
        # Try to list one user to verify connectivity
        page = fb_auth.list_users(max_results=1)
        
        return {
            "status": "healthy",
            "firebase_initialized": _firebase_initialized,
            "can_list_users": True,
            "timestamp": datetime.now(timezone.utc).isoformat()
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "error": str(e),
            "firebase_initialized": _firebase_initialized,
            "timestamp": datetime.now(timezone.utc).isoformat()
        }

