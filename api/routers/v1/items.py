from fastapi import APIRouter, HTTPException, Request
from typing import Dict
from models.schemas import EnhancedItemFile
from services.container import ITEMS_REPO
from core.security import require_roles

router = APIRouter()


@router.post("/items/ingest")
def ingest_items(payload: EnhancedItemFile, request: Request) -> Dict[str, int]:
    # Require author role when auth stub is disabled
    require_roles(request, roles=["author", "admin"])  # admin can also ingest
    for item in payload.items:
        ITEMS_REPO.put_item(item.model_dump())
    return {"ingested": len(payload.items)}


@router.get("/items/{item_id}")
def get_item(item_id: str):
    item = ITEMS_REPO.get_item(item_id)
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    return item
