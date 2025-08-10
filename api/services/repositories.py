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
            "current_step_idx": 0,
            "attempts_current": 0,
            "hints_used": 0,
            "finished": False,
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


@dataclass
class InMemoryProfilesRepo:
    profiles: Dict[str, dict] = field(default_factory=dict)

    def get_profile(self, learner_id: str) -> dict:
        return self.profiles.setdefault(learner_id, {"learner_id": learner_id, "xp": 0, "badges": []})

    def add_xp(self, learner_id: str, amount: int):
        p = self.get_profile(learner_id)
        p["xp"] = p.get("xp", 0) + amount
