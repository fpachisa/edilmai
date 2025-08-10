from typing import List, Optional, Literal
from pydantic import BaseModel, Field


class Hint(BaseModel):
    level: int = Field(ge=1, le=5)
    text: str


class Step(BaseModel):
    id: str
    prompt: str
    hints: List[Hint] = []


class StudentView(BaseModel):
    socratic: bool = True
    steps: List[Step]
    reflect_prompts: List[str] = []
    micro_drills: List[str] = []


class TeacherView(BaseModel):
    solutions_teacher: List[str] = []
    common_pitfalls: List[dict] = []


class EvaluationRules(BaseModel):
    regex: Optional[List[dict]] = None
    algebraic_equivalence: bool = False
    llm_fallback: bool = True


class Evaluation(BaseModel):
    rules: EvaluationRules
    notes: Optional[str] = None


class Item(BaseModel):
    id: str
    topic: str
    title: str
    learn_step: int
    complexity: Literal["Easy", "Medium", "Hard"]
    difficulty: float = Field(ge=0, le=1)
    skill: str
    subskills: List[str] = []
    estimated_time_seconds: int = 30
    problem_text: str
    assets: dict = {}
    student_view: StudentView
    teacher_view: Optional[TeacherView] = None
    telemetry: dict = {}
    evaluation: Evaluation


class EnhancedItemFile(BaseModel):
    topic: str
    version: str = "enhanced-v1"
    items: List[Item]


class SessionStartRequest(BaseModel):
    learner_id: str
    item_id: str


class SessionStartResponse(BaseModel):
    session_id: str
    step_id: str
    prompt: str
    ui: list[str] = ["chat", "math_input", "scratchpad"]


class SessionStepRequest(BaseModel):
    session_id: str
    step_id: str
    user_response: str


class SessionStepResponse(BaseModel):
    correctness: Optional[bool] = None
    next_prompt: Optional[str] = None
    hint: Optional[str] = None
    tutor_message: Optional[str] = None
    updates: dict = {}
    finished: bool = False
    step_id: Optional[str] = None
    ui: list[str] = ["chat", "math_input", "scratchpad"]


class SessionEndRequest(BaseModel):
    session_id: str
