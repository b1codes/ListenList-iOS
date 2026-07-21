# Firestore Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the FastAPI backend's DynamoDB persistence layer with Google Cloud Firestore, running against the Firestore Emulator for local development.

**Architecture:** A new `FirestoreService` keeps the exact public method signatures of the deleted `DynamoDBService`, so callers change only in *how they obtain* the service. DynamoDB's single-table `PK`/`SK` layout becomes `users/{id}` documents with `queue/` and `completed/` subcollections. A `get_db()` FastAPI dependency replaces the import-time singleton, making routes testable without a database.

**Tech Stack:** Python 3.13, FastAPI, `google-cloud-firestore`, pytest, gcloud Firestore Emulator.

**Spec:** `docs/superpowers/specs/2026-07-21-firestore-migration-design.md`

## Global Constraints

- **No GCP account is required.** Everything runs against the emulator. Never add steps that create GCP projects, billing accounts, or service-account keys.
- **Do not touch `infra/*.tf`.** Terraform migration is ClickUp task 86bazmf8b.
- **Do not touch the iOS app** (`frontend/`). It talks to Firestore directly and is out of scope.
- **`boto3` stays in `requirements.txt`** — `config.py` still uses it for SSM secret bootstrapping.
- **`AWS_REGION` stays in `Settings`** — SSM still needs it. Only its default value is corrected, to `us-east-2`.
- Public method signatures on `FirestoreService` must match the old `DynamoDBService` exactly.
- Use `where(filter=FieldFilter(...))`. Positional `where("field", "==", value)` is deprecated and emits warnings.
- All work happens on branch `feat/firestore-migration`.
- Run all commands from the `backend/` directory with the venv active: `cd backend && source venv/bin/activate`.

## File Structure

| File | Responsibility |
|---|---|
| `backend/app/services/firestore.py` | **New.** `FirestoreService` + private response mappers. The only module that imports `google.cloud.firestore`. |
| `backend/app/dependencies.py` | **New.** `get_db()` — lazy, cached service construction; the single override point for tests. |
| `backend/app/services/dynamodb.py` | **Deleted.** |
| `backend/app/config.py` | Settings: drop `DYNAMODB_TABLE_NAME`, add `GCP_PROJECT_ID`, fix `AWS_REGION` default. |
| `backend/app/routes/list_routes.py` | 6 routes switch to `Depends(get_db)`. |
| `backend/app/routes/auth.py` | 3 call sites switch to `Depends(get_db)`. |
| `backend/app/services/spotify.py` | 3 call sites switch to in-method `get_db()`. |
| `backend/tests/test_firestore.py` | **New.** Emulator-backed integration tests for `FirestoreService`. |
| `backend/tests/test_list_routes.py` | **New.** Route tests using an in-memory fake; no emulator needed. |
| `backend/tests/test_dynamodb.py` | **Deleted.** |
| `backend/README.md` | **New.** Emulator setup, run, and test instructions. |

**Known interim breakage.** Task 1 removes `DYNAMODB_TABLE_NAME` from `Settings`, but
`dynamodb.py` reads it at construction — so from Task 1 until Task 6 deletes the file,
`test_dynamodb.py` fails at *collection*, which aborts the entire pytest run. Between those
tasks, run the suite as `pytest --ignore=tests/test_dynamodb.py`. Task 6 resolves it by
deleting both files. The Tasks 2-5 constraint "dynamodb.py must keep working" therefore means
"leave the file untouched", not "keep it importable".

**Task order rationale:** Task 1 makes the emulator reachable and provable. Tasks 2–4 build `FirestoreService` incrementally, each verified against the live emulator. Task 5 rewires callers. Task 6 removes DynamoDB. The build is only import-clean again at the end of Task 5 — this is expected, and Task 6 is what proves the whole suite green.

---

### Task 1: Emulator harness, dependencies, and configuration

Sets up everything later tasks need: the emulator installed and running, the client library available, config pointing at the right place, and a smoke test proving a real read/write round-trips.

**Files:**
- Modify: `backend/requirements.txt`
- Modify: `backend/requirements-test.txt`
- Modify: `backend/app/config.py:12-14`
- Create: `backend/README.md`
- Create: `backend/tests/test_firestore.py`

**Interfaces:**
- Consumes: nothing (first task).
- Produces: `backend/tests/test_firestore.py` containing the fixtures `firestore_client` and the autouse `clear_emulator`, plus module-level constants `EMULATOR_HOST` and `TEST_PROJECT`. Tasks 2–4 append tests to this same file and reuse these fixtures.

- [ ] **Step 1: Install the emulator component**

`gcloud` (SDK 576.0.0) and Java 21 are already installed; only the emulator component is missing.

```bash
gcloud components install cloud-firestore-emulator --quiet
```

Verify:

```bash
gcloud components list --filter="id~firestore" --format="value(id,state.name)"
```

Expected: `cloud-firestore-emulator	Installed`

- [ ] **Step 2: Add the client library to requirements**

Add to `backend/requirements.txt` (keep `boto3` — SSM still uses it):

```
google-cloud-firestore>=2.16.0
```

`backend/requirements-test.txt` needs **no change**. The emulator-clearing fixture uses
`httpx`, which is already a runtime dependency.

Install:

```bash
cd backend && source venv/bin/activate && pip install -r requirements.txt -r requirements-test.txt
```

- [ ] **Step 3: Update configuration**

In `backend/app/config.py`, replace the DynamoDB block (currently lines 12-14):

```python
    # DynamoDB Configuration
    DYNAMODB_TABLE_NAME: str = "ListenListTable"
    AWS_REGION: str = "us-east-1"
```

with:

```python
    # Firestore Configuration
    # Under the emulator this project need not exist — it is only a namespace
    # label. It becomes a real GCP project ID once one is created (86bazmf8b).
    GCP_PROJECT_ID: str = "listenlist-dev"

    # AWS region is retained solely for SSM secret bootstrapping below.
    # The infrastructure lives in us-east-2, not us-east-1.
    AWS_REGION: str = "us-east-2"
```

Leave the rest of `config.py` — including the entire SSM bootstrap block — untouched.

- [ ] **Step 4: Write the emulator harness and a smoke test**

Create `backend/tests/test_firestore.py`:

```python
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
```

`test_clearing_removes_all_documents` is not redundant: it proves the wipe the autouse
fixture depends on actually works. Test isolation that silently failed would make every
later task's tests unreliable. It calls `_clear_emulator_data()` directly rather than
asserting on state left by a previous test, so it is order-independent and cannot pass
for the wrong reason.

- [ ] **Step 5: Start the emulator and run the smoke test**

In one terminal:

```bash
gcloud emulators firestore start --host-port=localhost:8080
```

In another:

```bash
cd backend && source venv/bin/activate
export FIRESTORE_EMULATOR_HOST=localhost:8080
pytest tests/test_firestore.py -v
```

Expected: 2 passed.

Then confirm the skip path is clean:

```bash
env -u FIRESTORE_EMULATOR_HOST pytest tests/test_firestore.py -v
```

Expected: 2 skipped, with the "Firestore emulator not running" message.

- [ ] **Step 6: Write the backend README**

Create `backend/README.md`:

````markdown
# ListenList Backend

FastAPI service backed by Google Cloud Firestore.

## Local development

All local work runs against the **Firestore Emulator**. No GCP account,
billing, or credentials are required.

### One-time setup

```bash
gcloud components install cloud-firestore-emulator
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt -r requirements-test.txt
```

### Running

Terminal 1 — the emulator:

```bash
gcloud emulators firestore start --host-port=localhost:8080
```

Terminal 2 — the API:

```bash
cd backend && source venv/bin/activate
export FIRESTORE_EMULATOR_HOST=localhost:8080
uvicorn app.main:app --reload
```

With `FIRESTORE_EMULATOR_HOST` set, the Firestore client connects to the
emulator with anonymous credentials. Unset it and the client will attempt to
reach real Cloud Firestore using Application Default Credentials — which will
fail until a GCP project exists (ClickUp 86bazmf8b).

## Testing

```bash
cd backend && source venv/bin/activate
export FIRESTORE_EMULATOR_HOST=localhost:8080
pytest -v
```

`tests/test_firestore.py` requires the emulator and skips with a clear message
without it. All other tests run without it.

## Data model

```
users/{user_id}                        <- profile fields
  |- queue/{entity_type}_{item_id}
  \- completed/{entity_type}_{item_id}
```
````

- [ ] **Step 7: Commit**

```bash
git add backend/requirements.txt backend/requirements-test.txt backend/app/config.py backend/README.md backend/tests/test_firestore.py
git commit -m "feat: add Firestore emulator harness and configuration

Adds google-cloud-firestore, swaps DYNAMODB_TABLE_NAME for GCP_PROJECT_ID,
and corrects the AWS_REGION default to us-east-2 (retained for SSM).

Emulator-backed test fixtures with a clear skip message when it is not
running, plus a smoke test proving both round-trip and test isolation."
```

---

### Task 2: FirestoreService — user profile methods

**Files:**
- Create: `backend/app/services/firestore.py`
- Modify: `backend/tests/test_firestore.py` (append)

**Interfaces:**
- Consumes: `firestore_client`, `clear_emulator`, `TEST_PROJECT` from Task 1.
- Produces:
  - `class FirestoreService` with `__init__(self, client: firestore.Client | None = None)`
  - `create_or_update_user(user_id: str, provider_sub: str, auth_provider: str, email: Optional[str] = None, name: Optional[str] = None) -> Dict[str, Any]`
  - `get_user_profile(user_id: str) -> Dict[str, Any]`
  - `save_spotify_tokens(user_id: str, access_token: str, refresh_token: str, expires_in: int) -> None`
  - `_user_doc(user_id: str)` — internal helper returning the `users/{user_id}` DocumentReference; Tasks 3–4 build subcollections from it.

- [ ] **Step 1: Write the failing tests**

Append to `backend/tests/test_firestore.py`:

```python
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
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
cd backend && source venv/bin/activate
export FIRESTORE_EMULATOR_HOST=localhost:8080
pytest tests/test_firestore.py -v
```

Expected: collection error — `ModuleNotFoundError: No module named 'app.services.firestore'`

- [ ] **Step 3: Implement the service**

Create `backend/app/services/firestore.py`:

```python
import time
from typing import Any, Dict, Optional

from fastapi import HTTPException, status
from google.api_core.exceptions import GoogleAPIError
from google.cloud import firestore

from app.config import settings

USERS_COLLECTION = "users"


class FirestoreService:
    """Firestore-backed persistence for user profiles, queues, and completions.

    When FIRESTORE_EMULATOR_HOST is set in the environment, the client library
    connects to the emulator with anonymous credentials — no branching on
    environment is needed here.
    """

    def __init__(self, client: Optional[firestore.Client] = None):
        self.db = client or firestore.Client(project=settings.GCP_PROJECT_ID)

    def _user_doc(self, user_id: str):
        return self.db.collection(USERS_COLLECTION).document(user_id)

    def create_or_update_user(
        self,
        user_id: str,
        provider_sub: str,
        auth_provider: str,
        email: Optional[str] = None,
        name: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Creates or updates a user profile document."""
        payload: Dict[str, Any] = {
            "provider_sub": provider_sub,
            "auth_provider": auth_provider,
        }
        if email:
            payload["email"] = email
        if name:
            payload["display_name"] = name

        try:
            # merge=True mirrors DynamoDB's UpdateExpression: fields absent from
            # this write are left untouched rather than erased.
            self._user_doc(user_id).set(payload, merge=True)
            return self.get_user_profile(user_id)
        except GoogleAPIError as e:
            print(f"Firestore user creation error: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Database error during user profile write: {str(e)}",
            )

    def get_user_profile(self, user_id: str) -> Dict[str, Any]:
        """Retrieves a user's profile document, or {} if absent."""
        try:
            snapshot = self._user_doc(user_id).get()
            return snapshot.to_dict() or {}
        except GoogleAPIError as e:
            print(f"Firestore fetch profile error: {e}")
            return {}

    def save_spotify_tokens(
        self, user_id: str, access_token: str, refresh_token: str, expires_in: int
    ) -> None:
        """Caches Spotify API tokens on the user profile."""
        expires_at = int(time.time()) + expires_in
        try:
            self._user_doc(user_id).set(
                {
                    "spotify_access_token": access_token,
                    "spotify_refresh_token": refresh_token,
                    "spotify_token_expires_at": expires_at,
                    "spotify_linked": True,
                },
                merge=True,
            )
        except GoogleAPIError as e:
            print(f"Firestore save Spotify tokens error: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to link Spotify account credentials.",
            )
```

- [ ] **Step 4: Run the tests to verify they pass**

```bash
pytest tests/test_firestore.py -v
```

Expected: 7 passed (2 smoke + 5 new).

- [ ] **Step 5: Commit**

```bash
git add backend/app/services/firestore.py backend/tests/test_firestore.py
git commit -m "feat: add FirestoreService user profile methods

create_or_update_user, get_user_profile, and save_spotify_tokens backed by
users/{user_id} documents. merge=True preserves the partial-update semantics
of the DynamoDB UpdateExpression it replaces."
```

---

### Task 3: FirestoreService — queue methods and response mapping

**Files:**
- Modify: `backend/app/services/firestore.py`
- Modify: `backend/tests/test_firestore.py` (append)

**Interfaces:**
- Consumes: `FirestoreService`, `_user_doc` from Task 2; the `service` fixture.
- Produces:
  - `add_item_to_queue(user_id: str, item_id: str, entity_type: str, metadata: Dict[str, Any]) -> None`
  - `get_active_queue(user_id: str, entity_type: Optional[str] = None) -> List[Dict[str, Any]]`
  - module-level `_doc_id(entity_type: str, item_id: str) -> str`
  - module-level `_epoch(value) -> Optional[int]`
  - module-level `_map_queue_item(snapshot) -> Dict[str, Any]`
  - constants `QUEUE_COLLECTION = "queue"`, `COMPLETED_COLLECTION = "completed"`

- [ ] **Step 1: Write the failing tests**

Append to `backend/tests/test_firestore.py`:

```python
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
```

The last test is the guard for the "no leaked storage keys" decision — it fails loudly if someone later returns raw document data.

- [ ] **Step 2: Run the tests to verify they fail**

```bash
pytest tests/test_firestore.py -v
```

Expected: FAIL with `AttributeError: 'FirestoreService' object has no attribute 'add_item_to_queue'`

- [ ] **Step 3: Implement queue methods and mappers**

In `backend/app/services/firestore.py`, add to the imports:

```python
from typing import Any, Dict, List, Optional

from google.cloud.firestore_v1.base_query import FieldFilter
```

Add below `USERS_COLLECTION`:

```python
QUEUE_COLLECTION = "queue"
COMPLETED_COLLECTION = "completed"


def _doc_id(entity_type: str, item_id: str) -> str:
    """Stable document ID, so re-adding an item upserts instead of duplicating."""
    return f"{entity_type.lower()}_{item_id}"


def _epoch(value: Any) -> Optional[int]:
    """Normalises a Firestore timestamp to epoch seconds.

    Writes use SERVER_TIMESTAMP, so reads return a datetime. Clients have
    always seen integers here, so convert rather than change the contract.
    """
    if value is None:
        return None
    if isinstance(value, (int, float)):
        return int(value)
    return int(value.timestamp())


def _map_queue_item(snapshot) -> Dict[str, Any]:
    """Maps a queue document to the client-facing shape.

    Deliberately explicit: document identity and any future internal fields
    stay out of API responses.
    """
    data = snapshot.to_dict() or {}
    return {
        "entity_type": data.get("entity_type"),
        "item_id": data.get("item_id"),
        "added_at": _epoch(data.get("added_at")),
        "is_completed": data.get("is_completed", False),
        "metadata": data.get("metadata", {}),
    }
```

Add these methods to `FirestoreService`:

```python
    def _queue_collection(self, user_id: str):
        return self._user_doc(user_id).collection(QUEUE_COLLECTION)

    def _completed_collection(self, user_id: str):
        return self._user_doc(user_id).collection(COMPLETED_COLLECTION)

    def add_item_to_queue(
        self, user_id: str, item_id: str, entity_type: str, metadata: Dict[str, Any]
    ) -> None:
        """Adds a media item to the user's active queue."""
        try:
            self._queue_collection(user_id).document(
                _doc_id(entity_type, item_id)
            ).set(
                {
                    "entity_type": entity_type.lower(),
                    "item_id": item_id,
                    "added_at": firestore.SERVER_TIMESTAMP,
                    "is_completed": False,
                    "metadata": metadata,
                }
            )
        except GoogleAPIError as e:
            print(f"Firestore add queue item error: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to add item to your active list.",
            )

    def get_active_queue(
        self, user_id: str, entity_type: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """Retrieves the user's active queue, optionally filtered by media type."""
        try:
            query = self._queue_collection(user_id)
            if entity_type:
                query = query.where(
                    filter=FieldFilter("entity_type", "==", entity_type.lower())
                )
            return [_map_queue_item(doc) for doc in query.stream()]
        except GoogleAPIError as e:
            print(f"Firestore fetch queue error: {e}")
            return []
```

Note `entity_type.lower()` on both write and filter — this is what makes
`test_entity_type_casing_does_not_duplicate` pass, and it mirrors the old code's
`entity_type.upper()` normalisation in the sort key.

- [ ] **Step 4: Run the tests to verify they pass**

```bash
pytest tests/test_firestore.py -v
```

Expected: 14 passed.

- [ ] **Step 5: Commit**

```bash
git add backend/app/services/firestore.py backend/tests/test_firestore.py
git commit -m "feat: add FirestoreService queue methods

add_item_to_queue and get_active_queue over a per-user queue subcollection.
Document IDs are {entity_type}_{item_id}, preserving upsert-on-re-add.
Response mapping keeps storage details out of API payloads."
```

---

### Task 4: FirestoreService — completion and deletion

The atomic-completion fix lands here.

**Files:**
- Modify: `backend/app/services/firestore.py`
- Modify: `backend/tests/test_firestore.py` (append)

**Interfaces:**
- Consumes: everything from Tasks 2–3.
- Produces:
  - `log_item_completed(user_id: str, item_id: str, entity_type: str, rating: int, comment: str) -> None`
  - `get_completed_list(user_id: str, entity_type: Optional[str] = None) -> List[Dict[str, Any]]`
  - `delete_item(user_id: str, item_id: str, entity_type: str, queue_only: bool = True) -> None`
  - module-level `_map_completed_item(snapshot) -> Dict[str, Any]`

  This completes the 8-method surface. Task 5 wires exactly these into callers.

- [ ] **Step 1: Write the failing tests**

Append to `backend/tests/test_firestore.py`:

```python
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
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
pytest tests/test_firestore.py -v
```

Expected: FAIL with `AttributeError: 'FirestoreService' object has no attribute 'log_item_completed'`

- [ ] **Step 3: Implement completion and deletion**

Add the mapper below `_map_queue_item` in `backend/app/services/firestore.py`:

```python
def _map_completed_item(snapshot) -> Dict[str, Any]:
    """Maps a completed document to the client-facing shape."""
    data = snapshot.to_dict() or {}
    return {
        "entity_type": data.get("entity_type"),
        "item_id": data.get("item_id"),
        "completed_at": _epoch(data.get("completed_at")),
        "is_completed": data.get("is_completed", True),
        "rating": data.get("rating"),
        "comment": data.get("comment"),
        "metadata": data.get("metadata", {}),
    }
```

Add these methods to `FirestoreService`:

```python
    def log_item_completed(
        self, user_id: str, item_id: str, entity_type: str, rating: int, comment: str
    ) -> None:
        """Moves an active queue item into the completed log.

        The create and the delete run in a single batch, so a failure cannot
        leave the item present in both lists.
        """
        doc_id = _doc_id(entity_type, item_id)
        queue_ref = self._queue_collection(user_id).document(doc_id)
        completed_ref = self._completed_collection(user_id).document(doc_id)

        try:
            queue_snapshot = queue_ref.get()
            if not queue_snapshot.exists:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Item was not found in your active queue.",
                )

            queue_data = queue_snapshot.to_dict() or {}

            batch = self.db.batch()
            batch.set(
                completed_ref,
                {
                    "entity_type": entity_type.lower(),
                    "item_id": item_id,
                    "completed_at": firestore.SERVER_TIMESTAMP,
                    "is_completed": True,
                    "rating": rating,
                    "comment": comment,
                    "metadata": queue_data.get("metadata", {}),
                },
            )
            batch.delete(queue_ref)
            batch.commit()
        except HTTPException:
            raise
        except GoogleAPIError as e:
            print(f"Firestore complete item error: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to record completion.",
            )

    def get_completed_list(
        self, user_id: str, entity_type: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """Fetches all completed items logged by the user."""
        try:
            query = self._completed_collection(user_id)
            if entity_type:
                query = query.where(
                    filter=FieldFilter("entity_type", "==", entity_type.lower())
                )
            return [_map_completed_item(doc) for doc in query.stream()]
        except GoogleAPIError as e:
            print(f"Firestore fetch completions error: {e}")
            return []

    def delete_item(
        self, user_id: str, item_id: str, entity_type: str, queue_only: bool = True
    ) -> None:
        """Deletes an item from either the active queue or the completed log."""
        collection = (
            self._queue_collection(user_id)
            if queue_only
            else self._completed_collection(user_id)
        )
        try:
            collection.document(_doc_id(entity_type, item_id)).delete()
        except GoogleAPIError as e:
            print(f"Firestore delete item error: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to delete the item.",
            )
```

The bare `except HTTPException: raise` is defensive, not load-bearing. `HTTPException` is not
a subclass of `GoogleAPIError`, so the fallback clause could never catch the 404 regardless of
ordering. (The claim *is* true of `dynamodb.py`, whose fallback is the far broader
`except Exception` — do not carry that reasoning across without rechecking.) Keep the clause:
it costs nothing and preserves the 404 if the fallback is ever widened.

- [ ] **Step 4: Run the tests to verify they pass**

```bash
pytest tests/test_firestore.py -v
```

Expected: 24 passed. `FirestoreService` now has all 8 public methods.

- [ ] **Step 5: Commit**

```bash
git add backend/app/services/firestore.py backend/tests/test_firestore.py
git commit -m "feat: add FirestoreService completion and deletion

log_item_completed now writes the completed record and deletes the queue
record in a single batch. The DynamoDB version did these sequentially, so a
failure between them left the item in both lists."
```

---

### Task 5: Dependency injection and caller rewiring

After this task the app imports and runs on Firestore.

**Files:**
- Create: `backend/app/dependencies.py`
- Modify: `backend/app/routes/list_routes.py`
- Modify: `backend/app/routes/auth.py:6,35,69,106`
- Modify: `backend/app/services/spotify.py:5,40,91,129`
- Modify: `backend/app/main.py:8`
- Create: `backend/tests/test_list_routes.py`

**Interfaces:**
- Consumes: the complete `FirestoreService` from Tasks 2–4.
- Produces: `get_db() -> FirestoreService` in `app.dependencies`, the override point for `app.dependency_overrides`.

- [ ] **Step 1: Create the dependency**

Create `backend/app/dependencies.py`:

```python
from functools import lru_cache

from app.services.firestore import FirestoreService


@lru_cache(maxsize=1)
def _service() -> FirestoreService:
    return FirestoreService()


def get_db() -> FirestoreService:
    """FastAPI dependency yielding the shared FirestoreService.

    Construction is lazy and cached, so importing a module never opens a
    database connection — and tests can override this without touching
    constructors.
    """
    return _service()
```

- [ ] **Step 2: Write the failing route tests**

Create `backend/tests/test_list_routes.py`:

```python
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
```

- [ ] **Step 3: Run the tests to verify they fail**

```bash
pytest tests/test_list_routes.py -v
```

Expected: FAIL. `dynamodb.py` still exists, so the import succeeds — but the routes still call
the module-level `db_service`, so `app.dependency_overrides[get_db]` has nothing to override.
The tests fail with `AssertionError` on the empty `fake_db.calls` list (or an AWS
connection error, if boto3 attempts a real call before the assertion runs).

- [ ] **Step 4: Rewire `list_routes.py`**

Replace the import at `backend/app/routes/list_routes.py:4`:

```python
from app.services.dynamodb import db_service
```

with:

```python
from app.dependencies import get_db
from app.services.firestore import FirestoreService
```

Then add a `db` parameter to each of the six route functions and call methods on it. The full rewritten route bodies:

```python
@router.get("/active")
def get_active_queue(
    entity_type: Optional[str] = Query(None, description="Filter queue by media type (song, album, artist, podcast, audiobook)"),
    user_id: str = Depends(get_current_user_id),
    db: FirestoreService = Depends(get_db)
):
    """
    Returns all items in the user's active queue.
    """
    items = db.get_active_queue(user_id, entity_type)
    return {"items": items}

@router.post("/active", status_code=status.HTTP_201_CREATED)
def add_to_queue(
    item: QueueItemCreate,
    user_id: str = Depends(get_current_user_id),
    db: FirestoreService = Depends(get_db)
):
    """
    Adds a new item to the user's active queue.
    """
    db.add_item_to_queue(
        user_id=user_id,
        item_id=item.id,
        entity_type=item.entity_type,
        metadata=item.metadata
    )
    return {"status": "success", "message": "Item added to active queue."}

@router.delete("/active/{entity_type}/{item_id}")
def delete_from_queue(
    entity_type: str,
    item_id: str,
    user_id: str = Depends(get_current_user_id),
    db: FirestoreService = Depends(get_db)
):
    """
    Deletes an item from the user's active queue.
    """
    db.delete_item(
        user_id=user_id,
        item_id=item_id,
        entity_type=entity_type,
        queue_only=True
    )
    return {"status": "success", "message": "Item removed from queue."}

@router.post("/active/{entity_type}/{item_id}/complete", status_code=status.HTTP_200_OK)
def log_completion(
    entity_type: str,
    item_id: str,
    request: CompletionLogRequest,
    user_id: str = Depends(get_current_user_id),
    db: FirestoreService = Depends(get_db)
):
    """
    Logs an active queue item as completed (records rating and comments, and moves record to completions).
    """
    db.log_item_completed(
        user_id=user_id,
        item_id=item_id,
        entity_type=entity_type,
        rating=request.rating,
        comment=request.comment
    )
    return {"status": "success", "message": "Item logged as completed."}

@router.get("/completed")
def get_completed_history(
    entity_type: Optional[str] = Query(None, description="Filter history by media type"),
    user_id: str = Depends(get_current_user_id),
    db: FirestoreService = Depends(get_db)
):
    """
    Returns the user's completed media log history.
    """
    items = db.get_completed_list(user_id, entity_type)
    return {"items": items}

@router.delete("/completed/{entity_type}/{item_id}")
def delete_from_completed(
    entity_type: str,
    item_id: str,
    user_id: str = Depends(get_current_user_id),
    db: FirestoreService = Depends(get_db)
):
    """
    Permanently deletes a record from the completed list.
    """
    db.delete_item(
        user_id=user_id,
        item_id=item_id,
        entity_type=entity_type,
        queue_only=False
    )
    return {"status": "success", "message": "Item removed from history."}
```

- [ ] **Step 5: Run the route tests to verify they pass**

```bash
pytest tests/test_list_routes.py -v
```

Expected: 8 passed. These run without the emulator — confirm with:

```bash
env -u FIRESTORE_EMULATOR_HOST pytest tests/test_list_routes.py -v
```

Expected: 8 passed.

- [ ] **Step 6: Rewire `auth.py`**

Replace the import at `backend/app/routes/auth.py:6`:

```python
from app.services.dynamodb import db_service
```

with:

```python
from app.dependencies import get_db
from app.services.firestore import FirestoreService
```

Add `db: FirestoreService = Depends(get_db)` to the signatures of the three affected route functions, and change the three call sites from `db_service.` to `db.`:

- line ~35: `profile = db.create_or_update_user(` (Apple login)
- line ~69: `profile = db.create_or_update_user(` (Auth0 login)
- line ~106: `profile = db.get_user_profile(user_id)` (Spotify status)

Also update the stale comment above the first call site:

```python
    # 3. Create or update user profile item in Firestore
```

- [ ] **Step 7: Rewire `spotify.py`**

`SpotifyService` is not a route, so it cannot receive `Depends`. Replace the module-level import at `backend/app/services/spotify.py:5`:

```python
from app.services.dynamodb import db_service
```

with:

```python
from app.dependencies import get_db
```

Then at `spotify.py:40`, `:91`, and `:129`, call `get_db()` inside the methods:

```python
        profile = get_db().get_user_profile(user_id)
```

```python
            get_db().save_spotify_tokens(user_id, new_access_token, new_refresh_token, expires_in)
```

```python
            get_db().save_spotify_tokens(user_id, access_token, refresh_token, expires_in)
```

Import `get_db` at module top, following the conventions of every other import in this
codebase. What keeps client construction out of import time is calling `get_db()` **inside**
the methods rather than binding a service at module level — not where the `import` statement
sits. Do **not** add a module-level `db = get_db()`; that would reintroduce exactly the
import-time construction this migration removes.

- [ ] **Step 8: Update the app description**

In `backend/app/main.py:8`, change:

```python
    description="Backend API for managing Spotify media queue, completions, and user mapping in AWS.",
```

to:

```python
    description="Backend API for managing Spotify media queue, completions, and user mapping in GCP.",
```

- [ ] **Step 9: Verify the app imports and starts**

```bash
python -c "from app.main import app; print('import ok')"
```

Expected: `import ok` — and no Firestore connection attempt, proving construction is lazy.

Then, with the emulator running:

```bash
export FIRESTORE_EMULATOR_HOST=localhost:8080
uvicorn app.main:app --port 8001 &
sleep 3
curl -s localhost:8001/ | head
kill %1
```

Expected: `{"message":"Welcome to the ListenList API!","status":"healthy"}`

- [ ] **Step 10: Commit**

```bash
git add backend/app/dependencies.py backend/app/routes/list_routes.py backend/app/routes/auth.py backend/app/services/spotify.py backend/app/main.py backend/tests/test_list_routes.py
git commit -m "refactor: inject FirestoreService via FastAPI dependency

Replaces the import-time db_service singleton with get_db(), so importing a
module no longer opens a database connection and route tests can substitute
a fake. SpotifyService takes it via in-method get_db() as it is not a route.

Adds route tests covering all six list endpoints; they need no emulator."
```

---

### Task 6: Remove DynamoDB and verify

**Files:**
- Delete: `backend/app/services/dynamodb.py`
- Delete: `backend/tests/test_dynamodb.py`

**Interfaces:**
- Consumes: everything. This task's deliverable is a green suite with no DynamoDB code.
- Produces: nothing new.

- [ ] **Step 0: Fix `test_auth_routes.py`, which Task 5 broke by design**

`backend/tests/test_auth_routes.py:17` patches `app.routes.auth.db_service` — a symbol Task 5
correctly removed. One test (`test_auth0_login_returns_session_token`) fails as a result. Now
that routes take the service through `Depends(get_db)`, the correct substitution is a
dependency override, matching `tests/test_list_routes.py`.

Replace the `db_service` patch with an override. Add near the top:

```python
from app.dependencies import get_db
```

Then rewrite `test_auth0_login_returns_session_token`:

```python
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
```

The `try/finally` matters: without it a failing assertion leaves the override installed and
leaks into every later test in the session.

The other two tests in the file need no change — they never touch the database.

- [ ] **Step 1: Confirm nothing still references DynamoDB**

```bash
cd backend && grep -rn "dynamodb\|DynamoDB\|db_service" app tests
```

Expected: no output. If anything appears, fix it before deleting — a reference found now is a clear error; found after deletion it is an `ImportError` you must trace back.

- [ ] **Step 2: Delete the files**

```bash
git rm backend/app/services/dynamodb.py backend/tests/test_dynamodb.py
```

- [ ] **Step 3: Run the full suite with the emulator**

```bash
cd backend && source venv/bin/activate
export FIRESTORE_EMULATOR_HOST=localhost:8080
pytest -v
```

Expected: all pass — 24 in `test_firestore.py`, 8 in `test_list_routes.py`, plus the pre-existing `test_auth0.py` and `test_auth_routes.py`. Zero failures, zero errors.

- [ ] **Step 4: Run the full suite without the emulator**

```bash
env -u FIRESTORE_EMULATOR_HOST pytest -v
```

Expected: the 24 `test_firestore.py` tests skip with the emulator message; everything else passes. No errors. This proves a contributor without the emulator still gets a usable suite.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor: remove DynamoDB persistence layer

Deletes dynamodb.py and its tests. Firestore is now the only database.
The dev table held zero items, so there was nothing to migrate and no
reason to maintain two code paths."
```

- [ ] **Step 6: Update the ClickUp task**

Move task **86bb077ue** from `planning` to `complete`, and comment with the branch name and the commit range so the work is traceable from the task.

---

## Verification Checklist

Run at the end; every line must hold.

- [ ] `grep -rn "dynamodb\|DynamoDB\|db_service" backend/app backend/tests` returns nothing
- [ ] `pytest -v` with the emulator: all pass
- [ ] `pytest -v` without the emulator: `test_firestore.py` skips, everything else passes
- [ ] `python -c "from app.main import app"` succeeds with no emulator and no credentials
- [ ] `git diff main --stat -- infra/ frontend/` is empty (out-of-scope directories untouched)
- [ ] `backend/requirements.txt` still contains `boto3` (SSM needs it)
- [ ] `AWS_REGION` is still in `Settings`, defaulting to `us-east-2`
- [ ] No GCP project, billing account, or service-account key was created
