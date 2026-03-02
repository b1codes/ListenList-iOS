---
name: spotify-api-integrator
description: Integrates new Spotify API endpoints and generates `Decodable` response models. Use when expanding ListenList's feature set with additional music or audio metadata from Spotify.
---

# Spotify API Integrator

This skill assists in expanding the Spotify API integration in ListenList.

## Key Workflow
1.  **Response Models**: Define `Decodable` structs for API responses.
2.  **API Methods**: Implement `async/await` methods in `SpotifyAPIManager.swift`.
3.  **Authentication**: Ensure token headers are correctly included in new requests.

## Reference
- See [ENDPOINTS.md](references/ENDPOINTS.md) for existing Spotify API patterns.
