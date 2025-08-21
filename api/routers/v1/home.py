from fastapi import APIRouter, HTTPException
from services.container import ITEMS_REPO, PROFILES_REPO, SESSIONS_REPO

router = APIRouter()


def _topics_from_items():
  topics = {}
  for it in ITEMS_REPO.items.values():
    t = it.get("topic", "General")
    topics.setdefault(t, []).append(it)
  return topics


@router.get("/homefeed/{learner_id}")
def get_homefeed(learner_id: str):
  profile = PROFILES_REPO.get_profile(learner_id)
  items = list(ITEMS_REPO.items.values())
  completed = set(profile.get("completed_items", []))

  # Continue card
  cont = None
  sid = profile.get("current_session_id")
  if sid:
    s = SESSIONS_REPO.get(sid)
    if s:
      it = ITEMS_REPO.get_item(s.get("item_id")) or {}
      cont = {
        "session_id": sid,
        "item_id": s.get("item_id"),
        "title": it.get("title", "Continue learning"),
        "est_seconds": it.get("estimated_time_seconds", 60),
      }

  # Daily quest: pick up to 2 not-yet-completed items
  dq = []
  for it in items:
    if it["id"] in completed:
      continue
    dq.append({
      "id": it["id"],
      "title": it.get("title", "Practice"),
      "est_seconds": it.get("estimated_time_seconds", 60),
      "topic": it.get("topic", "General"),
      "skill": it.get("skill", "")
    })
    if len(dq) >= 2:
      break

  # For you: recommend next two items with reasons
  fy = []
  for it in items:
    if it["id"] in completed:
      continue
    reason = f"Because you haven't tried {it.get('skill', 'this')} yet"
    fy.append({
      "item_id": it["id"],
      "title": it.get("title", "Practice"),
      "reason": reason,
      "topic": it.get("topic", "General"),
      "skill": it.get("skill", "")
    })
    if len(fy) >= 2:
      break

  # Topics with naive mastery (completed/total per topic)
  topics = _topics_from_items()
  topics_arr = []
  for t, arr in topics.items():
    total = len(arr)
    done = len([x for x in arr if x["id"] in completed])
    pct = 0 if total == 0 else done / total
    topics_arr.append({"id": t.lower(), "title": t, "mastery_pct": pct})

  # Collections (static placeholders for now)
  collections = [
    {"id": "algebra_starter", "title": "Algebra Starter", "items_count": len([i for i in items if i.get("topic") == "Algebra"])},
    {"id": "number_lines", "title": "Number Lines Basics", "items_count": 0},
  ]

  # Gamification from profile (stubs for now)
  gamification = {
    "xp": profile.get("xp", 0),
    "streak_days": 0,
    "next_badge": {"id": "first_steps", "label": "First Steps", "progress": 0, "target": 1},
  }

  weekly = {"challenge": {"id": "weekly-1", "title": "Solve 3 items", "progress": len(completed) % 3, "target": 3}, "leaderboard": []}

  return {
    "continue": cont,
    "daily_quest": dq,
    "for_you": fy,
    "collections": collections,
    "topics": topics_arr,
    "gamification": gamification,
    "weekly": weekly,
  }


@router.get("/catalog/topics")
def list_topics():
  topics = _topics_from_items()
  return [{"id": t.lower(), "title": t, "count": len(arr)} for t, arr in topics.items()]


@router.get("/catalog/collections")
def list_collections():
  topics = _topics_from_items()
  algebra_count = len(topics.get("Algebra", []))
  return [
    {"id": "algebra_starter", "title": "Algebra Starter", "count": algebra_count},
    {"id": "bar_models", "title": "Bar Models Basics", "count": 0},
  ]

