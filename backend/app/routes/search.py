from fastapi import APIRouter, Depends, Query
from app.auth.jwt import get_current_user_id
from app.services.spotify import spotify_service
from typing import Optional

router = APIRouter()

@router.get("")
async def search_spotify(
    q: str = Query(..., description="The query string to search for"),
    type: str = Query("track,album,artist,show,audiobook", description="Comma-separated list of item types to search for (track, album, artist, show, audiobook)"),
    limit: int = Query(20, ge=1, le=50, description="Number of results to return"),
    offset: int = Query(0, ge=0, description="Offset for pagination"),
    user_id: str = Depends(get_current_user_id)
):
    """
    Proxies a search query securely to the Spotify Web API.
    Uses the user's Spotify authorization details if available, otherwise falls back to server-side Client Credentials.
    """
    # Standardize our custom iOS media types to Spotify types
    # e.g., 'song' -> 'track', 'podcast' -> 'show'
    spotify_types = []
    for t in type.split(","):
        t_clean = t.strip().lower()
        if t_clean == "song":
            spotify_types.append("track")
        elif t_clean == "podcast":
            spotify_types.append("show")
        else:
            spotify_types.append(t_clean)
            
    api_types = ",".join(spotify_types)
    
    results = await spotify_service.search(
        user_id=user_id,
        query=q,
        type_str=api_types,
        limit=limit,
        offset=offset
    )
    
    return results
