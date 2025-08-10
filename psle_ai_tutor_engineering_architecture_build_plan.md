# PSLE AI Tutor — Engineering Architecture & Build Plan (GAE + Firebase)

> **Audience:** Engineering, Product, Design, Data.\
> **Scope:** P6 Maths MVP with Socratic AI, gamification, dashboards.\
> **Target Platforms:** iOS, Android, Web.\
> **Cloud:** Google App Engine (GAE) + Firebase suite.

---

## 1) Product Goals & Non‑Goals (MVP)

**Goals**

- Socratic, step‑based tutoring for PSLE Maths (P6) aligned to MOE.
- Visually rich, game‑like experience with low friction and high retention.
- Parent/Teacher dashboards; learner mastery tracking and adaptive practice.
- Content authoring pipeline using **Enhanced Item JSON** (enriched schema).

**Non‑Goals (for MVP)**

- Full offline content sync across all grades/subjects.
- Advanced classroom orchestration (assignments, pacing).
- Human live tutoring.

---

## 2) User Journeys (Condensed)

1. **Learner:** Sign in → choose Quest → solve item via Socratic chat + canvas → reflect → earn XP/badges → next item auto‑select.
2. **Parent/Teacher:** Sign in → view progress, mastery and time‑on‑task → see misconceptions → printable report.
3. **Content Author:** Upload/validate Enhanced JSON → preview flow → publish to catalog.

---

## 3) Proposed Tech Stack

**Frontend**

- **Flutter** (iOS/Android/Web): one codebase, rich animations, Lottie/Rive support.
  - State: Riverpod or Bloc.
  - UI: Material 3 + custom theme; Rive/Lottie for micro‑animations; Flame (optional) for mini‑games.
  - Charts: fl\_chart.
  - Accessibility: large fonts, high‑contrast themes.

**Backend**

- **Google App Engine (Standard)** running **Python (FastAPI)** **or** **Node (NestJS)**.
  - We’ll scaffold with **FastAPI** for clarity/performance, async I/O.
- **Firebase** services:
  - **Auth** (Email/Password, Apple, Google; optional phone).
  - **Cloud Firestore** (realtime doc store for users, progress, items index, leaderboards).
  - **Cloud Functions** (scheduled jobs, webhook processing, secure server‑side ops).
  - **Cloud Storage** (images, diagrams, exports).
  - **Remote Config** (feature flags, A/B variants, difficulty knobs).
  - **Analytics** + **Crashlytics** (engagement + stability).
  - **App Check** (abuse mitigation).
- **LLM Layer (provider‑agnostic)**
  - First‑class support for **OpenAI** and **Vertex AI**; switch via env.
  - Orchestrator: lightweight custom service (no heavy framework) + JSON schema validators.
  - Optional: **Sympy** (Python) for CAS checks; **NumPy** for numeric tolerance.

**DevOps / Data**

- **CI/CD:** GitHub Actions → Cloud Build → GAE deploy; Firebase Hosting for web.
- **Monitoring:** Cloud Logging, Error Reporting, Cloud Trace; Sentry (optional).
- **Data Warehouse:** BigQuery (daily export from Firestore via Dataflow templates).
- **Experimentation:** Firebase A/B Testing + Remote Config.

---

## 4) System Architecture (Logical)

**Client (Flutter)** ↔ **API Gateway (GAE FastAPI)** ↔ **Services**:

- **Tutor Service** (LLM Orchestrator): state machine execution, hint ladder selection, evaluation pipeline (regex → CAS → LLM), token budgeting.
- **Content Service**: ingest/validate Enhanced Item JSON; versioning; preview.
- **Mastery Service**: Bayesian mastery updates (ELO/IRT hybrid), spaced repetition.
- **Gamification Service**: XP, badges, streaks, quests, leaderboards (aggregations).
- **Telemetry Service**: session logs, step outcomes, hint levels, latency, cost.
- **Reporting Service**: parent/teacher summaries; PDF generation (Cloud Run job).

**Data Stores**

- Firestore collections: `users/`, `learners/`, `sessions/`, `events/`, `items/`, `catalog/`, `leaderboards/`, `badges/`, `versions/`.
- Storage buckets: `assets/diagrams/`, `exports/reports/`.
- BigQuery datasets: `events_raw`, `mastery_daily`, `ab_tests`.

---

## 5) Enhanced Item JSON (Authoring Schema)

**File wrapper**

```json
{
  "topic": "Algebra",
  "version": "enhanced-v1",
  "items": [ /* see item schema */ ]
}
```

**Item (minimum fields)**

```json
{
  "id": "ALG-S1-E1",
  "topic": "Algebra",
  "title": "Adding to an Unknown",
  "learn_step": 1,
  "complexity": "Easy",
  "difficulty": 0.25,
  "skill": "Algebraic Expressions",
  "subskills": ["use-variable", "form-addition-expression"],
  "estimated_time_seconds": 30,
  "problem_text": "Amelia has 'b' books...",
  "assets": {"manipulatives": [], "image_url": null, "svg_code": null},
  "student_view": {
    "socratic": true,
    "steps": [ /* micro-steps with hints L1-L3 */ ],
    "reflect_prompts": ["..."],
    "micro_drills": []
  },
  "teacher_view": {
    "solutions_teacher": ["..."],
    "common_pitfalls": [{"text": "4b instead of b+4", "tag": "concat-for-multiply"}]
  },
  "telemetry": {"scoring": {"xp": 10, "bonus_no_hints": 2}, "prereqs": [], "next_items": []},
  "evaluation": {
    "rules": {
      "regex": [{"equivalent_to": "b+4"}],
      "algebraic_equivalence": true,
      "llm_fallback": true
    },
    "notes": "Regex → CAS → LLM adjudication"
  }
}
```

**Validation contract**

- `regex` supports normalisation (trim spaces, canonical order when safe).
- `algebraic_equivalence` calls a CAS (sympy) to compare forms.
- `llm_fallback` adjudicates with rubric prompt (no answer leakage).

---

## 6) API Design (GAE FastAPI)

**Auth**

- Firebase Auth tokens verified by GAE middleware; RBAC roles: `learner`, `parent`, `teacher`, `author`, `admin`.

**Endpoints (v1)**

- `POST /v1/session/start` → payload: learner\_id, item\_id | returns session\_id, first prompt.
- `POST /v1/session/step` → payload: session\_id, step\_id, user\_response | returns: correctness, next prompt/hint, updates.
- `POST /v1/session/end` → writes summary, mastery delta.
- `GET /v1/items/:id` → item payload for preview (author/teacher).
- `POST /v1/items/ingest` → upload Enhanced JSON; validate, version.
- `GET /v1/leaderboard/:scope` → weekly scope: cohort/school/national.
- `GET /v1/profile/:learner_id` → mastery vector, streaks, badges.

**Webhooks / Jobs**

- Cloud Functions cron: recompute leaderboards daily; export events to BigQuery; rotate A/B variants.

---

## 7) Tutor Orchestrator (LLM) — Decision Flow

1. **Receive**: current step, learner response, history, misconception tags.
2. **Evaluate** (pipeline):\
   a) Regex & normalisation\
   b) CAS equivalence (sympy) / numeric tolerance\
   c) If inconclusive → **LLM judge** with rubric (no final answer reveal).
3. **Select** next action:
   - Correct → move to next step or Reflect.
   - Incorrect → pick hint level based on struggle signals; tag misconception.
   - Low confidence → ask a clarifying Socratic probe.
4. **Update** mastery (IRT/ELO hybrid) + telemetry (events).
5. **Return** render payload (prompt text, hint text, UI widgets to show).

**LLM prompts (guardrails)**

- System: “Patient Socratic tutor for P6 Maths; never reveal final answer; ask one question at a time; short sentences; Singapore context.”
- Judge rubric: evaluate equivalence, check units, identify misconception category, recommend hint level (L1–L3).

---

## 8) Data Model (Firestore)

**Collections**

- `users/{uid}`: profile, role, PII minimal (PDPA).
- `learners/{lid}`: grade, preferences, current quest, streak.
- `items/{itemId}`: Enhanced Item JSON (denormalised, version pointer).
- `sessions/{sid}`: { learner\_id, item\_id, steps[ ], times, hints\_used, outcome }.
- `events/{eventId}`: granular logs for analytics (BigQuery sink).
- `leaderboards/{scope}`: computed aggregates (week key).
- `badges/{badgeId}`: definitions + awarding rules.

**PII & Compliance**

- Minimise PII; region: **asia-southeast1**.
- Parental consent flags; audit logs; data retention policy (1yr raw events → aggregated thereafter).
- Access via Security Rules + custom claims (teacher vs parent visibility).

---

## 9) Gamification System

- **XP** per correct step; bonus for no‑hint solves; decay‑proof streaks (grace day).
- **Badges**: mastery milestones, perseverance (recover after 2 hints), speed (within T).
- **Leaderboards**: weekly reset; anti‑cheat via server validation + App Check.
- **Quests**: themed arcs (5–7 items) mapped to subskills with art + light narrative.

---

## 10) UI/UX Guidelines (Visually Stunning, Engaging)

- **Design Language:** playful‑premium; soft gradients, rounded 2xl corners, depth; motion that aids meaning.
- **Animations:** micro‑feedback on each step; confetti burst on milestone; Rive for character reactions.
- **Socratic Canvas:** split view (chat bubbles ↔ working area with bar models/number lines).
- **Accessibility:** dyslexic‑friendly font option; haptic hints; captions on animations.
- **Performance:** 60fps targets; idle Lottie disabled; image lazy‑load.

---

## 11) Security, Privacy, Safety

- **Auth**: Firebase; token verification on GAE; refresh handling on client.
- **Rules**: Firestore Security Rules + custom claims; Row‑level read filters for parents/teachers.
- **Secrets**: Secret Manager (LLM keys, service creds).
- **Network**: Restrict egress for GAE to LLM endpoints; VPC egress if needed.
- **Safety**: content filters and profanity shields in LLM outputs; hint rate limiting.

---

## 12) Analytics & A/B Testing

- Funnel: Onboard → First Solve → First Streak → 7‑day Retention.
- Event schema: `solve_step`, `hint_level`, `misconception_tag`, `latency_ms`, `token_cost`.
- A/B: hint ladder depth (3 vs 5), animation intensity (low vs high), quest framing (story vs plain).
- Dashboards: Looker Studio on BigQuery.

---

## 13) Deployment & Environments

- **Envs**: dev, staging, prod (separate Firebase projects).
- **Web**: Firebase Hosting → GAE API; CDN enabled.
- **Mobile**: CI via Fastlane; upload to App Store/Play; feature flags via Remote Config.
- **GAE**: minimum instances tuned; autoscale; health checks.
- **Jobs**: Cloud Scheduler → Functions for leaderboards, exports.

---

## 14) CI/CD Pipeline

- PR → lint, type‑check, tests → build Flutter (web + mobile artifacts) → run unit/integration tests → deploy to **staging**.
- Manual QA checklist → promote to **prod**.
- Migrations: content version bump → backfill index docs.
- Canary rollout via Remote Config percentage.

---

## 15) Acceptance Criteria (MVP)

- **Tutoring**: 95% of Algebra items render and progress via steps; no answer leak; avg LLM latency < 2.5s P50, < 6s P95.
- **Evaluation**: regex+CAS resolve ≥80% of answers without LLM; judge accuracy ≥97% on gold set.
- **Mastery**: progression curves visible; weak subskills resurface within 24–72h.
- **Gamification**: XP, badges, streaks, leaderboard weekly reset verified.
- **Dashboards**: parent/teacher summaries load < 1.5s P50.
- **Stability**: crash‑free users > 99.5%.

---

## 16) Build Plan & Timeline (indicative)

**Phase 0 — Foundations (2 weeks)**

- Repo setup, CI/CD, Firebase projects, Auth, skeleton Flutter app, FastAPI boilerplate.

**Phase 1 — Tutoring Core (4 weeks)**

- Socratic state machine in client, API endpoints, Orchestrator v1 (regex→CAS→LLM), render Algebra Enhanced JSON.

**Phase 2 — Gamification & Dashboards (3 weeks)**

- XP/Badges/Leaderboards; parent/teacher dashboards; analytics plumbing.

**Phase 3 — Polish & Hardening (2 weeks)**

- Animations, performance, accessibility; load tests; A/B hooks; content preview tool.

---

## 17) Sample Configs

**app.yaml (GAE, Python)**

```yaml
runtime: python312
instance_class: F2
entrypoint: uvicorn api.main:app --host 0.0.0.0 --port $PORT
handlers:
  - url: /v1/.*
    script: auto
    secure: always
    login: optional
automatic_scaling:
  min_idle_instances: 1
  max_instances: 10
  target_cpu_utilization: 0.6
```

**Firestore Rules (sketch)**

```bash
match /databases/{database}/documents {
  match /learners/{lid} {
    allow read: if request.auth != null && (request.auth.uid == lid || hasRole("teacher") || hasRole("parent"));
    allow write: if request.auth != null && request.auth.uid == lid;
  }
  match /sessions/{sid} {
    allow read, write: if request.auth != null && resource.data.learner_id == request.auth.uid;
  }
}
```

**Orchestrator service env**

```bash
LLM_PROVIDER=openai # or vertex
LLM_MODEL=gpt-4o-mini
REGEX_ENABLED=true
CAS_ENABLED=true
MAX_HINT_LEVEL=3
```

---

## 18) Open Questions / Nice‑to‑Haves

- Should we ship **web** first with Flutter, or add a **Next.js** teacher portal for richer tables?
- Add **classroom mode** (project to TV, QR join).
- **Rewards store** (stickers/avatars) governed by XP.
- **Voice** (ASR/TTS) for accessibility; on‑device TTS first.

---

## 19) Handover Checklist

- Repos created (client, api, infra), env secrets in Secret Manager, Firebase projects (dev/stage/prod).
- Content: Algebra Enhanced JSON ingested; preview tool working.
- Design kit (Figma) with tokens: colors, spacing, motion, iconography.

**Ready for build.**

