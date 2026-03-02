# GEMINI.md

## Project Overview

**ListenList** is a modern iOS application designed for curating and managing a personal library of music and audio content. Built with **SwiftUI**, it allows users to search for songs, albums, artists, podcasts, and audiobooks via the **Spotify Web API**, track their progress, and log completed items with ratings and notes.

### Core Technologies
- **UI Framework**: SwiftUI (iOS 17.0+)
- **Persistence**: Firebase Firestore (Real-time NoSQL)
- **Networking**: Spotify Web API using Swift's `async/await` concurrency
- **Security**: `KeychainSwift` for secure token management
- **Dependency Management**: Swift Package Manager (SPM)

### Architecture
The project follows a modular manager-based architecture:
- **`AuthManager`**: Handles Spotify OAuth2 flow, token exchange, and persistence in Keychain.
- **`SpotifyAPIManager`**: Interfaces with Spotify's REST API for search and metadata retrieval.
- **`DatabaseManager`**: Manages all interactions with Firebase Firestore, including CRUD operations for media items.
- **`ListManager`**: Orchestrates the local state of the user's "ListenList."
- **`SearchManager`**: Manages search state, debouncing, and result processing.

## Building and Running

### Prerequisites
- **Xcode 15.0+**
- **iOS 17.0+** Target Device/Simulator
- **Spotify Developer Account** (for Client ID/Secret)
- **Firebase Project** (for Firestore and `GoogleService-Info.plist`)

### Configuration
1. **Firebase**: Place `GoogleService-Info.plist` in `ListenList/ListenList/`.
2. **Spotify**: Create `Config.xcconfig` (based on `Sample.xcconfig`) in the `ListenList/` directory with the following keys:
   ```xcconfig
   SPOTIFY_API_CLIENT_ID = YOUR_ID
   SPOTIFY_API_CLIENT_SECRET = YOUR_SECRET
   REDIRECT_URI_SCHEME = YOUR_SCHEME
   REDIRECT_URI_HOST = YOUR_HOST
   ```

### Execution
- Open `ListenList.xcworkspace` in Xcode.
- Select the `ListenList` target and a compatible simulator/device.
- Press **⌘R** to build and run.
- Press **⌘U** to run unit and UI tests.

## Development Conventions

### Coding Style
- **Declarative UI**: Exclusively use SwiftUI for all user interface components.
- **Concurrency**: Use `async/await` and `Task` for asynchronous operations. Avoid completion handlers where possible.
- **Data Modeling**: 
  - Use `DTOs.swift` for types that map directly to API or Firestore responses.
  - Use `Media.swift` and `IdentifiableTypes.swift` for domain-specific models used in the UI.
- **Managers**: Centralize business logic and external service integrations in `Managers/`. Access them via `@StateObject` or `@EnvironmentObject`.

### Data Flow
1. **Search**: `SearchManager` calls `SpotifyAPIManager` -> Results are displayed.
2. **Add to List**: UI calls `DatabaseManager` to persist to Firestore -> `ListManager` updates local state.
3. **Completion**: UI captures rating/notes -> `DatabaseManager` updates the document with `isCompleted: true`.

### Testing
- **Unit Tests**: Located in `ListenListTests/`. Focus on testing Managers and Data Models.
- **UI Tests**: Located in `ListenListUITests/`. Focus on critical user journeys (Auth, Search, Adding to List).

## Project Hooks (Reference Context)

### Spotify API Reference
- **Base URL**: `https://api.spotify.com/v1`
- **Objects**: `Track`, `Album`, `Artist`, `Episode`, `Show`, `Audiobook`.
- **Note**: Always check if a field is optional in the Spotify Web API documentation before making it required in a DTO.

### Firestore Schema
- **Collections**: `users`, `songs`, `albums`, `artists`, `podcasts`, `audiobooks`.
- **Relationships**:
  - `songs.album`: `DocumentReference` to `albums`.
  - `songs.artists`: Array of `DocumentReference` to `artists`.
  - `albums.artists`: Array of `DocumentReference` to `artists`.
- **Persistence**: Booleans `showOnList` and `isCompleted` control visibility in the app's tabs.

### Data Flow & Architecture
1. **Fetch**: `SpotifyAPIManager` retrieves raw JSON.
2. **Transform**: `DTOs.swift` maps JSON to DTOs; `DatabaseManager` maps DTOs to Domain Models.
3. **State**: `ListManager` and `SearchManager` publish state to SwiftUI views.
4. **Action**: User interaction triggers `DatabaseManager` to sync local changes to Firestore.

### Environment Configuration
- **Config.xcconfig**: Contains Spotify credentials.
- **GoogleService-Info.plist**: Required for Firebase initialization.
- **Keychain**: Used by `AuthManager` to persist `accessToken` and `refreshToken` securely.
