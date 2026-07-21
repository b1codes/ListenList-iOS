from unittest.mock import AsyncMock, patch
from fastapi.testclient import TestClient
from app.main import app
from app.dependencies import get_db

client = TestClient(app)

_MOCK_CLAIMS = {
    "sub": "auth0|test_user_123",
    "email": "user@example.com",
    "name": "Test User",
}
_MOCK_PROFILE = {"spotify_linked": False}


class _NullDatabase:
    """Dependency-injection stand-in for tests that never reach the database.

    FastAPI resolves ``Depends(get_db)`` for every request to this route
    regardless of what the handler body does, so even tests whose assertions
    never touch persistence must override it — otherwise the endpoint tries
    to construct a real FirestoreService and fails on missing credentials
    when no emulator is configured.
    """


def test_auth0_login_returns_session_token():
    class _FakeDatabase:
        def create_or_update_user(self, **kwargs):
            return _MOCK_PROFILE

    app.dependency_overrides[get_db] = _FakeDatabase
    try:
        with patch("app.routes.auth.verify_auth0_token", new_callable=AsyncMock, return_value=_MOCK_CLAIMS), \
             patch("app.routes.auth.create_session_token", return_value="my.session.jwt"):

            response = client.post("/auth/auth0", json={"identity_token": "fake.id.token"})
    finally:
        app.dependency_overrides.clear()

    assert response.status_code == 200
    body = response.json()
    assert body["access_token"] == "my.session.jwt"
    assert body["token_type"] == "bearer"
    assert body["email"] == "user@example.com"
    assert body["spotify_linked"] is False
    assert len(body["user_id"]) == 20  # sha256 hex[:20]


def test_auth0_login_propagates_401_from_verifier():
    from fastapi import HTTPException
    app.dependency_overrides[get_db] = _NullDatabase
    try:
        with patch(
            "app.routes.auth.verify_auth0_token",
            new_callable=AsyncMock,
            side_effect=HTTPException(status_code=401, detail="Expired"),
        ):
            response = client.post("/auth/auth0", json={"identity_token": "bad.token"})
    finally:
        app.dependency_overrides.clear()

    assert response.status_code == 401


def test_auth0_login_missing_body_returns_422():
    app.dependency_overrides[get_db] = _NullDatabase
    try:
        response = client.post("/auth/auth0", json={})
    finally:
        app.dependency_overrides.clear()
    assert response.status_code == 422
