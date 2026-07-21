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
