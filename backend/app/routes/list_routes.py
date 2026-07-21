from fastapi import APIRouter, Depends, Query, status
from app.auth.jwt import get_current_user_id
from app.models.media import QueueItemCreate, CompletionLogRequest
from app.dependencies import get_db
from app.services.firestore import FirestoreService
from typing import List, Dict, Any, Optional

router = APIRouter()

@router.get("/active")
def get_active_queue(
    entity_type: Optional[str] = Query(None, description="Filter queue by media type (song, album, artist, podcast, audiobook)"),
    user_id: str = Depends(get_current_user_id),
    db: FirestoreService = Depends(get_db)
):
    """
    Returns all items in the user's active queue.
    """
    items = db.get_active_queue(user_id, entity_type)
    return {"items": items}

@router.post("/active", status_code=status.HTTP_201_CREATED)
def add_to_queue(
    item: QueueItemCreate,
    user_id: str = Depends(get_current_user_id),
    db: FirestoreService = Depends(get_db)
):
    """
    Adds a new item to the user's active queue.
    """
    db.add_item_to_queue(
        user_id=user_id,
        item_id=item.id,
        entity_type=item.entity_type,
        metadata=item.metadata
    )
    return {"status": "success", "message": "Item added to active queue."}

@router.delete("/active/{entity_type}/{item_id}")
def delete_from_queue(
    entity_type: str,
    item_id: str,
    user_id: str = Depends(get_current_user_id),
    db: FirestoreService = Depends(get_db)
):
    """
    Deletes an item from the user's active queue.
    """
    db.delete_item(
        user_id=user_id,
        item_id=item_id,
        entity_type=entity_type,
        queue_only=True
    )
    return {"status": "success", "message": "Item removed from queue."}

@router.post("/active/{entity_type}/{item_id}/complete", status_code=status.HTTP_200_OK)
def log_completion(
    entity_type: str,
    item_id: str,
    request: CompletionLogRequest,
    user_id: str = Depends(get_current_user_id),
    db: FirestoreService = Depends(get_db)
):
    """
    Logs an active queue item as completed (records rating and comments, and moves record to completions).
    """
    db.log_item_completed(
        user_id=user_id,
        item_id=item_id,
        entity_type=entity_type,
        rating=request.rating,
        comment=request.comment
    )
    return {"status": "success", "message": "Item logged as completed."}

@router.get("/completed")
def get_completed_history(
    entity_type: Optional[str] = Query(None, description="Filter history by media type"),
    user_id: str = Depends(get_current_user_id),
    db: FirestoreService = Depends(get_db)
):
    """
    Returns the user's completed media log history.
    """
    items = db.get_completed_list(user_id, entity_type)
    return {"items": items}

@router.delete("/completed/{entity_type}/{item_id}")
def delete_from_completed(
    entity_type: str,
    item_id: str,
    user_id: str = Depends(get_current_user_id),
    db: FirestoreService = Depends(get_db)
):
    """
    Permanently deletes a record from the completed list.
    """
    db.delete_item(
        user_id=user_id,
        item_id=item_id,
        entity_type=entity_type,
        queue_only=False
    )
    return {"status": "success", "message": "Item removed from history."}
