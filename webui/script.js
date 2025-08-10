const sample = {
  topic: "Algebra",
  version: "enhanced-v1",
  items: [
    {
      id: "ALG-S1-E1",
      topic: "Algebra",
      title: "Adding to an Unknown",
      learn_step: 1,
      complexity: "Easy",
      difficulty: 0.25,
      skill: "Algebraic Expressions",
      subskills: ["use-variable", "form-addition-expression"],
      estimated_time_seconds: 30,
      problem_text:
        "Amelia has 'b' books. She buys 4 more. Write an expression for how many books she has now.",
      assets: { manipulatives: [], image_url: null, svg_code: null },
      student_view: {
        socratic: true,
        steps: [
          {
            id: "s1",
            prompt:
              "If Amelia has b books and buys 4 more, what is the new total in terms of b?",
            hints: [
              { level: 1, text: "Start with b and add 4." },
              { level: 2, text: "Write it as b + 4." },
            ],
          },
        ],
        reflect_prompts: ["Why is it addition and not multiplication?"],
        micro_drills: [],
      },
      teacher_view: {
        solutions_teacher: ["b + 4"],
        common_pitfalls: [{ text: "4b instead of b+4", tag: "concat-for-multiply" }],
      },
      telemetry: { scoring: { xp: 10, bonus_no_hints: 2 }, prereqs: [], next_items: [] },
      evaluation: {
        rules: {
          regex: [{ equivalent_to: "b+4" }],
          algebraic_equivalence: true,
          llm_fallback: true,
        },
        notes: "Regex → CAS → LLM adjudication",
      },
    },
  ],
};

const els = {
  apiUrl: document.getElementById("apiUrl"),
  btnIngest: document.getElementById("btnIngest"),
  learnerId: document.getElementById("learnerId"),
  btnStart: document.getElementById("btnStart"),
  btnEnd: document.getElementById("btnEnd"),
  sessionInfo: document.getElementById("sessionInfo"),
  prompt: document.getElementById("prompt"),
  answer: document.getElementById("answer"),
  btnSubmit: document.getElementById("btnSubmit"),
  hint: document.getElementById("hint"),
  log: document.getElementById("log"),
};

let state = { sessionId: null, currentStepId: "s1" };

function log(msg) {
  const ts = new Date().toISOString();
  els.log.textContent += `[${ts}] ${msg}\n`;
  els.log.scrollTop = els.log.scrollHeight;
}

function setPrompt(text) {
  els.prompt.textContent = text || "";
}

function setHint(text) {
  els.hint.textContent = text || "";
}

async function ingest() {
  const url = `${els.apiUrl.value}/v1/items/ingest`;
  const r = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(sample),
  });
  const body = await r.json();
  if (!r.ok) throw new Error(body.detail || r.statusText);
  log(`Ingested ${body.ingested} item(s)`);
}

async function startSession() {
  const url = `${els.apiUrl.value}/v1/session/start`;
  const r = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ learner_id: els.learnerId.value || "demo", item_id: "ALG-S1-E1" }),
  });
  const body = await r.json();
  if (!r.ok) throw new Error(body.detail || r.statusText);
  state.sessionId = body.session_id;
  setPrompt(body.first_prompt);
  els.btnSubmit.disabled = false;
  els.btnEnd.disabled = false;
  els.sessionInfo.textContent = `Session: ${state.sessionId}`;
  log(`Session started: ${state.sessionId}`);
}

async function submitAnswer() {
  if (!state.sessionId) return;
  const url = `${els.apiUrl.value}/v1/session/step`;
  const r = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      session_id: state.sessionId,
      step_id: state.currentStepId,
      user_response: (els.answer.value || "").trim(),
    }),
  });
  const body = await r.json();
  if (!r.ok) throw new Error(body.detail || r.statusText);
  if (body.correctness === true) {
    setHint("");
    setPrompt(body.next_prompt || "Correct!\nAll steps complete.");
  } else if (body.hint) {
    setHint(`Hint: ${body.hint}`);
  } else {
    setHint("Let's think step by step.");
  }
  log(`Step result: ${JSON.stringify(body)}`);
}

async function endSession() {
  if (!state.sessionId) return;
  const url = `${els.apiUrl.value}/v1/session/end`;
  const r = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ session_id: state.sessionId }),
  });
  const body = await r.json();
  if (!r.ok) throw new Error(body.detail || r.statusText);
  log(`Session ended: ${state.sessionId}`);
  state.sessionId = null;
  els.btnSubmit.disabled = true;
  els.btnEnd.disabled = true;
  setHint("");
  setPrompt("");
  els.sessionInfo.textContent = "";
}

els.btnIngest.addEventListener("click", () =>
  ingest().catch((e) => log(`ERROR ingest: ${e.message}`))
);
els.btnStart.addEventListener("click", () =>
  startSession().catch((e) => log(`ERROR start: ${e.message}`))
);
els.btnSubmit.addEventListener("click", () =>
  submitAnswer().catch((e) => log(`ERROR step: ${e.message}`))
);
els.btnEnd.addEventListener("click", () =>
  endSession().catch((e) => log(`ERROR end: ${e.message}`))
);

