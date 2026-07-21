from fastapi import APIRouter, Depends, HTTPException, status
from app.models.user import AppleLoginRequest, Auth0LoginRequest, UserSessionResponse, SpotifyConnectRequest, SpotifyStatusResponse
from app.auth.apple import verify_apple_token
from app.auth.auth0 import verify_auth0_token
from app.auth.jwt import create_session_token, get_current_user_id
from app.dependencies import get_db
from app.services.firestore import FirestoreService
from app.services.spotify import spotify_service
import hashlib

router = APIRouter()

@router.post("/apple", response_model=UserSessionResponse)
async def login_with_apple(request: AppleLoginRequest, db: FirestoreService = Depends(get_db)):
    """
    Endpoint validating a Sign in with Apple Identity Token.
    Establishes/fetches a user profile in Firestore and returns a session JWT.
    """
    # 1. Cryptographically verify the Apple identity token
    claims = await verify_apple_token(request.identity_token, request.client_id)
    
    # 2. Extract stable Apple user identifier
    apple_sub = claims.get("sub")
    email = claims.get("email") or request.email
    
    # Generate a stable database user ID by hashing the Apple sub identifier
    # This keeps user IDs consistent, short, and URL-safe
    user_id = hashlib.sha256(apple_sub.encode()).hexdigest()[:20]
    
    # Handle optional names received during initial sign up
    first_name = request.given_name or claims.get("given_name", "")
    last_name = request.family_name or claims.get("family_name", "")
    display_name = f"{first_name} {last_name}".strip() or email or "User"
    
    # 3. Create or update user profile item in Firestore
    profile = db.create_or_update_user(
        user_id=user_id,
        provider_sub=apple_sub,
        auth_provider="apple",
        email=email,
        name=display_name
    )
    
    # 4. Generate backend session token
    session_jwt = create_session_token(user_id=user_id, email=email)
    
    return UserSessionResponse(
        access_token=session_jwt,
        user_id=user_id,
        email=email,
        spotify_linked=profile.get("spotify_linked", False)
    )

@router.post("/auth0", response_model=UserSessionResponse)
async def login_with_auth0(request: Auth0LoginRequest, db: FirestoreService = Depends(get_db)):
    """
    Validates an Auth0 ID Token and returns a session JWT.
    Creates or updates the user profile in Firestore on first login.
    """
    claims = await verify_auth0_token(request.identity_token)

    auth0_sub = claims.get("sub")
    if not auth0_sub:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing subject claim")
    email = claims.get("email")
    name = claims.get("name", "")

    user_id = hashlib.sha256(auth0_sub.encode()).hexdigest()[:20]

    profile = db.create_or_update_user(
        user_id=user_id,
        provider_sub=auth0_sub,
        auth_provider="auth0",
        email=email,
        name=name
    )

    session_jwt = create_session_token(user_id=user_id, email=email)

    return UserSessionResponse(
        access_token=session_jwt,
        user_id=user_id,
        email=email,
        spotify_linked=profile.get("spotify_linked", False)
    )

@router.post("/spotify/connect", response_model=SpotifyStatusResponse)
async def connect_spotify(request: SpotifyConnectRequest, user_id: str = Depends(get_current_user_id)):
    """
    Links a user's account to their Spotify account by exchanging a code for tokens.
    """
    result = await spotify_service.exchange_auth_code(
        user_id=user_id,
        code=request.code,
        redirect_uri=request.redirect_uri
    )
    return SpotifyStatusResponse(
        spotify_linked=True,
        display_name=result.get("display_name")
    )

@router.get("/spotify/status", response_model=SpotifyStatusResponse)
async def get_spotify_connection_status(user_id: str = Depends(get_current_user_id), db: FirestoreService = Depends(get_db)):
    """
    Check if the authenticated user has a Spotify account connected.
    """
    profile = db.get_user_profile(user_id)
    linked = profile.get("spotify_linked", False)
    
    display_name = None
    if linked:
        # Obtain user token to verify / pull name from profile
        try:
            token = await spotify_service.get_user_token(user_id)
            display_name = await spotify_service.fetch_spotify_display_name(token)
        except Exception:
            pass
            
    return SpotifyStatusResponse(
        spotify_linked=linked,
        display_name=display_name
    )
