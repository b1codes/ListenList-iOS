# Firestore Integration

## Query Examples
- **Fetch by Field**: `db.collection(collection).whereField("isCompleted", isEqualTo: true)`.
- **Sorting/Filtering**: Ensure Firestore indexes are considered for multi-field queries.
- **DocumentReferences**: Mapping `DocumentReference` to domain objects via `DispatchGroup`.

## Database Schema
- `users`: User metadata.
- `songs`, `albums`, `artists`, `podcasts`, `audiobooks`: Media collections.
- Relationship mapping: Media objects contain references to artists and albums.
