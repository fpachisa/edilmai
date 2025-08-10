from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pathlib import Path
from fastapi.responses import JSONResponse
import os

from routers.v1 import items, session, leaderboards, profiles
from core.config import settings
from core.auth import init_firebase, verify_bearer_token

app = FastAPI(title="EDIL AI Tutor API", version="0.1.0")


@app.get("/healthz")
async def healthz():
    return {"status": "ok", "env": settings.env}


def _auth_stub_enabled() -> bool:
    # In Phase 0/1, allow local/dev without strict auth; wire real checks later
    return settings.auth_stub


@app.middleware("http")
async def firebase_auth_middleware(request: Request, call_next):
    # Attach user to request.state.user.
    if _auth_stub_enabled():
        request.state.user = {"uid": "dev-user", "roles": ["learner"]}
        return await call_next(request)

    # Initialize Firebase admin (expects GOOGLE_APPLICATION_CREDENTIALS or default env)
    init_firebase(project_id=os.getenv("FIREBASE_PROJECT_ID") or os.getenv("GOOGLE_CLOUD_PROJECT"))
    user = verify_bearer_token(request.headers.get("Authorization"))
    if not user:
        return JSONResponse(status_code=401, content={"detail": "Unauthorized: missing/invalid ID token"})
    request.state.user = user
    return await call_next(request)


@app.get("/")
async def root():
    return {"service": "edil-api", "version": app.version}


@app.get("/whoami")
async def whoami(request: Request):
    return {"user": getattr(request.state, "user", None)}


# Mount routers (Phase 1 stubs)
app.include_router(items.router, prefix="/v1", tags=["items"])
app.include_router(session.router, prefix="/v1", tags=["session"])
app.include_router(leaderboards.router, prefix="/v1", tags=["leaderboards"])
app.include_router(profiles.router, prefix="/v1", tags=["profiles"])


# Enable permissive CORS in dev to allow local web UI testing
if settings.env.lower() in ("dev", "development"):
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
    )

# Serve the lightweight demo UI under /webui for local testing
webui_dir = (Path(__file__).resolve().parents[1] / "webui")
if webui_dir.exists():
    app.mount("/webui", StaticFiles(directory=str(webui_dir), html=True), name="webui")
