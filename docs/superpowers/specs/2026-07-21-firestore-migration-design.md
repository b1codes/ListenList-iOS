# Backend Database Migration: DynamoDB → Google Cloud Firestore

**ClickUp:** 86bb077ue
**Date:** 2026-07-21
**Status:** Approved

---

## Overview

Replace the backend's DynamoDB persistence layer with Google Cloud Firestore, using the
Firestore Emulator for local development. This is the database half of the deliberate
AWS→GCP pivot; the Terraform/infrastructure half is tracked separately as **86bazmf8b**.

Scope is the **FastAPI backend only**. The iOS app is not touched by this task — it still
talks to Firestore directly through its own `DatabaseManager`, exactly as it does today.

**No GCP account exists yet, and none is required by this task.** This is a local-development
change: it moves the backend onto Firestore's API surface against the emulator, so that when
a GCP project is eventually created, going live is a credentials-and-config step rather than
a code rewrite. Nothing here blocks on, or should wait for, GCP account setup.

### Current state (verified 2026-07-21)

- `backend/app/services/dynamodb.py` is the only database layer: 8 methods, single-table
  design with `PK`/`SK` and one GSI (`GSI1`) for rating queries.
- `DynamoDBService.__init__` points boto3 at `http://localhost:8000` (DynamoDB Local) when
  `ENV == "local"` — this is the "local database" named in the task title.
- The dev environment is live in **us-east-2** (`listenlist-dev-api` Lambda,
  `listenlist-dev-table`), and the table contains **0 items**. There is no data to migrate.
- The iOS app has no local database. Its only on-device persistence is a single
  `@AppStorage("glass_opacity")` in `SettingsManager.swift:5`.

---

## Architecture

```
[Before]
iOS (direct Firestore, unchanged) ────────────────────► Cloud Firestore

FastAPI backend
  └─ DynamoDBService ──► DynamoDB Local (ENV=local)
                     └─► DynamoDB us-east-2 (dev)

[After]
iOS (direct Firestore, unchanged) ────────────────────► Cloud Firestore

FastAPI backend
  └─ FirestoreService ──► Firestore Emulator (local dev)
                      └─► Cloud Firestore (once 86bazmf8b provisions it)
```

### The local/cloud branch disappears

`dynamodb.py:11-19` requires an explicit `if settings.ENV == "local"` branch to redirect
boto3 at a local endpoint. The Firestore client library reads the `FIRESTORE_EMULATOR_HOST`
environment variable itself and reroutes with anonymous credentials, so no such branch is
needed. `FirestoreService.__init__` is one unconditional line, and "am I running locally?"
becomes purely an environment concern. The emulator therefore exercises the same code path
that will run against Cloud Firestore.

### Library choice

`google-cloud-firestore`, not `firebase-admin`. We need only the Firestore client; the
Firebase Admin SDK's auth/messaging/storage surface is unused weight. Authentication is
Application Default Credentials (ADC) in the cloud, bypassed entirely under the emulator.

`boto3` remains in `requirements.txt` — `config.py` still uses it to bootstrap secrets from
SSM Parameter Store. Migrating secrets to GCP Secret Manager belongs to 86bazmf8b.

---

## Data Model

DynamoDB's single-table layout becomes per-user documents with subcollections.

```
users/{user_id}                          ← profile document
  │    provider_sub, auth_provider, email, display_name,
  │    spotify_access_token, spotify_refresh_token,
  │    spotify_token_expires_at, spotify_linked
  │
  ├─ queue/{entity_type}_{item_id}
  │    entity_type, item_id, added_at, is_completed, metadata
  │
  └─ completed/{entity_type}_{item_id}
       entity_type, item_id, completed_at, is_completed,
       rating, comment, metadata
```

Document IDs in the subcollections are `{entity_type}_{item_id}` (lowercased entity type),
which preserves the current upsert-by-identity semantics: adding the same item twice
overwrites rather than duplicating, exactly as the DynamoDB `put_item` did.

### Key mapping

| DynamoDB (today) | Firestore (after) |
|---|---|
| `PK="USER#<id>", SK="PROFILE"` | `users/{id}` document |
| `SK="QUEUE#<TYPE>#<item>"` | `users/{id}/queue/{type}_{item}` |
| `SK="COMPLETED#<TYPE>#<item>"` | `users/{id}/completed/{type}_{item}` |
| `begins_with(SK, "QUEUE#SONG#")` | `queue.where(entity_type == "song")` |
| `GSI1_SK="RATING#4#..."` | `completed.order_by("rating")` — GSI unnecessary |
| `int(time.time())` | `SERVER_TIMESTAMP`, converted to epoch int on read |

The `GSI1_PK` / `GSI1_SK` attributes are dropped. They existed solely to make rating
queries possible under DynamoDB's index model; Firestore orders on any field directly.

### Timestamps

Writes use `firestore.SERVER_TIMESTAMP` rather than the application server's clock, so
timestamps come from the database and are immune to Lambda clock skew. The response mapper
converts them back to epoch-second integers, preserving the field types clients see today.

---

## Components

| File | Change |
|---|---|
| `backend/app/services/firestore.py` | **new** — `FirestoreService`, same 8-method surface |
| `backend/app/services/dynamodb.py` | **deleted** |
| `backend/app/dependencies.py` | **new** — `get_db()` FastAPI dependency |
| `backend/app/routes/list_routes.py` | 6 routes: module import → `Depends(get_db)` |
| `backend/app/routes/auth.py` | 3 call sites (lines 35, 69, 106) → `Depends(get_db)` |
| `backend/app/services/spotify.py` | 3 call sites (lines 40, 91, 129) → in-method `get_db()` |
| `backend/app/config.py` | drop `DYNAMODB_TABLE_NAME`; add `GCP_PROJECT_ID`; fix `AWS_REGION` default |
| `backend/app/main.py` | description text: "in AWS" → "in GCP" |
| `backend/requirements.txt` | add `google-cloud-firestore>=2.16.0` |
| `backend/tests/test_dynamodb.py` | **deleted** |
| `backend/tests/test_firestore.py` | **new** — emulator-backed integration tests |
| `backend/tests/test_list_routes.py` | **new** — route tests with a fake service |
| `backend/README.md` | **new** — emulator setup and backend run/test instructions |

The root `README.md` needs no change: it documents the iOS app exclusively, already lists
Firebase Firestore under "Technologies Used", and never mentions the backend or AWS.

### Method surface (unchanged signatures)

`FirestoreService` keeps the exact public signatures of `DynamoDBService`, so routes change
only in *how they obtain* the service, not how they call it:

- `create_or_update_user(user_id, provider_sub, auth_provider, email=None, name=None)`
- `get_user_profile(user_id)`
- `save_spotify_tokens(user_id, access_token, refresh_token, expires_in)`
- `add_item_to_queue(user_id, item_id, entity_type, metadata)`
- `get_active_queue(user_id, entity_type=None)`
- `log_item_completed(user_id, item_id, entity_type, rating, comment)`
- `get_completed_list(user_id, entity_type=None)`
- `delete_item(user_id, item_id, entity_type, queue_only=True)`

### Dependency injection replaces the import-time singleton

`dynamodb.py:223` instantiates `db_service = DynamoDBService()` at import time, which opens
a client connection as a side effect of importing the module. That is why
`test_dynamodb.py:5-9` must construct instances via `__new__` to bypass `__init__`.

`get_db()` replaces it with a lazily-constructed, cached instance that FastAPI injects.
Route tests then substitute a fake through `app.dependency_overrides[get_db]` with no
constructor trickery.

`SpotifyService` is not a route and cannot receive `Depends`. Its three call sites instead
invoke `get_db()` inside the methods that need it, rather than binding a service at import
time. This preserves the property that matters — importing a module never constructs a
database client — without making `SpotifyService` FastAPI-aware.

### Configuration changes

```python
# Removed
DYNAMODB_TABLE_NAME: str = "ListenListTable"

# Added
GCP_PROJECT_ID: str = "listenlist-dev"
# Under the emulator this is just a namespace label — the project need not
# exist, and no account, billing, or credentials are involved. It becomes a
# real project ID only once one is created (86bazmf8b).
#
# FIRESTORE_EMULATOR_HOST is read directly from the environment by the
# client library — it is deliberately NOT a Settings field.

# Corrected
AWS_REGION: str = "us-east-2"   # was "us-east-1"
```

`AWS_REGION` is **retained**, not removed: `config.py:32` still uses it to construct the SSM
client for secret bootstrapping. Its declared default was wrong — the infrastructure lives
in us-east-2. This is masked in Lambda, where the runtime injects `AWS_REGION` into the
environment and pydantic's `BaseSettings` silently prefers the env var over the default, but
it would resolve to the wrong region's Parameter Store anywhere else.

---

## Behavioral Improvements

Two defects in the current implementation are fixed as part of the port.

### 1. Completion becomes atomic

`dynamodb.py:180-183` writes the completed record and then deletes the queue record as two
sequential calls, with a comment conceding this is "to keep Lambda cost/complexity minimal."
A failure between the two leaves the item in both the active queue and the completed list.

Firestore batched writes make this atomic at no added cost or complexity, so
`log_item_completed` performs the create and the delete in a single `WriteBatch`.

### 2. Storage keys stop leaking into API responses

Routes currently return raw DynamoDB items, so `PK`, `SK`, `GSI1_PK`, and `GSI1_SK` appear
in client-facing JSON. A response mapper now returns only domain fields:

```jsonc
// before
{"items": [{"PK": "USER#u1", "SK": "QUEUE#SONG#abc",
            "GSI1_PK": "...", "GSI1_SK": "...",
            "entity_type": "song", "item_id": "abc", ...}]}

// after
{"items": [{"entity_type": "song", "item_id": "abc",
            "added_at": 1784494491, "is_completed": false,
            "metadata": {...}}]}
```

The iOS app does not consume these endpoints yet — it still reads Firestore directly — so
there is no client to break. This is the cheapest possible moment to correct the contract.

---

## Error Handling

Behavior is preserved exactly; only the exception type caught changes, from
`botocore.exceptions.ClientError` / bare `Exception` to
`google.api_core.exceptions.GoogleAPIError`.

| Operation | On failure |
|---|---|
| `create_or_update_user` | `HTTPException(500)`, "Database error during user profile write" |
| `save_spotify_tokens` | `HTTPException(500)`, "Failed to link Spotify account credentials." |
| `add_item_to_queue` | `HTTPException(500)`, "Failed to add item to your active list." |
| `log_item_completed` | `HTTPException(404)` if absent from queue; `HTTPException(500)` otherwise |
| `delete_item` | `HTTPException(500)`, "Failed to delete the item." |
| `get_user_profile` | returns `{}` (logs, does not raise) |
| `get_active_queue` / `get_completed_list` | return `[]` (log, do not raise) |

Read paths remain deliberately forgiving so a transient database problem degrades to an
empty list rather than a client-facing error.

---

## Local Development

The emulator requires one-time setup. `gcloud` (SDK 576.0.0) and Java 21 are already
present on the dev machine; the emulator component is not yet installed:

```bash
gcloud components install cloud-firestore-emulator

# start (foreground, port 8080)
gcloud emulators firestore start --host-port=localhost:8080

# in the API shell
export FIRESTORE_EMULATOR_HOST=localhost:8080
uvicorn app.main:app --reload
```

With `FIRESTORE_EMULATOR_HOST` set, the client library connects to the emulator with
anonymous credentials; no GCP project, billing account, or service-account key is required
to run or test the backend locally.

---

## Testing

Tests are written before implementation (TDD).

### `tests/test_firestore.py` — emulator-backed integration

Exercises `FirestoreService` against a live emulator, verifying real read/write behavior and
query semantics rather than call shapes. A module-level `skipif` on an unset
`FIRESTORE_EMULATOR_HOST` produces a clear skip message instead of an obscure connection
failure. An autouse fixture clears emulator data between tests via the emulator's REST
`DELETE /emulator/v1/projects/{project}/databases/(default)/documents` endpoint, keeping
tests independent.

Coverage:
- user upsert stores provider fields; optional `email`/`name` omitted when not supplied
- Spotify tokens write to the profile with a correct computed expiry
- queue add → read-back round trip
- `entity_type` filtering returns only matching items
- adding the same item twice upserts rather than duplicating
- completion moves the item: present in `completed`, absent from `queue`, rating/comment recorded
- completing an item absent from the queue raises 404
- completed-list filtering by `entity_type`
- delete removes from queue (`queue_only=True`) and from completed (`queue_only=False`)
- reads against an unknown user return `[]` / `{}` rather than raising

### `tests/test_list_routes.py` — route wiring

Uses FastAPI's `TestClient` with `app.dependency_overrides[get_db]` bound to an in-memory
fake and `get_current_user_id` overridden to a fixed test user. Runs without the emulator,
verifying that each of the six routes calls the right service method with the right
arguments and returns the cleaned response shape.

### Existing tests

`test_auth0.py` is unaffected. `test_auth_routes.py` needs one test rewired from patching
`db_service` to a `get_db` dependency override. `test_dynamodb.py` is deleted
along with the service it tested.

---

## Out of Scope

| Item | Owner |
|---|---|
| Terraform AWS→GCP migration, GCP project provisioning | 86bazmf8b |
| SSM Parameter Store → GCP Secret Manager | 86bazmf8b |
| Retiring the AWS Lambda / API Gateway deployment | 86bazmf8b |
| The iOS app's direct-Firestore `DatabaseManager` (619 lines) | future task |
| Firestore security rules | future — the backend uses ADC, which bypasses rules entirely; they matter only when a client talks to Firestore directly |
| Data migration | not applicable — the dev table holds 0 items |

---

## Risks

**The deployed AWS environment stops working — intentionally.** After this change, the
`listenlist-dev-api` Lambda points at a Firestore project that does not exist, so it has no
reachable database. This is not a regression to manage: AWS is being abandoned, the dev table
is empty, and the deployment has no users. Local development via the emulator is fully
functional throughout, which is the only environment that matters until a GCP project exists.

The practical consequence is that **the cloud path ships untested**. Emulator coverage
verifies the query semantics and data model but cannot verify credentials, ADC resolution, or
IAM. Expect a short round of authentication fixes when 86bazmf8b provisions a real project —
budget for it there rather than assuming a clean cutover.

**Emulator/production divergence.** The emulator is faithful for CRUD and query semantics
but does not enforce quotas, billing limits, or composite-index requirements the way
production does. The chosen data model uses only single-field filters and ordering, so no
composite indexes are required — this is the main reason to prefer per-user subcollections
over flat collections with `user_id` filters.
