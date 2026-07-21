import os

import httpx
import pytest
from google.cloud import firestore

EMULATOR_HOST = os.environ.get("FIRESTORE_EMULATOR_HOST")
TEST_PROJECT = "listenlist-test"

pytestmark = pytest.mark.skipif(
    not EMULATOR_HOST,
    reason=(
        "Firestore emulator not running. Start it with:\n"
        "  gcloud emulators firestore start --host-port=localhost:8080\n"
        "then export FIRESTORE_EMULATOR_HOST=localhost:8080"
    ),
)


@pytest.fixture(scope="session")
def firestore_client():
    """A Firestore client bound to the emulator.

    The client library reads FIRESTORE_EMULATOR_HOST from the environment and
    connects with anonymous credentials, so no GCP account is involved.
    """
    return firestore.Client(project=TEST_PROJECT)


def _clear_emulator_data() -> None:
    """Deletes every document in the emulator's default database."""
    httpx.delete(
        f"http://{EMULATOR_HOST}/emulator/v1/projects/{TEST_PROJECT}"
        f"/databases/(default)/documents"
    )


@pytest.fixture(autouse=True)
def clear_emulator():
    """Wipe all emulator data between tests so each test is independent."""
    yield
    _clear_emulator_data()


def test_emulator_round_trips_a_document(firestore_client):
    firestore_client.collection("smoke").document("d1").set({"value": 42})

    snapshot = firestore_client.collection("smoke").document("d1").get()

    assert snapshot.exists
    assert snapshot.to_dict()["value"] == 42


def test_clearing_removes_all_documents(firestore_client):
    firestore_client.collection("smoke").document("d1").set({"value": 42})

    _clear_emulator_data()

    assert not firestore_client.collection("smoke").document("d1").get().exists


from app.services.firestore import FirestoreService


@pytest.fixture
def service(firestore_client):
    return FirestoreService(client=firestore_client)


def test_create_or_update_user_stores_provider_fields(service):
    profile = service.create_or_update_user(
        user_id="abc",
        provider_sub="auth0|sub123",
        auth_provider="auth0",
        email="user@example.com",
    )

    assert profile["provider_sub"] == "auth0|sub123"
    assert profile["auth_provider"] == "auth0"
    assert profile["email"] == "user@example.com"


def test_create_or_update_user_omits_optional_fields(service):
    profile = service.create_or_update_user(
        user_id="u1",
        provider_sub="sub1",
        auth_provider="auth0",
    )

    assert "email" not in profile
    assert "display_name" not in profile


def test_create_or_update_user_preserves_existing_fields(service):
    service.create_or_update_user(
        user_id="u1", provider_sub="s", auth_provider="auth0", email="a@b.com"
    )

    profile = service.create_or_update_user(
        user_id="u1", provider_sub="s", auth_provider="auth0"
    )

    # A second call without email must not erase the stored one.
    assert profile["email"] == "a@b.com"


def test_get_user_profile_unknown_user_returns_empty_dict(service):
    assert service.get_user_profile("nobody") == {}


def test_save_spotify_tokens_records_tokens_and_expiry(service):
    service.create_or_update_user(
        user_id="u1", provider_sub="s", auth_provider="auth0"
    )

    service.save_spotify_tokens(
        user_id="u1",
        access_token="at",
        refresh_token="rt",
        expires_in=3600,
    )

    profile = service.get_user_profile("u1")
    assert profile["spotify_access_token"] == "at"
    assert profile["spotify_refresh_token"] == "rt"
    assert profile["spotify_linked"] is True
    assert profile["spotify_token_expires_at"] > 0
