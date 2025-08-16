from __future__ import annotations
from dataclasses import dataclass, field
from typing import Dict, Optional, Any
import uuid


@dataclass
class InMemoryItemsRepo:
    items: Dict[str, dict] = field(default_factory=dict)

    def put_item(self, item: dict):
        self.items[item["id"]] = item

    def get_item(self, item_id: str) -> Optional[dict]:
        return self.items.get(item_id)


@dataclass
class InMemorySessionsRepo:
    sessions: Dict[str, dict] = field(default_factory=dict)

    def create_session(self, learner_id: str, item_id: str) -> str:
        sid = str(uuid.uuid4())
        self.sessions[sid] = {
            "id": sid,
            "learner_id": learner_id,
            "item_id": item_id,
            "steps": [],  # log of interactions
            "conversation_history": [],  # chronological conversation for AI context
            "current_step_idx": 0,
            "attempts_current": 0,
            "hints_used": 0,
            "finished": False,
            "learning_insights": [],  # AI-observed learning patterns
            "misconceptions": {},  # Track misconception frequency
        }
        return sid

    def get(self, session_id: str) -> Optional[dict]:
        return self.sessions.get(session_id)

    def append_step(self, session_id: str, step: dict):
        self.sessions[session_id]["steps"].append(step)

    def inc_attempt(self, session_id: str):
        self.sessions[session_id]["attempts_current"] += 1

    def reset_attempts(self, session_id: str):
        self.sessions[session_id]["attempts_current"] = 0

    def advance_step(self, session_id: str):
        self.sessions[session_id]["current_step_idx"] += 1
        self.reset_attempts(session_id)

    def mark_finished(self, session_id: str):
        self.sessions[session_id]["finished"] = True

    def add_to_conversation(self, session_id: str, role: str, message: str, metadata: dict = None):
        """Add message to conversation history with timestamp."""
        import datetime
        entry = {
            "timestamp": datetime.datetime.utcnow().isoformat(),
            "role": role,  # 'student', 'tutor', 'system'
            "message": message,
            "metadata": metadata or {}
        }
        self.sessions[session_id]["conversation_history"].append(entry)

    def get_conversation_history(self, session_id: str, limit: int = 10) -> list:
        """Get recent conversation history for AI context."""
        history = self.sessions[session_id]["conversation_history"]
        return history[-limit:] if limit else history

    def add_learning_insight(self, session_id: str, insight: str, confidence: float = 1.0):
        """Record AI-observed learning patterns."""
        import datetime
        entry = {
            "timestamp": datetime.datetime.utcnow().isoformat(),
            "insight": insight,
            "confidence": confidence
        }
        self.sessions[session_id]["learning_insights"].append(entry)

    def record_misconceptions(self, session_id: str, misconception_tags: list, confidence: float = 1.0):
        """Record identified misconceptions with frequency tracking."""
        import datetime
        session = self.sessions[session_id]
        for tag in misconception_tags:
            if tag not in session["misconceptions"]:
                session["misconceptions"][tag] = {
                    "count": 0,
                    "first_seen": datetime.datetime.utcnow().isoformat(),
                    "last_seen": datetime.datetime.utcnow().isoformat(),
                    "confidence_scores": []
                }
            session["misconceptions"][tag]["count"] += 1
            session["misconceptions"][tag]["last_seen"] = datetime.datetime.utcnow().isoformat()
            session["misconceptions"][tag]["confidence_scores"].append(confidence)

    def get_misconception_summary(self, session_id: str) -> dict:
        """Get summarized misconception data for AI context."""
        misconceptions = self.sessions[session_id]["misconceptions"]
        return {
            tag: {"count": data["count"], "avg_confidence": sum(data["confidence_scores"]) / len(data["confidence_scores"])}
            for tag, data in misconceptions.items()
        }


@dataclass
class InMemoryProfilesRepo:
    profiles: Dict[str, dict] = field(default_factory=dict)

    def get_profile(self, learner_id: str) -> dict:
        return self.profiles.setdefault(learner_id, {
            "learner_id": learner_id, 
            "xp": 0, 
            "badges": [],
            "completed_items": [],
            "current_session_id": None,
            # Metadata
            "name": "Your Learner",
            "grade_level": "P6",
            "subjects": ["maths"],
        })

    def add_xp(self, learner_id: str, amount: int):
        p = self.get_profile(learner_id)
        p["xp"] = p.get("xp", 0) + amount

    def mark_item_completed(self, learner_id: str, item_id: str):
        """Mark an item as completed for the learner."""
        p = self.get_profile(learner_id)
        if item_id not in p["completed_items"]:
            p["completed_items"].append(item_id)
    
    def set_current_session(self, learner_id: str, session_id: str):
        """Track current active session."""
        p = self.get_profile(learner_id)
        p["current_session_id"] = session_id
    
    def clear_current_session(self, learner_id: str):
        """Clear current session when completed."""
        p = self.get_profile(learner_id)
        p["current_session_id"] = None

    def create_learner(self, *, name: str, grade_level: str = "P6", subjects: Optional[list[str]] = None, learner_id: Optional[str] = None) -> str:
        import uuid
        lid = learner_id or str(uuid.uuid4())
        p = self.get_profile(lid)
        p["name"] = name or "Your Learner"
        p["grade_level"] = grade_level or "P6"
        p["subjects"] = subjects or ["maths"]
        self.profiles[lid] = p
        return lid


@dataclass
class InMemoryParentsRepo:
    parents: Dict[str, dict] = field(default_factory=dict)

    def _get(self, parent_uid: str) -> dict:
        return self.parents.setdefault(parent_uid, {"children": []})

    def add_child(self, parent_uid: str, learner_id: str):
        p = self._get(parent_uid)
        if learner_id not in p["children"]:
            p["children"].append(learner_id)

    def list_children(self, parent_uid: str) -> list[str]:
        return list(self._get(parent_uid)["children"])
