// ListenList/ListenList/Managers/TabSelectionManager.swift

import SwiftUI

enum AppTab: Hashable {
    case home, completed, settings, search
}

/// Lets a child view (e.g. an empty-state CTA) switch the active tab
/// programmatically, without threading a Binding through every intermediate view.
@MainActor
class TabSelectionManager: ObservableObject {
    @Published var selected: AppTab = .home
}
