from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pathlib import Path
from fastapi.responses import JSONResponse
import os

from api.routers.v1 import items, session, leaderboards, profiles, home
from api.routers.v1 import parents
from api.core.config import settings
from api.core.auth import init_firebase, verify_bearer_token
from api.services.container import ITEMS_REPO
import json

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
app.include_router(home.router, prefix="/v1", tags=["home"])
app.include_router(parents.router, prefix="/v1", tags=["parents"])


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


# Development-only: auto-ingest curriculum items from local assets on startup
def _find_assets_dir() -> Path | None:
    """Search upwards from this file for a repo root that contains client/assets.

    Handles nested repo layouts like edilmai/edilmai by walking up a few levels.
    """
    here = Path(__file__).resolve()
    for ancestor in [here.parent, *here.parents]:
        candidate = ancestor.parent / "client" / "assets"
        if candidate.exists() and candidate.is_dir():
            return candidate
        candidate2 = ancestor / "client" / "assets"
        if candidate2.exists() and candidate2.is_dir():
            return candidate2
    return None


def _dev_auto_ingest_from_assets():
    try:
        if settings.env.lower() not in ("dev", "development"):
            return
        assets_dir = _find_assets_dir()
        if not assets_dir:
            print("ℹ️ Dev auto-ingest: client/assets not found")
            return
        print(f"ℹ️ Dev auto-ingest scanning: {assets_dir}")
        for path in assets_dir.glob("*.json"):
            print(f"📄 Processing file: {path.name}")
            try:
                data = json.loads(path.read_text())
            except Exception as e:
                print(f"❌ Failed to parse {path.name}: {e}")
                continue
            # Support both old "items" and new "questions" format
            items = data.get("questions") or data.get("items")
            if not isinstance(items, list):
                print(f"⚠️ No 'questions' or 'items' list found in {path.name}")
                continue
            print(f"📦 Found {len(items)} items in {path.name}")
            for item in items:
                if not isinstance(item, dict):
                    continue
                item_id = item.get("id")
                if not item_id:
                    print(f"⚠️ Item missing 'id' field, skipping")
                    continue
                # Skip if already present
                if ITEMS_REPO.get_item(item_id):
                    print(f"⏭️ Item {item_id} already exists, skipping")
                    continue
                print(f"➕ Adding new item: {item_id}")
                # Normalize minimal fields for backend consumption
                sv = item.get("student_view") or {}
                steps = sv.get("steps") or sv.get("socratic_steps") or []
                norm_steps = []
                if isinstance(steps, list):
                    for idx, s in enumerate(steps):
                        if isinstance(s, dict):
                            hints = s.get("hints", [])
                            # Normalize hints to list of {level, text}
                            norm_hints = []
                            if isinstance(hints, dict):
                                for k, v in hints.items():
                                    try:
                                        level = int(str(k).lstrip("L"))
                                    except Exception:
                                        level = len(norm_hints) + 1
                                    norm_hints.append({"level": level, "text": str(v)})
                            elif isinstance(hints, list):
                                for i, v in enumerate(hints, start=1):
                                    # Accept dicts with text or raw strings
                                    if isinstance(v, dict):
                                        txt = v.get("text") or v.get("hint") or ""
                                        lvl = int(v.get("level")) if str(v.get("level" or "")).isdigit() else i
                                        norm_hints.append({"level": lvl, "text": str(txt)})
                                    else:
                                        norm_hints.append({"level": i, "text": str(v)})
                            else:
                                norm_hints = []
                            ns = dict(s)
                            ns["hints"] = norm_hints
                            ns["id"] = str(ns.get("id") or f"s{idx+1}")
                            ns["prompt"] = str(ns.get("prompt") or "")
                            norm_steps.append(ns)
                        else:
                            # s is a string prompt from socratic_steps
                            norm_steps.append({"id": f"s{idx+1}", "prompt": str(s), "hints": []})
                # Write back normalized student_view
                item["student_view"] = {"socratic": True, "steps": norm_steps, "reflect_prompts": [], "micro_drills": []}
                # Ensure evaluation exists
                if not item.get("evaluation"):
                    item["evaluation"] = {"rules": {"regex": [], "algebraic_equivalence": True, "llm_fallback": True}, "notes": None}
                # Put item into repo
                ITEMS_REPO.put_item(item)
                print(f"✅ Successfully added item: {item_id}")
        print("💾 Dev auto-ingest completed from client/assets")
    except Exception as e:
        print(f"⚠️ Dev auto-ingest failed: {e}")


# Trigger dev auto-ingest at import time (FastAPI startup)
_dev_auto_ingest_from_assets()
