from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pathlib import Path
from fastapi.responses import JSONResponse
import os

from routers.v1 import items, session, leaderboards, profiles, home
from routers.v1 import parents, admin
from core.config import settings
from core.auth import init_firebase, verify_bearer_token
from services.container import ITEMS_REPO
import json
import asyncio
# Import with error handling to prevent startup failures
try:
    from services.firestore_repository import get_firestore_repository
    FIRESTORE_AVAILABLE = True
except Exception as e:
    print(f"⚠️ Firestore repository unavailable: {e}")
    FIRESTORE_AVAILABLE = False

app = FastAPI(title="EDIL AI Tutor API", version="0.1.0")


@app.get("/healthz")
async def healthz():
    return {"status": "ok", "env": settings.env}


@app.get("/healthz/firestore")
async def healthz_firestore():
    if not FIRESTORE_AVAILABLE:
        return {"firestore": "unavailable", "detail": "Firestore repository not loaded"}
    try:
        repo = get_firestore_repository()
        ok = await repo.health_check()
        return {"firestore": "ok" if ok else "unhealthy"}
    except Exception as e:
        return {"firestore": "error", "detail": str(e)}


@app.post("/debug/curriculum-sync-now")
async def debug_curriculum_sync():
    """TEMPORARY DEBUG ENDPOINT - Remove after subtopic fix is complete"""
    if not FIRESTORE_AVAILABLE:
        return {"error": "Firestore not available"}
    try:
        from services.curriculum_sync import sync_curriculum_to_firestore
        stats = sync_curriculum_to_firestore()
        return {
            "status": "success" if stats["errors"] == 0 else "partial_success", 
            "stats": stats,
            "message": f"Synced {stats['questions_synced']} questions with {stats['errors']} errors"
        }
    except Exception as e:
        return {"error": str(e), "status": "failed"}


def _auth_stub_enabled() -> bool:
    # In Phase 0/1, allow local/dev without strict auth; wire real checks later
    return settings.auth_stub


@app.middleware("http")
async def firebase_auth_middleware(request: Request, call_next):
    # Skip auth for OPTIONS requests (CORS preflight)
    if request.method == "OPTIONS":
        return await call_next(request)
    
    # Skip auth for health endpoints
    if request.url.path.startswith("/healthz"):
        return await call_next(request)
        
    # TEMPORARY: Skip auth for debug curriculum sync
    if request.url.path == "/debug/curriculum-sync-now":
        return await call_next(request)
    
    # Attach user to request.state.user.
    if _auth_stub_enabled():
        request.state.user = {"uid": "dev-user", "roles": ["learner"]}
        return await call_next(request)

    # Initialize Firebase admin using settings
    init_firebase(project_id=settings.firebase_project_id)
    user = verify_bearer_token(request.headers.get("Authorization"))
    if not user:
        return JSONResponse(status_code=401, content={"detail": "Unauthorized: missing/invalid ID token"})
    request.state.user = user
    return await call_next(request)


@app.get("/")
async def root():
    return {"service": "edil-api", "version": app.version, "timestamp": "2025-08-21T20:30:00Z"}


@app.get("/whoami")
async def whoami(request: Request):
    return {"user": getattr(request.state, "user", None)}

@app.get("/test-route")
async def test_route():
    return {"message": "test route works", "timestamp": "2025-08-20T21:35:00Z"}


# Mount routers (Phase 1 stubs)
app.include_router(items.router, prefix="/v1", tags=["items"])
app.include_router(session.router, prefix="/v1", tags=["session"])
app.include_router(leaderboards.router, prefix="/v1", tags=["leaderboards"])
app.include_router(profiles.router, prefix="/v1", tags=["profiles"])
app.include_router(home.router, prefix="/v1", tags=["home"])
app.include_router(parents.router, prefix="/v1", tags=["parents"])
app.include_router(admin.router, prefix="/v1", tags=["admin"])


# Enable CORS for both dev and production
if settings.env.lower() in ("dev", "development"):
    # Permissive CORS for development
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
    )
else:
    # Restricted CORS for production
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[
            "https://edilmai.web.app",
            "https://edilmai.firebaseapp.com",
        ],
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allow_headers=["*"],
    )

# Serve the lightweight demo UI under /webui for local testing
webui_dir = (Path(__file__).resolve().parents[1] / "webui")
if webui_dir.exists():
    app.mount("/webui", StaticFiles(directory=str(webui_dir), html=True), name="webui")


# Hybrid architecture: Firestore is golden copy, items loaded into memory at startup
