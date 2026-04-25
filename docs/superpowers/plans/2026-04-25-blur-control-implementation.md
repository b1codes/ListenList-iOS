# Blur Control Setting Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a discrete setting in the Settings tab to control the frosted glass opacity of media cards globally.

**Architecture:** Create a `SettingsManager` that persists a `GlassOpacity` enum via `@AppStorage`. Inject this into the environment and update all media cards to use the setting for their background glass layer.

**Tech Stack:** SwiftUI, @AppStorage, ObservableObject.

---

### Task 1: Define GlassOpacity Enum

**Files:**
- Create: `ListenList/ListenList/Types/Settings.swift`

- [ ] **Step 1: Create the Settings.swift file with GlassOpacity enum**

```swift
import Foundation

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

- [ ] **Step 2: Commit**

```bash
git add ListenList/ListenList/Types/Settings.swift
git commit -m "feat: add GlassOpacity enum for blur control"
```

---

### Task 2: Create SettingsManager

**Files:**
- Create: `ListenList/ListenList/Managers/SettingsManager.swift`

- [ ] **Step 1: Create SettingsManager class**

```swift
import SwiftUI
import Combine

class SettingsManager: ObservableObject {
    @AppStorage("glass_opacity") var glassOpacity: GlassOpacity = .standard
}
```

- [ ] **Step 2: Commit**

```bash
git add ListenList/ListenList/Managers/SettingsManager.swift
git commit -m "feat: add SettingsManager to manage app settings"
```

---

### Task 3: Inject SettingsManager into App Environment

**Files:**
- Modify: `ListenList/ListenList/ListenListApp.swift`

- [ ] **Step 1: Add SettingsManager to ListenListApp and inject it**

```swift
@main
struct ListenListApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = AuthManager()
    @StateObject private var settingsManager = SettingsManager() // Add this

    ...

    var body: some Scene {
        WindowGroup {
            ZStack {
                ...
            }
            .environmentObject(authManager)
            .environmentObject(SearchManager.shared)
            .environmentObject(settingsManager) // Inject here
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add ListenList/ListenList/ListenListApp.swift
git commit -m "feat: inject SettingsManager into the environment"
```

---

### Task 4: Implement Settings UI for Blur Control

**Files:**
- Modify: `ListenList/ListenList/Tabs/SettingsView.swift`

- [ ] **Step 1: Add Appearance section with Glass Opacity picker**

```swift
struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var settingsManager: SettingsManager // Add this
    ...

    var body: some View {
        NavigationView {
            List {
                ... profile section ...

                Section(header: Text("Appearance")) {
                    VStack(alignment: .leading) {
                        Text("Card Glass Opacity")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Picker("Glass Opacity", selection: $settingsManager.glassOpacity) {
                            ForEach(GlassOpacity.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    ... logout button ...
                }
            }
            ...
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add ListenList/ListenList/Tabs/SettingsView.swift
git commit -m "feat: add appearance settings UI for blur control"
```

---

### Task 5: Update Media Cards Integration

**Files:**
- Modify: `ListenList/ListenList/Cards/List Cards/SongCard.swift`
- Modify: `ListenList/ListenList/Cards/List Cards/AlbumCard.swift`
- Modify: `ListenList/ListenList/Cards/List Cards/ArtistCard.swift`
- Modify: `ListenList/ListenList/Cards/List Cards/PodcastCard.swift`
- Modify: `ListenList/ListenList/Cards/List Cards/AudiobookCard.swift`
- Modify: `ListenList/ListenList/Cards/Grid Cards/SongGridCard.swift`
- Modify: `ListenList/ListenList/Cards/Grid Cards/AlbumGridCard.swift`
- Modify: `ListenList/ListenList/Cards/Grid Cards/ArtistGridCard.swift`
- Modify: `ListenList/ListenList/Cards/Grid Cards/PodcastGridCard.swift`
- Modify: `ListenList/ListenList/Cards/Grid Cards/AudiobookGridCard.swift`

- [ ] **Step 1: Update each card to use settingsManager.glassOpacity.opacityValue**

Repeat for each file:
1. Add `@EnvironmentObject var settingsManager: SettingsManager` to the struct.
2. Find the background glass layer (usually a `RoundedRectangle` filled with `.ultraThinMaterial`).
3. Apply `.opacity(settingsManager.glassOpacity.opacityValue)` to it.

Example change:
```swift
RoundedRectangle(cornerRadius: 15.0)
    .fill(.ultraThinMaterial)
    .opacity(settingsManager.glassOpacity.opacityValue) // Dynamic opacity
```

- [ ] **Step 2: Commit**

```bash
git add ListenList/ListenList/Cards/
git commit -m "feat: link media cards to global glass opacity setting"
```

---

### Task 6: Verification

- [ ] **Step 1: Verify on Settings Screen**
Open settings, change opacity, and verify it persists.

- [ ] **Step 2: Verify Cards**
Navigate to ListenList and Search tabs and verify card backgrounds update according to the setting.
