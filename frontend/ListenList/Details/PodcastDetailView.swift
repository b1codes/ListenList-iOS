// ListenList/ListenList/Details/PodcastDetailView.swift

import SwiftUI

struct PodcastDetailView: View {
    var podcast: Podcast
    @EnvironmentObject var listManager: ListManager

    @State private var rating = 0
    @State private var comment = ""
    @State private var isAlreadyCompleted = false
    @State private var isAdding = false
    @State private var isLogging = false
    @State private var errorAlertMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header section
                HStack(alignment: .top, spacing: 15) {
                    if let imageUrl = podcast.images.largest(), let url = URL(string: imageUrl) {
                        CachedAsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            ProgressView().tint(.white)
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
                    Button(action: addToLibrary) {
                        HStack {
                            if isAdding {
                                ProgressView().tint(.white)
                            }
                            Label("Add to Library", systemImage: "plus.circle")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isAdding)
                    .padding(.horizontal)

                    Divider()
                }

                MediaLoggingView(
                    rating: $rating,
                    comment: $comment,
                    isAlreadyCompleted: isAlreadyCompleted,
                    isSubmitting: isLogging,
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
        .alert(
            "Something Went Wrong",
            isPresented: Binding(
                get: { errorAlertMessage != nil },
                set: { isPresented in if !isPresented { errorAlertMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorAlertMessage ?? "")
        }
    }

    private func addToLibrary() {
        isAdding = true
        listManager.add(media: Media(input: .podcast(podcast))) { _ in
            isAdding = false
        }
    }

    private func logAsCompleted() {
        isLogging = true
        DatabaseManager.shared.logPodcastAsCompleted(withId: podcast.id, rating: rating, comment: comment) { error in
            Task { @MainActor in
                isLogging = false
                if let error = error {
                    print("Error logging podcast as completed: \(error.localizedDescription)")
                    errorAlertMessage = "Couldn't save your rating. \(error.localizedDescription)"
                } else {
                    isAlreadyCompleted = true
                    await ListManager.shared.fetchListenList(forceReload: true)
                }
            }
        }
    }
}
