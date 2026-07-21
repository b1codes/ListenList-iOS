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
