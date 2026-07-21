import time
from typing import Any, Dict, Optional

from fastapi import HTTPException, status
from google.api_core.exceptions import GoogleAPIError
from google.cloud import firestore

from app.config import settings

USERS_COLLECTION = "users"


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
        except GoogleAPIError as e:
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
        except GoogleAPIError as e:
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
        except GoogleAPIError as e:
            print(f"Firestore save Spotify tokens error: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to link Spotify account credentials.",
            )
