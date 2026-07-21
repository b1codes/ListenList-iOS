import os
from unittest.mock import patch

import httpx
import pytest
from google.api_core.exceptions import GoogleAPIError
from google.auth.exceptions import RefreshError
from google.cloud import firestore
from google.cloud.firestore_v1.batch import WriteBatch
from google.cloud.firestore_v1.collection import CollectionReference

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


def test_relogin_preserves_spotify_tokens(service):
    """Verify re-login doesn't erase Spotify tokens when merge=True."""
    # Create initial user
    service.create_or_update_user(
        user_id="u1",
        provider_sub="s",
        auth_provider="auth0",
        email="user@example.com",
    )

    # Link Spotify account
    service.save_spotify_tokens(
        user_id="u1",
        access_token="spotify_at",
        refresh_token="spotify_rt",
        expires_in=3600,
    )

    # Simulate re-login: call create_or_update_user again without Spotify fields
    profile = service.create_or_update_user(
        user_id="u1",
        provider_sub="s",
        auth_provider="auth0",
        email="user@example.com",
    )

    # Verify Spotify fields survived the re-login call
    assert profile["spotify_access_token"] == "spotify_at"
    assert profile["spotify_refresh_token"] == "spotify_rt"
    assert profile["spotify_linked"] is True
    assert profile["spotify_token_expires_at"] > 0


def test_add_item_to_queue_round_trips(service):
    service.add_item_to_queue(
        user_id="u1",
        item_id="song123",
        entity_type="song",
        metadata={"name": "Test Song"},
    )

    items = service.get_active_queue("u1")

    assert len(items) == 1
    assert items[0]["item_id"] == "song123"
    assert items[0]["entity_type"] == "song"
    assert items[0]["metadata"] == {"name": "Test Song"}
    assert items[0]["is_completed"] is False
    assert items[0]["added_at"] > 0


def test_get_active_queue_filters_by_entity_type(service):
    service.add_item_to_queue("u1", "s1", "song", {})
    service.add_item_to_queue("u1", "a1", "album", {})

    songs = service.get_active_queue("u1", entity_type="song")

    assert len(songs) == 1
    assert songs[0]["item_id"] == "s1"


def test_get_active_queue_is_scoped_to_one_user(service):
    service.add_item_to_queue("u1", "s1", "song", {})
    service.add_item_to_queue("u2", "s2", "song", {})

    assert len(service.get_active_queue("u1")) == 1


def test_adding_the_same_item_twice_upserts(service):
    service.add_item_to_queue("u1", "s1", "song", {"name": "First"})
    service.add_item_to_queue("u1", "s1", "song", {"name": "Second"})

    items = service.get_active_queue("u1")

    assert len(items) == 1
    assert items[0]["metadata"]["name"] == "Second"


def test_entity_type_casing_does_not_duplicate(service):
    service.add_item_to_queue("u1", "s1", "song", {})
    service.add_item_to_queue("u1", "s1", "SONG", {})

    assert len(service.get_active_queue("u1")) == 1


def test_get_active_queue_unknown_user_returns_empty_list(service):
    assert service.get_active_queue("nobody") == []


def test_queue_response_omits_storage_keys(service):
    service.add_item_to_queue("u1", "s1", "song", {})

    item = service.get_active_queue("u1")[0]

    assert set(item.keys()) == {
        "entity_type",
        "item_id",
        "added_at",
        "is_completed",
        "metadata",
    }


from fastapi import HTTPException


def test_log_item_completed_moves_item_between_collections(service):
    service.add_item_to_queue("u1", "s1", "song", {"name": "Song"})

    service.log_item_completed("u1", "s1", "song", rating=5, comment="Great")

    assert service.get_active_queue("u1") == []
    completed = service.get_completed_list("u1")
    assert len(completed) == 1
    assert completed[0]["item_id"] == "s1"
    assert completed[0]["rating"] == 5
    assert completed[0]["comment"] == "Great"
    assert completed[0]["is_completed"] is True
    assert completed[0]["completed_at"] > 0


def test_log_item_completed_preserves_metadata(service):
    service.add_item_to_queue("u1", "s1", "song", {"name": "Song"})

    service.log_item_completed("u1", "s1", "song", rating=4, comment="")

    assert service.get_completed_list("u1")[0]["metadata"] == {"name": "Song"}


def test_log_item_completed_missing_item_raises_404(service):
    with pytest.raises(HTTPException) as exc_info:
        service.log_item_completed("u1", "ghost", "song", rating=5, comment="")

    assert exc_info.value.status_code == 404


def test_failed_completion_leaves_both_collections_unchanged(service):
    """A failed batch commit must not move the item into either state.

    The fault only fires when a single commit carries more than one queued
    write, which is exactly the shape of the atomic batch in
    log_item_completed (one set + one delete, committed together). A single
    DocumentReference.set() or .delete() call commits just one write and
    would sail through untouched, so if this code ever regressed to
    sequential set()/delete() calls, this fault would never trigger, the
    call would succeed instead of raising, and this test would fail --
    that's the point: it proves the test is anchored to the real batch.
    """
    service.add_item_to_queue("u1", "s1", "song", {"name": "Song"})
    real_commit = WriteBatch.commit

    def commit_or_fail(self, *args, **kwargs):
        if len(self._write_pbs) > 1:
            raise GoogleAPIError("boom")
        return real_commit(self, *args, **kwargs)

    with patch.object(WriteBatch, "commit", commit_or_fail):
        with pytest.raises(HTTPException) as exc_info:
            service.log_item_completed("u1", "s1", "song", rating=5, comment="Great")

    assert exc_info.value.status_code == 500

    items = service.get_active_queue("u1")
    assert len(items) == 1
    assert items[0]["item_id"] == "s1"
    assert service.get_completed_list("u1") == []


def test_get_completed_list_filters_by_entity_type(service):
    service.add_item_to_queue("u1", "s1", "song", {})
    service.add_item_to_queue("u1", "a1", "album", {})
    service.log_item_completed("u1", "s1", "song", rating=5, comment="")
    service.log_item_completed("u1", "a1", "album", rating=3, comment="")

    albums = service.get_completed_list("u1", entity_type="album")

    assert len(albums) == 1
    assert albums[0]["item_id"] == "a1"


def test_get_completed_list_unknown_user_returns_empty_list(service):
    assert service.get_completed_list("nobody") == []


def test_completed_response_omits_storage_keys(service):
    service.add_item_to_queue("u1", "s1", "song", {})
    service.log_item_completed("u1", "s1", "song", rating=5, comment="ok")

    item = service.get_completed_list("u1")[0]

    assert set(item.keys()) == {
        "entity_type",
        "item_id",
        "completed_at",
        "is_completed",
        "rating",
        "comment",
        "metadata",
    }


def test_delete_item_removes_from_queue(service):
    service.add_item_to_queue("u1", "s1", "song", {})

    service.delete_item("u1", "s1", "song", queue_only=True)

    assert service.get_active_queue("u1") == []


def test_delete_item_removes_from_completed(service):
    service.add_item_to_queue("u1", "s1", "song", {})
    service.log_item_completed("u1", "s1", "song", rating=5, comment="")

    service.delete_item("u1", "s1", "song", queue_only=False)

    assert service.get_completed_list("u1") == []


def test_delete_item_queue_only_leaves_completed_untouched(service):
    service.add_item_to_queue("u1", "s1", "song", {})
    service.log_item_completed("u1", "s1", "song", rating=5, comment="")

    service.delete_item("u1", "s1", "song", queue_only=True)

    assert len(service.get_completed_list("u1")) == 1


def test_delete_item_missing_document_does_not_raise(service):
    # Firestore deletes are idempotent; deleting nothing is not an error.
    service.delete_item("u1", "ghost", "song", queue_only=True)


# --- Finding A: malformed item_id/entity_type must 400, not 500 ---------


def test_add_item_to_queue_rejects_slash_in_item_id(service):
    with pytest.raises(HTTPException) as exc_info:
        service.add_item_to_queue("u1", "a/b", "song", {})

    assert exc_info.value.status_code == 400


def test_add_item_to_queue_rejects_reserved_pattern(service):
    with pytest.raises(HTTPException) as exc_info:
        service.add_item_to_queue("u1", "__proto__", "song", {})

    assert exc_info.value.status_code == 400


def test_add_item_to_queue_rejects_empty_item_id(service):
    with pytest.raises(HTTPException) as exc_info:
        service.add_item_to_queue("u1", "", "song", {})

    assert exc_info.value.status_code == 400


def test_add_item_to_queue_rejects_whitespace_only_item_id(service):
    with pytest.raises(HTTPException) as exc_info:
        service.add_item_to_queue("u1", "   ", "song", {})

    assert exc_info.value.status_code == 400


def test_add_item_to_queue_rejects_overlong_item_id(service):
    with pytest.raises(HTTPException) as exc_info:
        service.add_item_to_queue("u1", "x" * 1001, "song", {})

    assert exc_info.value.status_code == 400


def test_add_item_to_queue_accepts_normal_spotify_id(service):
    # A real Spotify ID must still sail through unaffected by the new checks.
    service.add_item_to_queue(
        "u1", "4cOdK2wGLETKBW3PvgPWqT", "song", {"name": "Test Song"}
    )

    items = service.get_active_queue("u1")

    assert len(items) == 1
    assert items[0]["item_id"] == "4cOdK2wGLETKBW3PvgPWqT"


def test_delete_item_rejects_slash_in_item_id(service):
    # Proves the validation lives in the shared _doc_id helper, not just in
    # add_item_to_queue.
    with pytest.raises(HTTPException) as exc_info:
        service.delete_item("u1", "a/b", "song", queue_only=True)

    assert exc_info.value.status_code == 400


def test_delete_item_rejects_reserved_pattern(service):
    with pytest.raises(HTTPException) as exc_info:
        service.delete_item("u1", "__proto__", "song", queue_only=True)

    assert exc_info.value.status_code == 400


def test_delete_item_rejects_empty_item_id(service):
    with pytest.raises(HTTPException) as exc_info:
        service.delete_item("u1", "", "song", queue_only=True)

    assert exc_info.value.status_code == 400


def test_delete_item_rejects_overlong_item_id(service):
    with pytest.raises(HTTPException) as exc_info:
        service.delete_item("u1", "x" * 1001, "song", queue_only=True)

    assert exc_info.value.status_code == 400


# --- Finding B: google.auth errors on read paths must degrade to empty ----


def test_get_active_queue_degrades_to_empty_list_on_auth_error(service):
    """A revoked or clock-skewed credential must not surface as a 500.

    google.auth errors (RefreshError, DefaultCredentialsError, TransportError)
    are disjoint from google.api_core's GoogleAPIError, so the read path must
    explicitly widen its except clause to catch them too.
    """
    service.add_item_to_queue("u1", "s1", "song", {})

    with patch.object(
        CollectionReference, "stream", side_effect=RefreshError("boom")
    ):
        assert service.get_active_queue("u1") == []
