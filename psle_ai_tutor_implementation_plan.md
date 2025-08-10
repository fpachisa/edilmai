 # PSLE AI Tutor — Implementation Plan (MVP)

 > Scope: End-to-end plan to implement the PSLE P6 Maths Socratic tutor MVP across iOS/Android/Web using Flutter + FastAPI on GAE + Firebase.
 > Source: Derived from engineering architecture/build plan; this document focuses on actionable execution.

 ---

 ## 1. Execution Phases

 - Phase 0 — Foundations (Weeks 1–2): repos, environments, CI, auth, skeletons.
 - Phase 1 — Tutoring Core (Weeks 3–6): items pipeline, API, orchestrator, client state machine.
 - Phase 2 — Gamification & Dashboards (Weeks 7–9): XP/badges/leaderboards, parent/teacher views, analytics.
 - Phase 3 — Polish & Hardening (Weeks 10–11): performance, accessibility, A/B hooks, previews, load tests.
 - Phase 4 — Launch (Week 12): content QA, canary rollout, acceptance validation, post‑launch dashboards.

 ---

 ## 2. Repo & Project Setup

 - Repos: `client-flutter`, `api-fastapi`, `infra` (deployment configs, Firebase rules, workflows).
 - Branching: trunk‑based with short‑lived feature branches; protected `main`.
 - Environments: Firebase projects `dev`, `staging`, `prod`; corresponding GCP resources in `asia-southeast1`.
 - Standards: formatters/linters (Flutter `flutter_lints`; Python `ruff` + `black`), pre‑commit hooks, conventional commits.

 ---

 ## 3. Infrastructure & Environments

 - App Engine (Python 3.12): `app.yaml` per env; autoscaling with `min_idle_instances: 1`, `max_instances: 10`.
 - Firebase: Auth (Email/Google/Apple), Firestore, Storage, Functions, Remote Config, App Check, Analytics.
 - Networking: restrict egress to LLM endpoints; enable Secret Manager for LLM keys and service creds.
 - Observability: Cloud Logging, Error Reporting, Cloud Trace; optional Sentry in client/API.

 ---

 ## 4. Data & Content Pipeline

 - Enhanced Item JSON: finalize `enhanced-v1` schema; author a JSON Schema.
 - Validation: Python `pydantic` models + `jsonschema`; CLI for local validate.
 - Ingestion API: `POST /v1/items/ingest` stores item in `items/` with `versions/` pointer.
 - Preview API: `GET /v1/items/:id` for author/teacher previews; gated by roles.
 - Seed Content: convert `algebra.json` to `enhanced-v1`; seed 30–50 Algebra items.

 ---

 ## 5. Backend (FastAPI on GAE)

 - Structure: `api/main.py` (FastAPI app), `routers/v1`, `models` (pydantic), `services` (orchestrator, mastery, gamification), `adapters` (LLM, Firestore).
 - Auth: Firebase ID token verification middleware; roles via custom claims (`learner`, `parent`, `teacher`, `author`, `admin`).
 - Firestore: typed DTOs for collections `users/`, `learners/`, `items/`, `sessions/`, `events/`, `leaderboards/`, `badges/`.
 - Endpoints (v1):
   - `POST /v1/session/start` → create session, return first prompt payload.
   - `POST /v1/session/step` → evaluate response, hint/advance, emit telemetry.
   - `POST /v1/session/end` → finalize session, update mastery, XP, badges.
   - `GET /v1/items/:id`, `POST /v1/items/ingest`.
   - `GET /v1/leaderboard/:scope`, `GET /v1/profile/:learner_id`.
 - Jobs: Cloud Scheduler → Functions for leaderboards recompute, Firestore→BigQuery exports, A/B rotations.
 - Contracts: OpenAPI spec generated; publish client SDK.

 ---

 ## 6. LLM Orchestrator

 - Provider‑agnostic interface `LLMClient` with implementations for OpenAI and Vertex AI; selected via `LLM_PROVIDER`.
 - Prompts:
   - System: patient Socratic tutor for P6 Maths; no final answers; short, one question at a time.
   - Judge rubric: check equivalence, units, misconception category, recommend hint level (L1–L3).
 - Evaluation pipeline:
   1) Regex/normalization (trim, canonical forms, numeric tolerance).
   2) CAS via Sympy for algebraic equivalence (timeouts + fallbacks).
   3) LLM judge as fallback (no answer leakage; capture rationale).
 - State machine: decide advance/hint/probe; tag misconceptions; enforce hint throttles and per‑session token budgets.
 - Safety: profanity/PII filters, temperature constraints, refusal templates; App Check validations.

 ---

 ## 7. Mastery & Gamification Services

 - Mastery: ELO/IRT hybrid per subskill θ; update with penalties for hints; spaced repetition resurfacing within 24–72h.
 - XP: per correct step; bonus for no‑hint solves; streak logic with grace day.
 - Badges: definitions in `badges/` with server‑side awarding on session end.
 - Leaderboards: weekly aggregates (cohort/school/national) computed by job; anti‑cheat via server validation + App Check.

 ---

 ## 8. Client App (Flutter)

 - Foundations: Riverpod for state; Material 3 theme; Rive/Lottie; HTTP via `dio`.
 - Auth: Firebase Auth SDK; token refresh; custom claims; App Check.
 - Tutoring UI: split chat + working canvas (bar models, number lines); math input with LaTeX (`flutter_math_fork`).
 - Session logic: Riverpod state machine aligned with backend; optimistic UI where safe; offline‑tolerant rendering state.
 - Items rendering: steps with hints L1–L3, reflect prompts, micro‑drills placeholder.
 - Dashboards: parent/teacher summaries (progress, mastery vector, time‑on‑task) with `fl_chart`.
 - Gamification UI: XP bar, badges gallery, streak indicator, weekly leaderboard.
 - Accessibility: scale fonts, high‑contrast theme, haptics, reduced motion.

 ---

 ## 9. Security & Privacy

 - Firestore Security Rules + custom claims for role‑based access; row‑level filtering for parent/teacher visibility.
 - PII minimization; region `asia-southeast1` for data; consent flags and audit logs.
 - Retention: raw `events/` kept 1 year → aggregated thereafter.
 - Rate limits: per‑session hint caps; basic API token bucket at ingress.
 - Secrets: Secret Manager for keys; least‑privilege IAM for service accounts.

 ---

 ## 10. Analytics, Telemetry & A/B

 - Event schema: `solve_step`, `hint_level`, `misconception_tag`, `latency_ms`, `token_cost`, `llm_calls`.
 - Emission: client + API with dedupe keys; batching + retries.
 - Export: Dataflow template Firestore→BigQuery nightly; datasets `events_raw`, `mastery_daily`, `ab_tests`.
 - Dashboards: Looker Studio for funnel, latency/cost, retention cohorts.
 - A/B: Remote Config toggles for hint ladder depth, animation intensity, quest framing; exposure and outcome logging.

 ---

 ## 11. CI/CD & Tooling

 - GitHub Actions:
   - Client: format/lint/test → build web (staging) → deploy to Firebase Hosting.
   - API: ruff/pytest → build → deploy to App Engine (staging).
   - Infra: deploy Firestore rules, Remote Config templates, Functions, scheduled jobs.
 - Promotion: manual approval to prod; canary via Remote Config percentage.
 - Quality gates: coverage thresholds (API ≥70%, client ≥50% core), Lighthouse checks for web.

 ---

 ## 12. Testing Strategy

 - Unit: orchestrator (regex, CAS, judge), mastery updates, XP/badge rules, JSON validators.
 - Integration: session flow e2e (start→step→end) with fake LLM; Firestore emulator.
 - Contract: OpenAPI schema validated; generated API client for Flutter.
 - Performance: API latency P50/P95; token budget tests; Flutter 60fps jank tests.
 - Safety: prompt injection tests, profanity filters, “no answer leakage” assertions.

 ---

 ## 13. Performance & Cost Controls

 - Budgets: LLM P50 < 2.5s, P95 < 6s; token/session caps; retry coalescing.
 - Caching: static item docs cached client‑side; CDN caching for preview endpoints.
 - Autoscaling: GAE pre‑warm during peak; minimize heavy imports to reduce cold starts.
 - Media: lazy‑load images; disable idle animations; reduce Flutter rebuilds.

 ---

 ## 14. Milestones & Exit Criteria

 - Phase 0:
   - Repos created, CI green; Firebase Auth flows; GAE `/healthz` up; Security Rules deployed.
 - Phase 1:
   - 95% Algebra items render; step flow works; orchestrator v1 passes gold tests; latency P50 target met.
 - Phase 2:
   - XP/badges/streaks/leaderboards functional; dashboards <1.5s P50; analytics visible in BigQuery.
 - Phase 3:
   - Accessibility passes; load tests green; A/B toggles wired; author preview usable.
 - Launch:
   - Canary 10% for 48h; full rollout when error/latency budgets hold.

 ---

 ## 15. Decisions To Lock Early

 - Client state: Riverpod.
 - LLM default: OpenAI `gpt-4o-mini`, Vertex as fallback; env‑switchable.
 - Teacher portal: Flutter web for MVP; revisit Next.js later.
 - Region: `asia-southeast1` for all services.

 ---

 ## 16. Risks & Mitigations

 - LLM latency/cost: maximize regex/CAS resolution; tight prompt/token budgets; cache rubric judgments when safe.
 - Cold starts: min idle instances; reduce heavy imports; warmup pings.
 - Content quality: authoring validator + preview; evaluator gold test set.
 - Security: strict Security Rules, App Check, Secret Manager; periodic audits.

 ---

## 17. Appendix — Initial Deliverables Checklist

- Infra: GCP projects, Firebase projects, Secret Manager entries, App Check configured.
- API: FastAPI skeleton, health endpoint, GAE app.yaml committed; auth middleware (stub) in place.
- Client: Flutter app shell plan in `client/README.md`; starter code and deps listed.
- Content: `enhanced-v1` JSON Schema, validator CLI, 30–50 Algebra items seeded.
- CI/CD: pipelines for client/API/infra; staging deploys; manual prod promotion.
- Analytics: event schema implemented; BigQuery export job scheduled; Looker dashboard template.
