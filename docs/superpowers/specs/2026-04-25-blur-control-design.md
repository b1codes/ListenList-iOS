# Design Doc: Blur Control Setting

## 1. Problem Statement
Currently, all media cards (List and Grid variants) in ListenList use a hardcoded frosted glass effect (`.ultraThinMaterial` and `.blur(radius: 4.2)`). Users cannot adjust how much of the background image shines through, which can affect readability or aesthetic preference depending on the device and lighting.

## 2. Goals
- Provide a manual control for "frosted glass opacity" in the Settings screen.
- Use discrete options for simplicity and consistent design.
- Persist the user's choice across app sessions.
- Apply the setting globally to all media cards.

## 3. Proposed Design

### 3.1 Data Model
A new enum `GlassOpacity` will define the discrete options and their corresponding opacity values.

```swift
enum GlassOpacity: String, CaseIterable, Identifiable {
    case subtle = "Subtle"
    case standard = "Standard"
    case frosted = "Frosted"
    case heavy = "Heavy"

    var id: String { self.rawValue }

    var opacityValue: Double {
        switch self {
        case .subtle: return 0.4
        case .standard: return 0.7
        case .frosted: return 0.85
        case .heavy: return 0.98
        }
    }
}
```

### 3.2 State Management
A `SettingsManager` class will be created in `Managers/` to handle app settings.

- **Class**: `SettingsManager: ObservableObject`
- **Storage**: Uses `@AppStorage("glass_opacity")` to persist the selection.
- **Injection**: Initialized in `ListenListApp.swift` and injected as an `.environmentObject(settingsManager)`.

### 3.3 UI Changes
- **Settings Screen**: Add an "Appearance" section to `SettingsView.swift`.
- **Control**: Use a `Picker` with `SegmentedPickerStyle` to allow selection between the four discrete options.

### 3.4 Integration in Cards
Update all media card components to read the `SettingsManager` from the environment and apply the `opacityValue` to the glass layer.

**Files to Update:**
- `ListenList/ListenList/Cards/List Cards/SongCard.swift`
- `ListenList/ListenList/Cards/List Cards/AlbumCard.swift`
- `ListenList/ListenList/Cards/List Cards/ArtistCard.swift`
- `ListenList/ListenList/Cards/List Cards/PodcastCard.swift`
- `ListenList/ListenList/Cards/List Cards/AudiobookCard.swift`
- `ListenList/ListenList/Cards/Grid Cards/SongGridCard.swift`
- `ListenList/ListenList/Cards/Grid Cards/AlbumGridCard.swift`
- `ListenList/ListenList/Cards/Grid Cards/ArtistGridCard.swift`
- `ListenList/ListenList/Cards/Grid Cards/PodcastGridCard.swift`
- `ListenList/ListenList/Cards/Grid Cards/AudiobookGridCard.swift`

**Implementation Snippet:**
```swift
@EnvironmentObject var settingsManager: SettingsManager
...
RoundedRectangle(cornerRadius: 15.0)
    .fill(.ultraThinMaterial)
    .opacity(settingsManager.glassOpacity.opacityValue)
```

## 4. Testing Strategy
- **Manual Verification**: Verify that changing the setting in the Settings tab immediately updates the cards in the "ListenList" and "Search" tabs.
- **Persistence Check**: Close and relaunch the app to ensure the blur setting is preserved.
- **Visual Audit**: Check each card type (Song, Album, etc.) and layout (List, Grid) to ensure the opacity scales correctly.
