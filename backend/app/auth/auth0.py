import jwt
import httpx
from fastapi import HTTPException, status
from app.config import settings


async def verify_auth0_token(identity_token: str) -> dict:
    """
    Validates an Auth0 ID Token (RS256 JWT) sent by the iOS client.
    Verifies signature against Auth0's JWKS, issuer, audience, and expiry.
    Returns decoded token claims on success.
    """
    try:
        headers = jwt.get_unverified_header(identity_token)
        kid = headers.get("kid")
        if not kid:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token headers: missing 'kid'"
            )

        jwks_url = f"https://{settings.AUTH0_DOMAIN}/.well-known/jwks.json"
        async with httpx.AsyncClient() as client:
            response = await client.get(jwks_url)
            if response.status_code != 200:
                raise HTTPException(
                    status_code=status.HTTP_502_BAD_GATEWAY,
                    detail="Failed to fetch Auth0 public keys"
                )
            auth0_keys = response.json().get("keys", [])

        jwk = next((key for key in auth0_keys if key.get("kid") == kid), None)
        if not jwk:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Matching Auth0 public key not found"
            )

        public_key = jwt.algorithms.RSAAlgorithm.from_jwk(jwk)
        decoded_token = jwt.decode(
            identity_token,
            public_key,
            algorithms=["RS256"],
            audience=settings.AUTH0_CLIENT_ID,
            issuer=f"https://{settings.AUTH0_DOMAIN}/",
            options={"verify_exp": True}
        )
        return decoded_token

    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Auth0 identity token has expired"
        )
    except jwt.InvalidTokenError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid Auth0 identity token: {str(e)}"
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Auth0 token verification failed: {str(e)}"
        )
