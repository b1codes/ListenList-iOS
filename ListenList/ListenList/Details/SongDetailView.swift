// ListenList/ListenList/Details/SongDetailView.swift

import SwiftUI

struct SongDetailView: View {
    var song: Song

    @State private var rating = 0
    @State private var comment = ""
    @State private var isAlreadyCompleted = false

    private func artistsToStr() -> String {
        return song.artists.map { $0.name }.joined(separator: ", ")
    }

    private func durationToStr() -> String {
        let seconds = song.durationMs / 1000
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 30) {
                // Large Album Art
                if let imageUrl = song.album.images.first?.url, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } else {
                            Color.gray
                        }
                    }
                    .frame(maxWidth: 300)
                    .cornerRadius(20)
                    .shadow(radius: 15)
                }

                VStack(spacing: 10) {
                    Text(song.name)
                        .font(.title)
                        .bold()
                        .multilineTextAlignment(.center)

                    Text(artistsToStr())
                        .font(.title3)
                        .foregroundColor(.secondary)

                    Text(song.album.name)
                        .font(.headline)
                        .foregroundColor(.accentColor)
                }
                .padding(.horizontal)

                Divider()

                // Detailed Stats
                HStack(spacing: 40) {
                    VStack {
                        Text("Duration")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(durationToStr())
                            .font(.headline)
                    }

                    VStack {
                        Text("Popularity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(song.popularity)%")
                            .font(.headline)
                    }

                    if song.explicit {
                        VStack {
                            Text("Content")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Image(systemName: "e.square.fill")
                                .font(.headline)
                        }
                    }
                }

                Divider()

                // Log as Completed Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Log as Completed")
                        .font(.headline)

                    HStack {
                        Text("Rating:")
                        RatingView(rating: $rating)
                    }

                    TextField("Optional Comment", text: $comment)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button(action: logAsCompleted) {
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

                Spacer()
            }
            .padding(.top, 20)
        }
        .navigationTitle("Song Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let songRating = song.rating {
                self.rating = songRating
                self.isAlreadyCompleted = true
            }
            if let songComment = song.comment {
                self.comment = songComment
            }
        }
    }

    private func logAsCompleted() {
        DatabaseManager.shared.logSongAsCompleted(withId: song.id, rating: rating, comment: comment) { error in
            if let error = error {
                print("Error logging song as completed: \(error.localizedDescription)")
            } else {
                Task { @MainActor in
                    await ListManager.shared.fetchListenList(forceReload: true)
                }
            }
        }
    }
}
