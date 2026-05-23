import SwiftUI
import Combine

class SettingsManager: ObservableObject {
    @AppStorage("glass_opacity") var glassOpacity: GlassOpacity = .standard
}
