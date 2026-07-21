import httpx
import time
from fastapi import HTTPException, status
from app.config import settings
from app.dependencies import get_db
from typing import Dict, Any, Optional

SPOTIFY_TOKEN_URL = "https://accounts.spotify.com/api/token"
SPOTIFY_API_BASE = "https://api.spotify.com/v1"

class SpotifyService:
    async def get_client_credentials_token(self) -> str:
        """
        Obtains a server-to-server Spotify access token. Used for non-user-scoped queries.
        """
        if not settings.SPOTIFY_CLIENT_ID or not settings.SPOTIFY_CLIENT_SECRET:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Spotify API credentials are not configured on the backend."
            )

        async with httpx.AsyncClient() as client:
            response = await client.post(
                SPOTIFY_TOKEN_URL,
                data={"grant_type": "client_credentials"},
                auth=(settings.SPOTIFY_CLIENT_ID, settings.SPOTIFY_CLIENT_SECRET)
            )
            if response.status_code != 200:
                raise HTTPException(
                    status_code=status.HTTP_502_BAD_GATEWAY,
                    detail=f"Spotify credentials token exchange failed: {response.text}"
                )
            return response.json().get("access_token")

    async def get_user_token(self, user_id: str) -> str:
        """
        Retrieves a user's cached Spotify access token. 
        Automatically refreshes it and saves to DynamoDB if it is expired.
        """
        profile = get_db().get_user_profile(user_id)
        if not profile or not profile.get("spotify_linked"):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User has not linked their Spotify account."
            )

        access_token = profile.get("spotify_access_token")
        refresh_token = profile.get("spotify_refresh_token")
        expires_at = profile.get("spotify_token_expires_at", 0)

        # If token is still valid (with a 60-second safety margin), return it
        if int(time.time()) < (expires_at - 60):
            return access_token

        # Token is expired, perform refresh
        return await self.refresh_user_token(user_id, refresh_token)

    async def refresh_user_token(self, user_id: str, refresh_token: str) -> str:
        """
        Refreshes a user's Spotify access token using their refresh token.
        """
        if not settings.SPOTIFY_CLIENT_ID or not settings.SPOTIFY_CLIENT_SECRET:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Spotify API credentials are not configured."
            )

        async with httpx.AsyncClient() as client:
            response = await client.post(
                SPOTIFY_TOKEN_URL,
                data={
                    "grant_type": "refresh_token",
                    "refresh_token": refresh_token
                },
                auth=(settings.SPOTIFY_CLIENT_ID, settings.SPOTIFY_CLIENT_SECRET)
            )
            if response.status_code != 200:
                # If refresh token has been revoked, unlink account
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Spotify access revoked. Please re-link your Spotify account."
                )

            data = response.json()
            new_access_token = data.get("access_token")
            # Spotify might not return a new refresh token; fallback to existing
            new_refresh_token = data.get("refresh_token", refresh_token)
            expires_in = data.get("expires_in", 3600)

            # Update cache in DynamoDB
            get_db().save_spotify_tokens(user_id, new_access_token, new_refresh_token, expires_in)
            return new_access_token

    async def exchange_auth_code(self, user_id: str, code: str, redirect_uri: Optional[str] = None) -> Dict[str, Any]:
        """
        Exchanges an OAuth authorization code for Spotify Access and Refresh Tokens.
        Saves tokens in the user profile.
        """
        if not settings.SPOTIFY_CLIENT_ID or not settings.SPOTIFY_CLIENT_SECRET:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Spotify API credentials are not configured."
            )

        uri = redirect_uri or settings.SPOTIFY_REDIRECT_URI

        async with httpx.AsyncClient() as client:
            response = await client.post(
                SPOTIFY_TOKEN_URL,
                data={
                    "grant_type": "authorization_code",
                    "code": code,
                    "redirect_uri": uri
                },
                auth=(settings.SPOTIFY_CLIENT_ID, settings.SPOTIFY_CLIENT_SECRET)
            )
            if response.status_code != 200:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Spotify token exchange failed: {response.text}"
                )

            data = response.json()
            access_token = data.get("access_token")
            refresh_token = data.get("refresh_token")
            expires_in = data.get("expires_in", 3600)

            # Cache in database
            get_db().save_spotify_tokens(user_id, access_token, refresh_token, expires_in)
            
            # Fetch user profile to verify connection and get display name
            display_name = await self.fetch_spotify_display_name(access_token)
            
            return {
                "spotify_linked": True,
                "display_name": display_name
            }

    async def fetch_spotify_display_name(self, access_token: str) -> Optional[str]:
        """
        Fetches user profile details directly from Spotify.
        """
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{SPOTIFY_API_BASE}/me",
                    headers={"Authorization": f"Bearer {access_token}"}
                )
                if response.status_code == 200:
                    return response.json().get("display_name")
        except Exception:
            pass
        return None

    async def search(self, user_id: str, query: str, type_str: str, limit: int = 20, offset: int = 0) -> Dict[str, Any]:
        """
        Executes a proxy search against Spotify. Uses user credentials if linked, fallback to client credentials.
        """
        # Attempt to get user-specific token (for personalized results)
        try:
            token = await self.get_user_token(user_id)
        except Exception:
            # Fallback to general client credentials token
            token = await self.get_client_credentials_token()

        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{SPOTIFY_API_BASE}/search",
                params={
                    "q": query,
                    "type": type_str,
                    "limit": limit,
                    "offset": offset
                },
                headers={"Authorization": f"Bearer {token}"}
            )
            if response.status_code != 200:
                raise HTTPException(
                    status_code=response.status_code,
                    detail=f"Spotify search failed: {response.text}"
                )
            return response.json()

spotify_service = SpotifyService()
