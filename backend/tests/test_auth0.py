import base64
import json
import pytest
from fastapi import HTTPException
from pytest_httpx import HTTPXMock


def _encode_b64url(obj: dict) -> str:
    return base64.urlsafe_b64encode(json.dumps(obj).encode()).rstrip(b"=").decode()


def make_jwt(payload: dict, kid: str | None = None) -> str:
    header = {"alg": "RS256", "typ": "JWT"}
    if kid:
        header["kid"] = kid
    return f"{_encode_b64url(header)}.{_encode_b64url(payload)}.fakesig"


async def test_missing_kid_raises_401():
    from app.auth.auth0 import verify_auth0_token
    token = make_jwt({"sub": "auth0|123"})  # no kid
    with pytest.raises(HTTPException) as exc_info:
        await verify_auth0_token(token)
    assert exc_info.value.status_code == 401
    assert "kid" in exc_info.value.detail


async def test_jwks_fetch_failure_raises_502(httpx_mock: HTTPXMock):
    from app.auth.auth0 import verify_auth0_token
    httpx_mock.add_response(status_code=500)
    token = make_jwt({"sub": "auth0|123"}, kid="key1")
    with pytest.raises(HTTPException) as exc_info:
        await verify_auth0_token(token)
    assert exc_info.value.status_code == 502


async def test_no_matching_key_raises_401(httpx_mock: HTTPXMock):
    from app.auth.auth0 import verify_auth0_token
    httpx_mock.add_response(json={"keys": [{"kid": "other-key", "kty": "RSA"}]})
    token = make_jwt({"sub": "auth0|123"}, kid="key1")
    with pytest.raises(HTTPException) as exc_info:
        await verify_auth0_token(token)
    assert exc_info.value.status_code == 401
    assert "Matching" in exc_info.value.detail
