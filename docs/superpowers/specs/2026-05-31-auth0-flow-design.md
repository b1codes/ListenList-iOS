# Auth0 Authentication Flow Design

**ClickUp:** 86ba365wd (parent) / 86ba3660b (Auth0 subtask)
**Date:** 2026-05-31
**Status:** Approved

---

## Overview

Replace the current Spotify OAuth login with Auth0 as the primary identity layer. Auth0 becomes the authentication infrastructure (Universal Login, Apple SSO, social connections). Our backend remains the source of truth for user identity — Auth0 merely hands us a verified ID token, which the backend validates and exchanges for our own session JWT. Spotify moves to a post-login "link your account" step.

---

## Architecture

### Two-phase auth model

**Phase 1 — Identity (Auth0)**
```
iOS App
  → Auth0.swift SDK launches Universal Login (ASWebAuthenticationSession)
  → User logs in (email/password, Apple via Auth0, Google, etc.)
  → Auth0 returns ID token (RS256 JWT)
  → iOS sends ID token to POST /auth/auth0
  → Backend verifies JWT against Auth0 JWKS endpoint
  → Backend extracts stable `sub` claim, hashes to internal user_id
  → Backend upserts user profile in DynamoDB
  → Backend returns our session JWT + user metadata
  → iOS stores session JWT in Keychain, sets isAuthenticated = true
```

**Phase 2 — Spotify Link (post-login, unchanged)**
```
User taps "Connect Spotify" in Settings
  → Existing Spotify OAuth flow
  → POST /auth/spotify/connect with auth code
  → Backend stores Spotify tokens on user profile
```

The session JWT is the only credential iOS needs to store. The Auth0 ID token is consumed once and discarded. Spotify tokens never touch the iOS Keychain — they live in DynamoDB.

---

## Backend Changes

### New file: `backend/app/auth/auth0.py`

Mirrors `apple.py` in structure. Fetches Auth0's JWKS from `https://<AUTH0_DOMAIN>/.well-known/jwks.json`, finds the matching public key by `kid`, verifies the RS256 JWT:
- audience = `AUTH0_CLIENT_ID`
- issuer = `https://<AUTH0_DOMAIN>/`
- expiry enforced

Returns decoded claims on success. Raises `HTTPException` (401) on invalid/expired token, (502) if JWKS fetch fails.

### Modified: `backend/app/config.py`

Adds three new settings:
```python
AUTH0_DOMAIN: str       # e.g. "dev-abc123.us.auth0.com"
AUTH0_CLIENT_ID: str    # Auth0 application client ID
AUTH0_AUDIENCE: str     # Auth0 API audience identifier
```

Sourced from SSM Parameter Store in Lambda (keys: `/listenlist/auth0/domain`, `/listenlist/auth0/client_id`, `/listenlist/auth0/audience`). Loaded from `.env` locally.

### Modified: `backend/app/models/user.py`

Adds:
```python
class Auth0LoginRequest(BaseModel):
    identity_token: str
    client_id: str  # Auth0 client ID
```

Response uses existing `UserSessionResponse` — no new model needed.

### Modified: `backend/app/routes/auth.py`

Adds `POST /auth/auth0`. Flow mirrors `/auth/apple`:
1. Verify ID token via `auth0.verify_auth0_token()`
2. Extract `sub` claim → hash to `user_id`
3. Extract `email` from claims if present
4. `db_service.create_or_update_user(user_id, auth_provider="auth0", provider_sub=sub, email, name)`
5. `create_session_token(user_id, email)` → return `UserSessionResponse`

### Modified: `backend/app/services/dynamodb.py`

`create_or_update_user` signature updated to replace `apple_sub` with generic `provider_sub: str` and `auth_provider: str`. DynamoDB item stores `auth_provider` and `provider_sub` instead of `apple_sub`. Existing Apple route updated to pass `auth_provider="apple"`.

---

## iOS Changes

### Dependency: `Auth0.swift` (Swift Package Manager)

Added via Xcode → Add Package Dependencies:
- URL: `https://github.com/auth0/Auth0.swift`
- Target: `ListenList`

Auth0 credentials added to `ListenList/Config.xcconfig`:
```
AUTH0_DOMAIN = dev-abc123.us.auth0.com
AUTH0_CLIENT_ID = <your-client-id>
```

Also requires a `Auth0.plist` in the app bundle (standard Auth0.swift setup) with domain and clientId. A custom URL scheme must be registered in `Info.plist` matching the bundle ID (e.g. `com.b1codes.ListenList`), so Auth0.swift can handle the redirect back to the app after Universal Login.

### Modified: `AuthManager.swift`

Full rewrite. Removes all Spotify token exchange logic. New responsibilities:

- **`init()`** — checks Keychain for existing session JWT; if present and not expired (decode `exp` locally), sets `isAuthenticated = true` without a network call. If expired, clears token and sets `isLoading = false`.
- **`login()`** — calls `Auth0.webAuth().start()`, extracts `idToken` from credentials, POSTs to `POST /auth/auth0` on our backend, stores returned `access_token` in Keychain under key `"sessionToken"`, sets `isAuthenticated = true`.
- **`logout()`** — calls `Auth0.webAuth().clearSession()`, deletes `"sessionToken"` from Keychain, sets `isAuthenticated = false`.

Keychain key: `"sessionToken"` (replaces `"refreshToken"`).
`isAuthenticated` and `isLoading` `@Published` properties remain — same role in `ListenListApp.swift`.

Backend base URL read from `Config.xcconfig` via a `BACKEND_BASE_URL` key.

### Modified: `AuthorizationView.swift`

Full rewrite. Removes `WebView`, `WebViewCoordinator`, and all WKWebView/Spotify redirect logic.

Replaced with a minimal view:
- App icon
- "Sign In" button → calls `authManager.login()`
- Loading state while login is in progress

Auth0.swift launches `ASWebAuthenticationSession` internally — no web view management needed in this file.

### Modified: `ListenListApp.swift`

- Removes `getAuthorizationCodeURL()`, `authURL` property, and all Spotify OAuth URL construction
- `init()` becomes empty (no URL to build)
- `body` structure unchanged: `isLoading` → spinner, `isAuthenticated` → `TabUIView`, else → `AuthorizationView`

---

## What Does Not Change

- `/auth/spotify/connect` and `/auth/spotify/status` routes — untouched
- `SettingsView` Spotify connection UI — untouched
- All list, search, and media routes — untouched
- `ListManager`, `DatabaseManager`, `SpotifyAPIManager`, `SearchManager` — untouched
- DynamoDB schema (single-table design, user profile shape) — additive only

---

## Error Handling

| Scenario | Behavior |
|---|---|
| Auth0 login cancelled by user | `Auth0.webAuth().start()` returns an error; catch and silently return (stay on login screen) |
| Auth0 token expired before reaching backend | Backend returns 401; iOS clears token, sets `isAuthenticated = false` |
| Network failure during `/auth/auth0` call | Show error state on login screen, allow retry |
| Session JWT expired on app relaunch | Detected locally via `exp` decode; `login()` triggered automatically |
| Auth0 JWKS fetch failure | Backend returns 502; iOS surfaces generic "sign in failed" error |

---

## Local Development Setup

1. Create Auth0 tenant → Native application → note domain + client ID
2. In Auth0 dashboard, add `com.b1codes.ListenList://callback` as an allowed callback URL and allowed logout URL
3. Add `AUTH0_DOMAIN`, `AUTH0_CLIENT_ID`, and `BACKEND_BASE_URL` to `ListenList/Config.xcconfig`
4. Add `Auth0.plist` to the app bundle (domain + clientId fields)
5. Register `com.b1codes.ListenList` as a custom URL scheme in `Info.plist`
6. Add `AUTH0_DOMAIN`, `AUTH0_CLIENT_ID`, `AUTH0_AUDIENCE` to `backend/.env`

---

## Out of Scope

- Auth0 Rules / Actions configuration (Auth0 tenant setup is the developer's responsibility)
- Spotify as a social connection within Auth0 (Spotify is a linked service, not an Auth0 social provider)
- Token refresh for the session JWT (current 1-week expiry is sufficient for MVP; re-login on expiry is acceptable)
- Migration of existing Firestore users to DynamoDB users (no existing users in prod)
