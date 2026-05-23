from pydantic import BaseModel, EmailStr
from typing import Optional

class AppleLoginRequest(BaseModel):
    identity_token: str
    client_id: str  # Bundle Identifier (e.g., com.b1codes.ListenList)
    email: Optional[EmailStr] = None
    given_name: Optional[str] = None
    family_name: Optional[str] = None

class UserSessionResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: str
    email: Optional[str] = None
    spotify_linked: bool = False

class SpotifyConnectRequest(BaseModel):
    code: str
    redirect_uri: Optional[str] = None

class SpotifyStatusResponse(BaseModel):
    spotify_linked: bool
    display_name: Optional[str] = None
