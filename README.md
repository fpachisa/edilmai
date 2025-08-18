# EDIL AI Tutor — Monorepo

This repository contains the API (FastAPI on GAE), Flutter client, and infra configs for the PSLE AI Tutor MVP.

## Structure

- `api/` — FastAPI service with `app.yaml` for App Engine.
- `client/` — Flutter client (create with `flutter create .` inside this folder).
- `infra/` — Firebase rules and related infra artifacts.
- `.github/workflows/` — CI pipelines for API and client.
- `webui/` — Lightweight local web UI to exercise the API.

## Developer Docs

- Developer overview and handover guide: `docs/DEVELOPER_OVERVIEW.md`

## Phase 0 Checklist

- API skeleton with `/healthz` — done.
- GAE config (`api/app.yaml`) — done.
- CI workflows for API and client — done.
- Firebase rules (draft) — done.
- Client scaffold instructions — done.

## Next Steps (Phase 1)

- Implement Firebase token verification middleware in API.
- Define Enhanced Item JSON schema and validator.
- Scaffold v1 endpoints: session start/step/end, items ingest/get.
- Add initial algebra content and preview tool.

## Quick Demo UI (no Flutter required)

- Start the API: `cd api && uvicorn main:app --reload --port 8000`
- Open `webui/index.html` in your browser (double-click or open with a local server)
- Click "Ingest Sample Items" → "Start Session" → submit an answer (try `b+4`)

Notes:
- CORS is enabled in `dev` env, so browser calls are allowed from local files.
- Use the API URL box to point to a different host/port if needed.
