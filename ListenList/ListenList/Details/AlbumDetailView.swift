// ListenList/ListenList/Details/AlbumDetailView.swift

import SwiftUI

struct AlbumDetailView: View {
    var album: Album
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var listManager: ListManager
    @State private var tracks: [TrackItem] = []
    @State private var isLoading = true

    @State private var rating = 0
    @State private var comment = ""
    @State private var isAlreadyCompleted = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header: Cover Art and Basic Info
                HStack(alignment: .top, spacing: 20) {
                    if let imageUrl = album.images.first?.url, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } else {
                                Color.gray
                            }
                        }
                        .frame(width: 150, height: 150)
                        .cornerRadius(12)
                        .shadow(radius: 10)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(album.name)
                            .font(.title)
                            .bold()

                        Text(album.artists.map { $0.name }.joined(separator: ", "))
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text(album.albumType.capitalized)
                            .font(.subheadline)

                        Text("Released: \(album.releaseDate)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let label = album.label {
                            Text(label)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .italic()
                        }

                        if let genres = album.genres, !genres.isEmpty {
                            Text(genres.joined(separator: ", "))
                                .font(.caption2)
                                .padding(4)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(4)
                        }

                        if album.isExplicit ?? false {
                            Label("Explicit", systemImage: "e.square.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()

                Divider()

                if !listManager.isItemInList(id: album.id) {
                    Button(action: {
                        listManager.add(media: Media(input: .album(album)))
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

                // Track List
                VStack(alignment: .leading) {
                    Text("Tracks")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)

                    if isLoading {
                        ProgressView("Loading tracks...")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else if tracks.isEmpty {
                        Text("No tracks found.")
                            .padding()
                    } else {
                        ForEach(Array(tracks.enumerated()), id: \.offset) { index, track in
                            let song = Song(
                                id: track.id,
                                album: album,
                                artists: track.artists.map { Artist(id: $0.id, name: $0.name, artistId: $0.id) },
                                durationMs: track.durationMs,
                                name: track.name,
                                popularity: 0,
                                explicit: track.explicit
                            )
                            NavigationLink(destination: SongDetailView(song: song)) {
                                HStack {
                                    Text("\(index + 1)")
                                        .foregroundColor(.secondary)
                                        .frame(width: 20)

                                    Text(track.name)
                                        .font(.body)
                                        .foregroundColor(.primary)

                                    Spacer()

                                    if track.explicit {
                                        Image(systemName: "e.square.fill")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Album Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchTracks()
            if let albumRating = album.rating {
                self.rating = albumRating
                self.isAlreadyCompleted = true
            }
            if let albumComment = album.comment {
                self.comment = albumComment
            }
        }
    }

    private func fetchTracks() {
        guard let accessToken = authManager.accessToken, let tokenType = authManager.tokenType else { return }
        let spotifyManager = SpotifyAPIManager(access: accessToken, token: tokenType)

        Task {
            do {
                if let response = try await spotifyManager.getAlbumTracks(albumId: album.id) {
                    self.tracks = response.items
                }
                self.isLoading = false
            } catch {
                print("Error fetching album tracks: \(error)")
                self.isLoading = false
            }
        }
    }

    private func logAsCompleted() {
        DatabaseManager.shared.logAlbumAsCompleted(withId: album.id, rating: rating, comment: comment) { error in
            if let error = error {
                print("Error logging album as completed: \(error.localizedDescription)")
            } else {
                Task { @MainActor in
                    await ListManager.shared.fetchListenList(forceReload: true)
                }
            }
        }
    }
}
