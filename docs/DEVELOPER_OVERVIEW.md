# EDIL AI Tutor — Developer Overview

Last updated: 2025-08-18

This document gives new contributors a fast, practical understanding of the codebase, how to run it locally, and how the main parts fit together.

## Monorepo Layout

- `api/` — FastAPI backend (Google App Engine deployable). Auth, tutoring flow, progression, repos.
- `client/` — Flutter client scaffold. Curriculum assets live in `client/assets/*.json`.
- `webui/` — Lightweight local HTML/JS demo UI to exercise the API.
- `infra/` — Firebase rules and notes for deployment/security.
- `schemas/` — JSON Schema(s) for content validation.
- `tools/` — Content generation and validation helpers (Python).
- `api/tests/` — Minimal FastAPI tests.

## Quick Start (Local)

- Python 3.12+ recommended.
- From repo root:
  - `cd api && uvicorn main:app --reload --port 8000`
  - Visit `http://localhost:8000/healthz` (expect `{status: "ok"}`)
  - Optional: open `webui/index.html` to use the demo UI against the local API.

Notes:
- Dev auth is stubbed by default (`AUTH_STUB=true`) so endpoints work without Firebase.
- In dev, the API will auto-ingest items found in `client/assets/*.json` on startup (see `main.py`).

## Environment and Settings

- Settings live in `api/core/config.py` (Pydantic Settings via `.env`). Important keys:
  - `ENV`/`env`: environment name (default `dev`)
  - `AUTH_STUB`/`auth_stub`: when true, bypasses Firebase checks and grants a dummy user
  - `LLM_PROVIDER`/`llm_provider`: typically `gemini`
  - `LLM_MODEL`/`llm_model`: e.g., `gemini-2.5-flash-lite`
  - `GOOGLE_API_KEY` or `VERTEX_PROJECT_ID`/`VERTEX_LOCATION` for LLM
- Production auth requires `FIREBASE_PROJECT_ID` and `GOOGLE_APPLICATION_CREDENTIALS` for Firebase Admin.

## Backend Entry Point

- `api/main.py`
  - FastAPI app creation and middleware
  - Firebase auth middleware:
    - Dev: attaches `{uid: "dev-user", roles: ["learner"]}`
    - Prod: verifies `Authorization: Bearer <ID_TOKEN>` via Firebase Admin
  - Routers mounted under `/v1` (see below)
  - CORS enabled in dev
  - Serves `webui/` under `/webui` if present
  - Dev auto-ingest of curriculum items from `client/assets/*.json`

## Routers and Endpoints (v1)

- Items (`api/routers/v1/items.py`)
  - `POST /v1/items/ingest` — ingest Enhanced Item JSON (role-gated in prod)
  - `GET /v1/items/{item_id}` — fetch an item by ID
- Session (`api/routers/v1/session.py`)
  - `POST /v1/session/start` — start a session for an item
  - `GET /v1/session/{session_id}` — resume (returns current prompt)
  - `POST /v1/session/step` — submit an answer; AI evaluates, returns result/hint
  - `POST /v1/session/start-adaptive` — adaptive start from topic/legacy id
  - `POST /v1/session/continue-progression` — continue to next item in topic
  - `POST /v1/session/end` — end a session (no-op in-memory)
- Home (`api/routers/v1/home.py`)
  - `GET /v1/homefeed/{learner_id}` — assemble home feed cards
  - `GET /v1/catalog/topics` — list topics
  - `GET /v1/catalog/collections` — list collections
- Profiles (`api/routers/v1/profiles.py`)
  - `GET /v1/profile/{learner_id}` — get profile (in-memory, hydrated defaults)
- Parents (`api/routers/v1/parents.py`)
  - `POST /v1/parents/learners` — create learner attached to parent (auth required in prod)
  - `GET /v1/parents/learners` — list learners for parent
- Leaderboards (`api/routers/v1/leaderboards.py`)
  - `GET /v1/leaderboard/{scope}` — placeholder response

## Data Repositories

- Development (default): in-memory repositories (`api/services/repositories.py`)
  - Items: store/fetch items by ID; enumerate all for progression
  - Sessions: create sessions, track conversation history, attempts, misconceptions, insights
  - Profiles: track XP, completed items, and current session
  - Parents: map parent → children
- Production (optional): Firestore-backed (`api/services/container.py` + `api/services/firestore_repository.py`)
  - Auto-selected when `AUTH_STUB=false` and GCP/Firebase env is configured
  - Flat collections: `users`, `learners`, `sessions`, and `curriculum/<subject>/items`
  - Some session update methods are placeholders (append step, atomic increments) and are to-be-implemented

## Content Model and Validation

- Enhanced Item Schema: `schemas/enhanced_item_v1.schema.json`
- Validation CLI: `python api/tools/validate_items.py path/to/enhanced_items.json`
- Sample/demo item also in `webui/script.js` for quick ingest
- Dev auto-ingest normalizes older formats found in `client/assets/*.json`

## Tutoring Orchestration (AI-First)

- `api/services/orchestrator.py`
  - `SimpleOrchestrator.evaluate_simplified(...)` uses the LLM exclusively to:
    - Judge correctness, decide whether to advance
    - Produce feedback used as either `next_prompt` (correct) or `hint` (incorrect)
    - Emit learning insights and misconception tags (simplified)
  - On correct: marks session finished, awards XP, suggests next item via `ProgressionService`
  - On AI failure: returns `correctness=NULL` with a transparent retry message
- LLM integration: `api/services/llm.py`
  - `GeminiLLM` via Google AI Studio (`GOOGLE_API_KEY`) or Vertex AI
  - `build_llm()` respects `settings.enable_llm`, `llm_provider`, `llm_model`

## Progression Service

- `api/services/progression.py`
  - Auto-discovers items by topic using repo inventory, derives ordering from:
    - `sub_topic` (when present), question number in ID, and difficulty
  - `recommend_next_session(profile, topic)` returns the next item in that topic
  - Topic detection helpers for item IDs and topics listing

## Auth and Security

- Dev mode: `AUTH_STUB=true`, no token verification, role checks are bypassed
- Prod mode: Firebase Admin verifies ID tokens and attaches `request.state.user`
- Role checks: `api/core/security.py` → `require_roles(request, roles)`
  - Example: `/v1/items/ingest` requires `author` or `admin` when not stubbed
- Firebase Security Rules: `infra/firebase/firestore.rules` & `storage.rules`

## Tests

- Run: `pytest -q` (from repo root or `api/`)
- Tests:
  - `test_health.py` — health endpoint
  - `test_session_flow.py` — ingest sample → start session → submit correct response

## Client Assets and Topics

- Curriculum assets: `client/assets/algebra.json`, `fractions.json` (auto-ingested in dev)
- Topic mapping: `client/assets/p6_maths_topics.json` used by session router to map legacy IDs to subjects

## Known Gaps / Observations

- Demo UI expects `first_prompt` but API returns `prompt` in session start response (minor mismatch for webui).
- Firestore repos: some session update behaviors (append step, atomic attempt increments, array unions) are placeholders.
- LLM must be configured; if credentials are absent and `enable_llm=true`, AI evaluation will fail (the orchestrator reports a friendly retry message). Consider disabling `enable_llm` for purely offline flows.
- `AUTH_STUB` governs both auth bypass and Firestore selection (via `container.init_repositories()`); ensure prod deploys set it to `false`.

## Deployment (API)

- GAE: `gcloud app deploy api/app.yaml --project <PROJECT_ID>`
- Ensure prod env vars are set (Firebase/Vertex) and `AUTH_STUB=false`.

## Handy Commands

- Start API: `cd api && uvicorn main:app --reload --port 8000`
- Validate content: `python api/tools/validate_items.py file.json`
- Run tests: `pytest -q`

---

For deeper context, see also:
- `README.md` (root and `api/README.md`) for quick instructions
- `api/services/*` for orchestration, repos, progression
- `api/models/*` for pydantic and Firestore models
