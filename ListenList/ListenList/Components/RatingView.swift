// ListenList/ListenList/Components/RatingView.swift

import SwiftUI

struct RatingView: View {
    @Binding var rating: Int
    var maxRating = 5
    
    var body: some View {
        HStack {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .foregroundColor(index <= rating ? .yellow : .gray)
                    .onTapGesture {
                        rating = index
                    }
            }
        }
    }
}
