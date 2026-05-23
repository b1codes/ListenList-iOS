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
