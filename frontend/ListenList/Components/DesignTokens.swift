// ListenList/ListenList/Components/DesignTokens.swift
//
// Color and view tokens from DESIGN.md's "Instrument Panel" palette.
// Keeping these centralized means a value only needs to change in one place.

import SwiftUI

extension Color {
    /// Thermal Core — inner stop of the Thermal Glow spectrum. Also used for
    /// destructive actions per DESIGN.md's deliberate red/"hot" resonance.
    static let thermalCore = Color(red: 255 / 255, green: 59 / 255, blue: 48 / 255)

    /// Thermal Corona — outer stop of the Thermal Glow spectrum.
    static let thermalCorona = Color(red: 255 / 255, green: 149 / 255, blue: 0 / 255)

    /// Alias for Thermal Core, named for its destructive-action role even
    /// though the value is identical.
    static let destructiveRed = thermalCore

    /// Glass Surface — base translucent material tint layered under `.ultraThinMaterial`.
    static let glassSurface = Color.white.opacity(0.05)

    /// Glass Edge — rim-light stroke color for a glass pane's boundary.
    static let glassEdge = Color.white.opacity(0.2)

    /// Edit Scrim — dimming overlay applied when a card enters edit mode.
    static let editScrim = Color.gray.opacity(0.6)

    /// Contrast Scrim — fixed floor under card artwork/glass guaranteeing legible
    /// white text regardless of the user's GlassOpacity setting or artwork brightness.
    static let contrastScrim = Color.black.opacity(0.35)
}

extension View {
    /// Shadow for white text/icons rendered over card artwork, per DESIGN.md's
    /// Contrast Floor Rule.
    func cardTextShadow() -> some View {
        self.shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
    }

    /// The glass-over-artwork background shared by every media card: the item's
    /// own artwork (or a gray placeholder), the fixed Contrast Scrim, and the
    /// user-adjustable `.ultraThinMaterial` glass layer, all blurred together.
    func cardGlassBackground(imageUrl: String?, glassOpacity: Double, cornerRadius: CGFloat = 15.0) -> some View {
        self
            .background(
                ZStack {
                    if let imageUrl, let url = URL(string: imageUrl) {
                        CachedAsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray
                        }
                    } else {
                        Color.gray
                    }

                    Color.contrastScrim

                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                        .opacity(glassOpacity)
                }
                .blur(radius: 4.2)
                .allowsHitTesting(false)
            )
            .cornerRadius(cornerRadius)
            .clipped()
    }
}

/// The dimming scrim + delete affordance shown over a media card in edit mode.
/// Deliberately a separate (non-`AnyView`-wrapped) sibling view rather than an
/// overlay modifier on the card content — see commit e55dd93: NavigationLink
/// was swallowing taps meant for the delete button, and rendering edit mode as
/// an independent view fixed it.
struct EditModeOverlay: View {
    var onDelete: (() -> Void)?

    var body: some View {
        ZStack {
            Color.editScrim
            if let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.destructiveRed)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Delete")
            }
        }
    }
}
