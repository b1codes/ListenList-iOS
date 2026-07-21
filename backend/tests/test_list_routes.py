import pytest
from fastapi.testclient import TestClient

from app.auth.jwt import get_current_user_id
from app.dependencies import get_db
from app.main import app

TEST_USER = "test-user-1"


class FakeDatabase:
    """In-memory stand-in for FirestoreService, recording calls for assertions."""

    def __init__(self):
        self.queue = []
        self.completed = []
        self.calls = []

    def get_active_queue(self, user_id, entity_type=None):
        self.calls.append(("get_active_queue", user_id, entity_type))
        return self.queue

    def add_item_to_queue(self, user_id, item_id, entity_type, metadata):
        self.calls.append(("add_item_to_queue", user_id, item_id, entity_type, metadata))

    def delete_item(self, user_id, item_id, entity_type, queue_only=True):
        self.calls.append(("delete_item", user_id, item_id, entity_type, queue_only))

    def log_item_completed(self, user_id, item_id, entity_type, rating, comment):
        self.calls.append(
            ("log_item_completed", user_id, item_id, entity_type, rating, comment)
        )

    def get_completed_list(self, user_id, entity_type=None):
        self.calls.append(("get_completed_list", user_id, entity_type))
        return self.completed


@pytest.fixture
def fake_db():
    return FakeDatabase()


@pytest.fixture
def client(fake_db):
    app.dependency_overrides[get_db] = lambda: fake_db
    app.dependency_overrides[get_current_user_id] = lambda: TEST_USER
    yield TestClient(app)
    app.dependency_overrides.clear()


def test_get_active_queue_returns_items(client, fake_db):
    fake_db.queue = [
        {
            "entity_type": "song",
            "item_id": "s1",
            "added_at": 1784494491,
            "is_completed": False,
            "metadata": {},
        }
    ]

    response = client.get("/list/active")

    assert response.status_code == 200
    assert response.json() == {"items": fake_db.queue}


def test_get_active_queue_passes_entity_type_filter(client, fake_db):
    client.get("/list/active?entity_type=song")

    assert ("get_active_queue", TEST_USER, "song") in fake_db.calls


def test_add_to_queue_forwards_payload(client, fake_db):
    response = client.post(
        "/list/active",
        json={"id": "s1", "entity_type": "song", "metadata": {"name": "Song"}},
    )

    assert response.status_code == 201
    assert (
        "add_item_to_queue",
        TEST_USER,
        "s1",
        "song",
        {"name": "Song"},
    ) in fake_db.calls


def test_delete_from_queue_sets_queue_only_true(client, fake_db):
    response = client.delete("/list/active/song/s1")

    assert response.status_code == 200
    assert ("delete_item", TEST_USER, "s1", "song", True) in fake_db.calls


def test_delete_from_completed_sets_queue_only_false(client, fake_db):
    response = client.delete("/list/completed/song/s1")

    assert response.status_code == 200
    assert ("delete_item", TEST_USER, "s1", "song", False) in fake_db.calls


def test_log_completion_forwards_rating_and_comment(client, fake_db):
    response = client.post(
        "/list/active/song/s1/complete",
        json={"rating": 5, "comment": "Great"},
    )

    assert response.status_code == 200
    assert (
        "log_item_completed",
        TEST_USER,
        "s1",
        "song",
        5,
        "Great",
    ) in fake_db.calls


def test_get_completed_history_returns_items(client, fake_db):
    fake_db.completed = [
        {
            "entity_type": "song",
            "item_id": "s1",
            "completed_at": 1784494491,
            "is_completed": True,
            "rating": 5,
            "comment": "ok",
            "metadata": {},
        }
    ]

    response = client.get("/list/completed")

    assert response.status_code == 200
    assert response.json() == {"items": fake_db.completed}


def test_invalid_rating_is_rejected(client, fake_db):
    # CompletionLogRequest constrains rating to 1..5.
    response = client.post(
        "/list/active/song/s1/complete",
        json={"rating": 9, "comment": ""},
    )

    assert response.status_code == 422
