# Spotify API Endpoints

## Authentication
- Handled by `AuthManager.swift` via OAuth2.
- Tokens are stored in Keychain.

## Common Endpoints
- Search: `https://api.spotify.com/v1/search?q={query}&type={type}`
- Album Tracks: `https://api.spotify.com/v1/albums/{id}/tracks`
- User Profile: `https://api.spotify.com/v1/me`
- Top Content: `https://api.spotify.com/v1/me/top/{type}`

## Response Types
- Map JSON keys to camelCase in `Decodable` structs.
- Nest `ImageResponse` for album art.
