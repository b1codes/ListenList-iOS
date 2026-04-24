// ListenList/ListenList/Components/MediaLoggingView.swift

import SwiftUI

struct MediaLoggingView: View {
    @Binding var rating: Int
    @Binding var comment: String
    var isAlreadyCompleted: Bool
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Log as Completed")
                .font(.headline)

            HStack {
                Text("Rating:")
                RatingView(rating: $rating)
            }

            TextField("Optional Comment", text: $comment)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button(action: action) {
                Text(isAlreadyCompleted ? "Update Completion" : "Log as Completed")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}
