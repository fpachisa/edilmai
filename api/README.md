# EDIL AI Tutor API (FastAPI)

Minimal FastAPI skeleton for Phase 0. Deployed on Google App Engine (Standard).

## Local dev

1. Create a venv and install deps:

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r api/requirements.txt
```

2. Run the server:

```bash
cd api
export AUTH_STUB=true
uvicorn main:app --reload --port 8000
```

3. Check health:

```bash
curl http://localhost:8000/healthz

## API v1 stubs

- `POST /v1/items/ingest` — ingest Enhanced Item JSON (in-memory for dev).
- `GET /v1/items/{id}` — fetch an item (in-memory for dev).
- `POST /v1/session/start` — start a session and get first prompt.
- `POST /v1/session/step` — evaluate a step via simple orchestrator (regex/CAS fallback to hint).
- `POST /v1/session/end` — end a session (in-memory).
- `GET /v1/profile/{learner_id}` — get a placeholder profile (in-memory).
- `GET /v1/leaderboard/{scope}` — placeholder leaderboard response.

## Try it with curl

1) Ingest a sample item:

```bash
curl -X POST http://localhost:8000/v1/items/ingest \
  -H 'Content-Type: application/json' \
  --data @api/samples/enhanced_items.sample.json
```

2) Start a session:

```bash
curl -X POST http://localhost:8000/v1/session/start \
  -H 'Content-Type: application/json' \
  -d '{"learner_id":"demo","item_id":"ALG-S1-E1"}'
```

3) Answer the first step:

```bash
curl -X POST http://localhost:8000/v1/session/step \
  -H 'Content-Type: application/json' \
  -d '{"session_id":"<SID_FROM_START>","step_id":"s1","user_response":"b+4"}'
```

## Validation CLI

Validate an Enhanced Item JSON file against the schema:

```bash
python api/tools/validate_items.py path/to/enhanced_items.json
```

Schema file: `schemas/enhanced_item_v1.schema.json`.

## Tests

Run unit tests (pytest):

```bash
pytest -q
```
```

## Deploy (GAE)

Deploy the `api/` directory which contains `app.yaml`:

```bash
gcloud app deploy api/app.yaml --project <PROJECT_ID>
```

## Env vars

- `AUTH_STUB` (default: `true`) — bypass strict auth for dev. In staging/prod set to `false` and enable Firebase token verification.
- `FIREBASE_PROJECT_ID` and/or `GOOGLE_CLOUD_PROJECT` — used when initializing Firebase Admin.
- `GOOGLE_APPLICATION_CREDENTIALS` — path to a service account JSON file for Firebase Admin.

## Firebase Auth (API verification)

To require Firebase ID tokens on requests:

1. Create a Firebase service account in the Firebase Console (Project Settings → Service Accounts) and download the JSON key.
2. Set env vars and start the API with auth stub disabled:

```bash
export AUTH_STUB=false
export FIREBASE_PROJECT_ID=<your-firebase-project-id>
export GOOGLE_APPLICATION_CREDENTIALS=/absolute/path/to/service-account.json
uvicorn main:app --reload --port 8000
```

3. From a Firebase-authenticated client (Flutter/web), send requests with `Authorization: Bearer <ID_TOKEN>` header. The middleware will verify the token and attach `request.state.user`.

### Granting roles to users

Use custom claims to grant roles like `author` or `admin`:

```bash
# Requires GOOGLE_APPLICATION_CREDENTIALS and (optionally) FIREBASE_PROJECT_ID
python api/tools/grant_role.py --project $FIREBASE_PROJECT_ID --role author --uid <USER_UID>
# or by email
python api/tools/grant_role.py --project $FIREBASE_PROJECT_ID --role author --email someone@example.com
```

With `AUTH_STUB=false`, the endpoint `POST /v1/items/ingest` requires role `author` or `admin`.
