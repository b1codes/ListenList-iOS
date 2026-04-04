# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

This is a standard Xcode project with no Makefile or fastlane. All building and testing is done via Xcode or `xcodebuild`:

```bash
# Build
xcodebuild build -project ListenList.xcodeproj -scheme ListenList -destination 'platform=iOS Simulator,name=iPhone 16'

# Run all tests
xcodebuild test -project ListenList.xcodeproj -scheme ListenList -destination 'platform=iOS Simulator,name=iPhone 16'

# Run a single test class
xcodebuild test -project ListenList.xcodeproj -scheme ListenList -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:ListenListTests/ListenListTests
```

## Required Setup

Two files must exist before the app can run (neither is committed):

1. **`ListenList/Config.xcconfig`** — Spotify credentials. Copy `ListenList/Sample.xcconfig` and fill in your Spotify app's `CLIENT_ID`, `CLIENT_SECRET`, and redirect URI.
2. **`ListenList/GoogleService-Info.plist`** — Firebase configuration. Download from the Firebase Console for this project.

## Architecture

SwiftUI app targeting iOS 18+. Uses **MVVM-lite** with a dedicated Managers layer as the source of truth.

### Manager Singletons (`.shared`)

All managers are `@EnvironmentObject` singletons injected at the root and are the primary way views interact with data:

- **`AuthManager`** — Spotify OAuth 2.0 with PKCE. Stores refresh token in Keychain via `KeychainSwift`. `isAuthenticated` drives the root view conditional.
- **`ListManager`** (`@MainActor`) — Owns `cards` and `completedCards` `@Published` arrays. All list mutations go through here.
- **`DatabaseManager`** — All Firestore reads/writes. Uses DTOs from `Types/DTOs.swift` for Firestore serialization; domain models (`Types/IdentifiableTypes.swift`) for everything else.
- **`SpotifyAPIManager`** — Wraps Spotify Web API for search and recommendations. Handles token refresh coordination with `AuthManager`.
- **`SearchManager`** — Lightweight singleton holding search query string and active `MediaType` filter.

### Data Flow

```
View action
  → SpotifyAPIManager.search() → Spotify API → CodableTypes (response)
  → DatabaseManager stores DTO → Firestore
  → ListManager.cards updated (@Published)
  → SwiftUI re-renders
```

Authentication flow: `AuthorizationView` (WKWebView) → Spotify OAuth → redirect to `listenlist://callback` → `AuthManager.exchangeCodeForTokens()` → `isAuthenticated = true` → `TabUIView` shown.

### Key Type Boundaries

- **`Types/CodableTypes.swift`** — Spotify API response shapes (decoded from JSON).
- **`Types/DTOs.swift`** — Firestore-serializable versions of each media type.
- **`Types/IdentifiableTypes.swift`** — Domain models used throughout the UI (`Song`, `Album`, `Artist`, `Podcast`, `Audiobook`).
- **`Types/Card.swift`** — `Card` struct wraps a `CardType` enum (the five media types) for use in list/grid views.

### View Structure

- `ListenListApp.swift` — Entry point; builds the Spotify OAuth URL and injects managers as environment objects.
- `Tabs/TabUIView.swift` — Root tab container.
- `Tabs/` — The four main tabs: ListenList (queue), Search, Completed, Settings.
- `Cards/Grid Cards/` and `Cards/List Cards/` — Per-type card components for the two layout modes.
- `Details/` — Full detail views for each media type.

## Dependencies (Swift Package Manager)

- **firebase-ios-sdk** — `FirebaseCore`, `FirebaseFirestore`, `FirebaseAuth`, `FirebaseAnalytics`
- **KeychainSwift** — Secure storage for the Spotify refresh token
