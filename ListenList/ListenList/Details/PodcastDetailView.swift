// ListenList/ListenList/Details/PodcastDetailView.swift

import SwiftUI

struct PodcastDetailView: View {
    var podcast: Podcast
    @EnvironmentObject var listManager: ListManager

    @State private var rating = 0
    @State private var comment = ""
    @State private var isAlreadyCompleted = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header section
                HStack(alignment: .top, spacing: 15) {
                    if let imageUrl = podcast.images.first?.url, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } else {
                                Color.gray
                            }
                        }
                        .frame(width: 120, height: 120)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text(podcast.name)
                            .font(.title3)
                            .bold()

                        Text(podcast.publisher)
                            .font(.headline)
                            .foregroundColor(.secondary)

                        HStack {
                            Text("\(podcast.totalEpisodes) Episodes")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            if podcast.explicit {
                                Image(systemName: "e.square.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal)

                Divider()

                if !listManager.isItemInList(id: podcast.id) {
                    Button(action: {
                        listManager.add(media: Media(input: .podcast(podcast)))
                    }) {
                        Label("Add to Library", systemImage: "plus.circle")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                }

                MediaLoggingView(
                    rating: $rating,
                    comment: $comment,
                    isAlreadyCompleted: isAlreadyCompleted,
                    action: logAsCompleted
                )

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Description")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)

                    Text(podcast.description)
                        .font(.body)
                        .padding(.horizontal)
                }
            }
            .padding(.top, 20)
        }
        .navigationTitle("Podcast Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let podcastRating = podcast.rating {
                self.rating = podcastRating
                self.isAlreadyCompleted = true
            }
            if let podcastComment = podcast.comment {
                self.comment = podcastComment
            }
        }
    }

    private func logAsCompleted() {
        DatabaseManager.shared.logPodcastAsCompleted(withId: podcast.id, rating: rating, comment: comment) { error in
            if let error = error {
                print("Error logging podcast as completed: \(error.localizedDescription)")
            } else {
                Task { @MainActor in
                    await ListManager.shared.fetchListenList(forceReload: true)
                }
            }
        }
    }
}
