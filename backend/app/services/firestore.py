import re
import time
from typing import Any, Dict, List, Optional

from fastapi import HTTPException, status
from google.api_core.exceptions import GoogleAPIError
from google.auth.exceptions import GoogleAuthError
from google.cloud import firestore
from google.cloud.firestore_v1.base_query import FieldFilter

from app.config import settings

USERS_COLLECTION = "users"
QUEUE_COLLECTION = "queue"
COMPLETED_COLLECTION = "completed"

# google.auth errors (credentials, token refresh, transport) are disjoint from
# google.api_core's GoogleAPIError, so both must be caught for the documented
# degrade-to-empty behaviour to hold against real credentials.
DATABASE_ERRORS = (GoogleAPIError, GoogleAuthError)

# Firestore document ID constraints that DynamoDB sort keys did not have:
# no '/', no reserved '__*__' pattern, and a byte-length ceiling. item_id and
# entity_type are client-supplied, so both are validated here -- this is the
# single choke point shared by add_item_to_queue, log_item_completed, and
# delete_item.
_RESERVED_ID_PATTERN = re.compile(r"^__.*__$")
MAX_ITEM_ID_LENGTH = 1000


def _doc_id(entity_type: str, item_id: str) -> str:
    """Stable document ID, so re-adding an item upserts instead of duplicating.

    Raises HTTPException(400) for malformed client input -- this is not a
    server fault, so it must not be swallowed into a 500.
    """
    for label, value in (("item_id", item_id), ("entity_type", entity_type)):
        if not value or not value.strip():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"{label} must not be empty.",
            )
        if "/" in value:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"{label} must not contain '/'.",
            )
        if _RESERVED_ID_PATTERN.match(value):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"{label} must not match the reserved '__*__' pattern.",
            )
    if len(item_id) > MAX_ITEM_ID_LENGTH:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"item_id must be at most {MAX_ITEM_ID_LENGTH} characters.",
        )
    return f"{entity_type.lower()}_{item_id}"


def _epoch(value: Any) -> Optional[int]:
    """Normalises a Firestore timestamp to epoch seconds.

    Writes use SERVER_TIMESTAMP, so reads return a datetime. Clients have
    always seen integers here, so convert rather than change the contract.
    """
    if value is None:
        return None
    if isinstance(value, (int, float)):
        return int(value)
    return int(value.timestamp())


def _map_queue_item(snapshot) -> Dict[str, Any]:
    """Maps a queue document to the client-facing shape.

    Deliberately explicit: document identity and any future internal fields
    stay out of API responses.
    """
    data = snapshot.to_dict() or {}
    return {
        "entity_type": data.get("entity_type"),
        "item_id": data.get("item_id"),
        "added_at": _epoch(data.get("added_at")),
        "is_completed": data.get("is_completed", False),
        "metadata": data.get("metadata", {}),
    }


def _map_completed_item(snapshot) -> Dict[str, Any]:
    """Maps a completed document to the client-facing shape."""
    data = snapshot.to_dict() or {}
    return {
        "entity_type": data.get("entity_type"),
        "item_id": data.get("item_id"),
        "completed_at": _epoch(data.get("completed_at")),
        "is_completed": data.get("is_completed", True),
        "rating": data.get("rating"),
        "comment": data.get("comment"),
        "metadata": data.get("metadata", {}),
    }


class FirestoreService:
    """Firestore-backed persistence for user profiles, queues, and completions.

    When FIRESTORE_EMULATOR_HOST is set in the environment, the client library
    connects to the emulator with anonymous credentials — no branching on
    environment is needed here.
    """

    def __init__(self, client: Optional[firestore.Client] = None):
        self.db = client or firestore.Client(project=settings.GCP_PROJECT_ID)

    def _user_doc(self, user_id: str):
        return self.db.collection(USERS_COLLECTION).document(user_id)

    def create_or_update_user(
        self,
        user_id: str,
        provider_sub: str,
        auth_provider: str,
        email: Optional[str] = None,
        name: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Creates or updates a user profile document."""
        payload: Dict[str, Any] = {
            "provider_sub": provider_sub,
            "auth_provider": auth_provider,
        }
        if email:
            payload["email"] = email
        if name:
            payload["display_name"] = name

        try:
            # merge=True mirrors DynamoDB's UpdateExpression: fields absent from
            # this write are left untouched rather than erased.
            self._user_doc(user_id).set(payload, merge=True)
            return self.get_user_profile(user_id)
        except DATABASE_ERRORS as e:
            print(f"Firestore user creation error: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Database error during user profile write: {str(e)}",
            )

    def get_user_profile(self, user_id: str) -> Dict[str, Any]:
        """Retrieves a user's profile document, or {} if absent."""
        try:
            snapshot = self._user_doc(user_id).get()
            return snapshot.to_dict() or {}
        except DATABASE_ERRORS as e:
            print(f"Firestore fetch profile error: {e}")
            return {}

    def save_spotify_tokens(
        self, user_id: str, access_token: str, refresh_token: str, expires_in: int
    ) -> None:
        """Caches Spotify API tokens on the user profile."""
        expires_at = int(time.time()) + expires_in
        try:
            self._user_doc(user_id).set(
                {
                    "spotify_access_token": access_token,
                    "spotify_refresh_token": refresh_token,
                    "spotify_token_expires_at": expires_at,
                    "spotify_linked": True,
                },
                merge=True,
            )
        except DATABASE_ERRORS as e:
            print(f"Firestore save Spotify tokens error: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to link Spotify account credentials.",
            )

    def _queue_collection(self, user_id: str):
        return self._user_doc(user_id).collection(QUEUE_COLLECTION)

    def _completed_collection(self, user_id: str):
        return self._user_doc(user_id).collection(COMPLETED_COLLECTION)

    def add_item_to_queue(
        self, user_id: str, item_id: str, entity_type: str, metadata: Dict[str, Any]
    ) -> None:
        """Adds a media item to the user's active queue."""
        try:
            self._queue_collection(user_id).document(
                _doc_id(entity_type, item_id)
            ).set(
                {
                    "entity_type": entity_type.lower(),
                    "item_id": item_id,
                    "added_at": firestore.SERVER_TIMESTAMP,
                    "is_completed": False,
                    "metadata": metadata,
                }
            )
        except DATABASE_ERRORS as e:
            print(f"Firestore add queue item error: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to add item to your active list.",
            )

    def get_active_queue(
        self, user_id: str, entity_type: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """Retrieves the user's active queue, optionally filtered by media type."""
        try:
            query = self._queue_collection(user_id)
            if entity_type:
                query = query.where(
                    filter=FieldFilter("entity_type", "==", entity_type.lower())
                )
            return [_map_queue_item(doc) for doc in query.stream()]
        except DATABASE_ERRORS as e:
            print(f"Firestore fetch queue error: {e}")
            return []

    def log_item_completed(
        self, user_id: str, item_id: str, entity_type: str, rating: int, comment: str
    ) -> None:
        """Moves an active queue item into the completed log.

        The create and the delete run in a single batch, so a failure cannot
        leave the item present in both lists.
        """
        doc_id = _doc_id(entity_type, item_id)
        queue_ref = self._queue_collection(user_id).document(doc_id)
        completed_ref = self._completed_collection(user_id).document(doc_id)

        try:
            queue_snapshot = queue_ref.get()
            if not queue_snapshot.exists:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Item was not found in your active queue.",
                )

            queue_data = queue_snapshot.to_dict() or {}

            batch = self.db.batch()
            batch.set(
                completed_ref,
                {
                    "entity_type": entity_type.lower(),
                    "item_id": item_id,
                    "completed_at": firestore.SERVER_TIMESTAMP,
                    "is_completed": True,
                    "rating": rating,
                    "comment": comment,
                    "metadata": queue_data.get("metadata", {}),
                },
            )
            batch.delete(queue_ref)
            batch.commit()
        except HTTPException:
            raise
        except DATABASE_ERRORS as e:
            print(f"Firestore complete item error: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to record completion.",
            )

    def get_completed_list(
        self, user_id: str, entity_type: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """Fetches all completed items logged by the user."""
        try:
            query = self._completed_collection(user_id)
            if entity_type:
                query = query.where(
                    filter=FieldFilter("entity_type", "==", entity_type.lower())
                )
            return [_map_completed_item(doc) for doc in query.stream()]
        except DATABASE_ERRORS as e:
            print(f"Firestore fetch completions error: {e}")
            return []

    def delete_item(
        self, user_id: str, item_id: str, entity_type: str, queue_only: bool = True
    ) -> None:
        """Deletes an item from either the active queue or the completed log."""
        collection = (
            self._queue_collection(user_id)
            if queue_only
            else self._completed_collection(user_id)
        )
        try:
            collection.document(_doc_id(entity_type, item_id)).delete()
        except DATABASE_ERRORS as e:
            print(f"Firestore delete item error: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to delete the item.",
            )
