from fastapi import APIRouter

router = APIRouter()


@router.get("/leaderboard/{scope}")
def leaderboard(scope: str):
    return {"scope": scope, "week": "2025-W01", "entries": []}

