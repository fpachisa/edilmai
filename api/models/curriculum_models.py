"""
Firestore models for curriculum management
Hybrid approach: JSON files for authoring → Firestore for production runtime
"""

from typing import Dict, List, Optional, Any
from datetime import datetime, timezone
from dataclasses import dataclass, field
import uuid


@dataclass
class CurriculumQuestion:
    """Individual question/problem in the curriculum"""
    # Core identifiers (required fields first)
    question_id: str  # e.g., "ALGEBRA-INTRO-Q1"
    topic: str        # e.g., "algebra" 
    subtopic: str     # e.g., "introduction-to-algebra"
    
    # Educational metadata (required fields)
    title: str
    learn_step: int           # Position in learning progression (1, 2, 3...)
    complexity: str           # "Easy", "Medium", "Hard"
    difficulty: float         # 0.0-1.0 numerical difficulty
    skill: str               # Primary skill being taught
    subskills: List[str]     # Specific subskills
    estimated_time_seconds: int
    problem_text: str
    
    # Optional fields with defaults (must come after required fields)
    marks: int = 1           # Point value for grading
    assets: Optional[Dict[str, Any]] = None  # Images, SVG, manipulatives
    
    # Student interaction structure
    student_view: Dict[str, Any] = field(default_factory=dict)  # Socratic steps, hints, etc.
    
    # Teacher resources  
    teacher_view: Dict[str, Any] = field(default_factory=dict)  # Solutions, common pitfalls
    
    # AI evaluation rules
    evaluation: Dict[str, Any] = field(default_factory=dict)    # Regex, algebraic rules, LLM fallback
    
    # CRITICAL: Answer evaluation data  
    answer_details: Dict[str, Any] = field(default_factory=dict)  # correct_answer, alternative_answers, answer_format
    ai_guidance: Dict[str, Any] = field(default_factory=dict)     # evaluation_strategy, keywords, misconceptions, hints
    
    # Gamification and progression
    telemetry: Dict[str, Any] = field(default_factory=dict)     # XP, prerequisites, next items
    
    # Metadata for curriculum management
    version: str = "1.0"
    created_at: str = field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    updated_at: str = field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    
    # Performance analytics (populated by usage)
    usage_stats: Dict[str, Any] = field(default_factory=lambda: {
        "times_used": 0,
        "success_rate": 0.0, 
        "average_completion_time": 0,
        "common_misconceptions": []
    })

    def to_firestore_dict(self) -> Dict[str, Any]:
        """Convert to Firestore document format"""
        return {
            "question_id": self.question_id,
            "topic": self.topic,
            "subtopic": self.subtopic,
            "title": self.title,
            "learn_step": self.learn_step,
            "complexity": self.complexity,
            "difficulty": self.difficulty,
            "skill": self.skill,
            "subskills": self.subskills,
            "estimated_time_seconds": self.estimated_time_seconds,
            "marks": self.marks,
            "problem_text": self.problem_text,
            "assets": self.assets or {},
            "student_view": self.student_view,
            "teacher_view": self.teacher_view,
            "evaluation": self.evaluation,
            "answer_details": self.answer_details,
            "ai_guidance": self.ai_guidance,
            "telemetry": self.telemetry,
            "version": self.version,
            "created_at": self.created_at,
            "updated_at": self.updated_at,
            "usage_stats": self.usage_stats
        }

    @classmethod  
    def from_json_item(cls, item: Dict[str, Any], topic: str, subtopic: str) -> 'CurriculumQuestion':
        """Create from JSON curriculum file item"""
        return cls(
            question_id=item.get("id", ""),
            topic=topic.lower(),
            subtopic=subtopic.lower(),
            title=item.get("title", ""),
            learn_step=item.get("learn_step", 1),
            complexity=item.get("complexity", "Easy"),
            difficulty=item.get("difficulty", 0.5),
            skill=item.get("skill", ""),
            subskills=item.get("subskills", []),
            estimated_time_seconds=item.get("estimated_time_seconds", 30),
            marks=item.get("marks", 1),
            problem_text=item.get("problem_text", ""),
            assets=item.get("assets", {}),
            student_view=item.get("student_view", {}),
            teacher_view=item.get("teacher_view", {}),
            evaluation=item.get("evaluation", {}),
            answer_details=item.get("answer_details", {}),
            ai_guidance=item.get("ai_guidance", {}),
            telemetry=item.get("telemetry", {})
        )


@dataclass 
class TopicProgression:
    """Ordered sequence of questions for a topic"""
    topic: str                    # e.g., "algebra"
    subtopic: str                 # e.g., "introduction-to-algebra" 
    question_sequence: List[str]  # Ordered list of question_ids
    total_questions: int
    estimated_duration_minutes: int
    
    # Metadata
    created_at: str = field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    updated_at: str = field(default_factory=lambda: datetime.now(timezone.utc).isoformat())

    def to_firestore_dict(self) -> Dict[str, Any]:
        return {
            "topic": self.topic,
            "subtopic": self.subtopic,
            "question_sequence": self.question_sequence,
            "total_questions": self.total_questions,
            "estimated_duration_minutes": self.estimated_duration_minutes,
            "created_at": self.created_at,
            "updated_at": self.updated_at
        }


# Firestore collection names
COLLECTIONS = {
    "curriculum_questions": "curriculum_questions",
    "topic_progressions": "topic_progressions",
    "curriculum_metadata": "curriculum_metadata"
}