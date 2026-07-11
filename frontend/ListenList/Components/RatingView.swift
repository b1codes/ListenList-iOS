// ListenList/ListenList/Components/RatingView.swift

import SwiftUI

struct RatingView: View {
    @Binding var rating: Int
    var maxRating = 5

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { index in
                Button {
                    rating = index
                } label: {
                    Image(systemName: index <= rating ? "star.fill" : "star")
                        .foregroundColor(index <= rating ? .yellow : .gray)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
            }
        }
        // Exposed to VoiceOver as one adjustable control (swipe up/down to
        // change the rating) rather than five separate stops, which is the
        // standard accessible pattern for star ratings.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rating")
        .accessibilityValue(rating == 0 ? "No rating selected" : "\(rating) of \(maxRating) stars")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: rating = min(rating + 1, maxRating)
            case .decrement: rating = max(rating - 1, 0)
            default: break
            }
        }
    }
}
