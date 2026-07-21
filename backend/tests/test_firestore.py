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
