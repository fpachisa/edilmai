from __future__ import annotations
from typing import Any, Dict, Iterable
from fastapi import Request, HTTPException
from api.core.config import settings


def user_has_any_role(user: Dict[str, Any] | None, roles: Iterable[str]) -> bool:
    if not user:
        return False
    user_roles = set((user.get("roles") or []))
    return any(r in user_roles for r in roles)


def require_roles(request: Request, roles: Iterable[str]) -> None:
    # In demo mode, allow all to keep flows simple
    if settings.auth_stub:
        return
    user = getattr(request.state, "user", None)
    if not user_has_any_role(user, roles):
        raise HTTPException(status_code=403, detail="Forbidden: insufficient role")

