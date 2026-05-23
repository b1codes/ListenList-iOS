import jwt
import httpx
from fastapi import HTTPException, status
from app.config import settings

APPLE_KEYS_URL = "https://appleid.apple.com/auth/keys"
APPLE_ISSUER = "https://appleid.apple.com"

async def verify_apple_token(identity_token: str, client_id: str) -> dict:
    """
    Validates a Sign in with Apple Identity Token (JWT) sent by the iOS client.
    Verifies signature, issuer, audience, and expiration.
    Returns the decoded token claims if successful.
    """
    try:
        # Step 1: Decode headers to retrieve the Key ID (kid)
        headers = jwt.get_unverified_header(identity_token)
        kid = headers.get("kid")
        if not kid:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token headers: missing 'kid'"
            )

        # Step 2: Fetch Apple's public keys
        async with httpx.AsyncClient() as client:
            response = await client.get(APPLE_KEYS_URL)
            if response.status_code != 200:
                raise HTTPException(
                    status_code=status.HTTP_502_BAD_GATEWAY,
                    detail="Failed to fetch Apple public keys"
                )
            apple_keys = response.json().get("keys", [])

        # Step 3: Find the matching public key
        jwk = next((key for key in apple_keys if key.get("kid") == kid), None)
        if not jwk:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Matching Apple public key not found"
            )

        # Step 4: Construct public key and decode token
        public_key = jwt.algorithms.RSAAlgorithm.from_jwk(jwk)
        
        # Verify parameters:
        # - audience (client_id) should match our App ID (e.g. com.b1codes.ListenList)
        # - issuer should match apple id URL
        # - verify token is not expired
        decoded_token = jwt.decode(
            identity_token,
            public_key,
            algorithms=["RS256"],
            audience=client_id,
            issuer=APPLE_ISSUER,
            options={"verify_exp": True}
        )

        return decoded_token

    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Apple identity token has expired"
        )
    except jwt.InvalidTokenError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid Apple identity token: {str(e)}"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Apple token verification failed: {str(e)}"
        )
