"""
Firestore Data Models - Flat Structure for Optimal Performance
Designed for Singapore PSLE AI Tutor - Production Ready Schema
"""

from typing import Dict, List, Optional, Any
from dataclasses import dataclass, asdict
from datetime import datetime, timezone
import uuid


@dataclass 
class FirestoreUser:
    """
    Complete user profile in single document
    Collection: /users/{userId}
    """
    user_id: str
    email: str
    name: str
    role: str  # 'parent', 'teacher', 'admin'
    profile: Dict[str, Any]
    children_ids: List[str]  # List of learner IDs for parents
    students_ids: List[str]  # List of learner IDs for teachers
    created_at: str
    updated_at: str
    
    @classmethod
    def create_new(cls, user_id: str, email: str, name: str, role: str = 'parent') -> 'FirestoreUser':
        now = datetime.now(timezone.utc).isoformat()
        return cls(
            user_id=user_id,
            email=email,
            name=name,
            role=role,
            profile={
                'grade_level': 'P6',
                'school': '',
                'location': 'Singapore',
                'preferences': {
                    'language': 'en',
                    'notifications': True,
                    'reports_frequency': 'weekly'
                }
            },
            children_ids=[],
            students_ids=[],
            created_at=now,
            updated_at=now
        )


@dataclass
class FirestoreLearner:
    """
    Complete learner profile and progress in single document
    Collection: /learners/{learnerId}
    """
    learner_id: str
    parent_id: str
    teacher_ids: List[str]
    
    # Profile Information
    name: str
    grade_level: str
    subjects: List[str]
    learning_style: str  # 'visual', 'auditory', 'kinesthetic', 'mixed'
    
    # Progress Tracking
    xp: int
    level: int
    streaks: Dict[str, Any]  # current, best, last_active
    badges: List[str]
    completed_items: List[str]
    mastery_scores: Dict[str, float]  # subject -> mastery percentage
    
    # Session Management
    current_session_id: Optional[str]
    total_sessions: int
    total_time_spent: int  # minutes
    
    # Analytics
    performance_stats: Dict[str, Any]
    misconceptions: Dict[str, Dict[str, Any]]  # Aggregated across all sessions
    learning_insights: List[Dict[str, Any]]
    
    # Metadata
    created_at: str
    updated_at: str
    
    @classmethod
    def create_new(cls, learner_id: str, parent_id: str, name: str, grade_level: str = 'P6') -> 'FirestoreLearner':
        now = datetime.now(timezone.utc).isoformat()
        return cls(
            learner_id=learner_id,
            parent_id=parent_id,
            teacher_ids=[],
            name=name,
            grade_level=grade_level,
            subjects=['maths'],
            learning_style='mixed',
            xp=0,
            level=1,
            streaks={
                'current': 0,
                'best': 0,
                'last_active': None
            },
            badges=[],
            completed_items=[],
            mastery_scores={
                'algebra': 0.0,
                'fractions': 0.0,
                'percentage': 0.0,
                'ratio': 0.0,
                'speed': 0.0,
                'geometry': 0.0,
                'statistics': 0.0
            },
            current_session_id=None,
            total_sessions=0,
            total_time_spent=0,
            performance_stats={
                'total_problems_attempted': 0,
                'total_problems_correct': 0,
                'accuracy_rate': 0.0,
                'average_attempts_per_problem': 1.0,
                'hint_usage_rate': 0.0
            },
            misconceptions={},
            learning_insights=[],
            created_at=now,
            updated_at=now
        )


@dataclass
class FirestoreSession:
    """
    Complete tutoring session with full conversation history
    Collection: /sessions/{sessionId}
    """
    session_id: str
    learner_id: str
    item_id: str
    subject: str
    module_id: str
    
    # Session Progress
    current_step_idx: int
    attempts_current: int
    hints_used: int
    finished: bool
    success: bool
    
    # Conversation History (Full context for AI)
    conversation_history: List[Dict[str, Any]]
    
    # Learning Analytics
    learning_insights: List[Dict[str, Any]]
    misconceptions: Dict[str, Dict[str, Any]]  # Detected in this session
    
    # Performance Metrics
    total_time_spent: int  # seconds
    steps_completed: List[Dict[str, Any]]
    final_accuracy: float
    hint_efficiency: float  # hints used vs problems solved
    
    # Metadata
    started_at: str
    completed_at: Optional[str]
    created_at: str
    updated_at: str
    
    @classmethod
    def create_new(cls, learner_id: str, item_id: str, subject: str, module_id: str) -> 'FirestoreSession':
        session_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc).isoformat()
        return cls(
            session_id=session_id,
            learner_id=learner_id,
            item_id=item_id,
            subject=subject,
            module_id=module_id,
            current_step_idx=0,
            attempts_current=0,
            hints_used=0,
            finished=False,
            success=False,
            conversation_history=[],
            learning_insights=[],
            misconceptions={},
            total_time_spent=0,
            steps_completed=[],
            final_accuracy=0.0,
            hint_efficiency=0.0,
            started_at=now,
            completed_at=None,
            created_at=now,
            updated_at=now
        )


@dataclass
class FirestoreCurriculumItem:
    """
    Complete curriculum item with all teaching data
    Collection: /curriculum/{subject}/{itemId}
    """
    item_id: str
    subject: str
    module_id: str
    topic: str
    title: str
    
    # Learning Metadata
    learn_step: int
    complexity: str  # 'Easy', 'Medium', 'Hard'
    difficulty: float  # 0.0 to 1.0
    skill: str
    subskills: List[str]
    prerequisites: List[str]
    estimated_time_seconds: int
    
    # Problem Content
    problem_text: str
    assets: Dict[str, Any]  # images, manipulatives, etc.
    
    # Teaching Structure
    student_view: Dict[str, Any]  # steps, hints, prompts
    teacher_view: Optional[Dict[str, Any]]  # solutions, common pitfalls
    
    # AI Tutoring Configuration
    ai_context: str  # Specific prompting context for this item
    evaluation_rules: Dict[str, Any]  # How to evaluate responses
    
    # Analytics
    telemetry: Dict[str, Any]  # XP rewards, scoring, etc.
    usage_stats: Dict[str, Any]  # How often used, success rates
    
    # Metadata
    version: str
    created_at: str
    updated_at: str
    
    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


# Firestore Collection References
COLLECTIONS = {
    'users': 'users',
    'learners': 'learners', 
    'sessions': 'sessions',
    'curriculum_questions': 'curriculum_questions',  # Flat collection containing all questions
    'curriculum_algebra': 'curriculum/algebra/items',
    'curriculum_fractions': 'curriculum/fractions/items',
    'curriculum_percentage': 'curriculum/percentage/items',
    'curriculum_ratio': 'curriculum/ratio/items',
    'curriculum_speed': 'curriculum/speed/items',
    'curriculum_geometry': 'curriculum/geometry/items',
    'curriculum_statistics': 'curriculum/statistics/items',
}

# Data Access Patterns for Optimal Firestore Performance
QUERY_PATTERNS = {
    'learner_by_parent': 'learners where parent_id == parent_id',
    'learner_sessions': 'sessions where learner_id == learner_id order by started_at desc',
    'current_session': 'sessions where learner_id == learner_id and finished == false',
    'curriculum_by_subject': 'curriculum/{subject}/items order by learn_step asc',
    'learner_progress': 'single document read from learners/{learner_id}',
    'user_children': 'single document read from users/{user_id}, then batch read learners'
}