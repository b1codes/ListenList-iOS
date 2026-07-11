// ListenList/ListenList/Details/SongDetailView.swift

import SwiftUI

struct SongDetailView: View {
    @State var song: Song
    @EnvironmentObject var listManager: ListManager
    @EnvironmentObject var authManager: AuthManager

    @State private var rating = 0
    @State private var comment = ""
    @State private var isAlreadyCompleted = false
    @State private var isAdding = false
    @State private var isLogging = false
    @State private var errorAlertMessage: String?

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
                if let imageUrl = song.album.images.largest(), let url = URL(string: imageUrl) {
                    CachedAsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView().tint(.white)
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

                if !listManager.isItemInList(id: song.id) {
                    Divider()

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
                }

                Divider()

                MediaLoggingView(
                    rating: $rating,
                    comment: $comment,
                    isAlreadyCompleted: isAlreadyCompleted,
                    isSubmitting: isLogging,
                    action: logAsCompleted
                )

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
            fetchFullDetails()
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
        listManager.add(media: Media(input: .song(song))) { _ in
            isAdding = false
        }
    }

    private func fetchFullDetails() {
        // If popularity is 0, it might be a partial song from an album track list.
        guard song.popularity == 0 else { return }
        
        guard let accessToken = authManager.accessToken, let tokenType = authManager.tokenType else { return }
        let spotifyManager = SpotifyAPIManager(access: accessToken, token: tokenType)
        
        Task {
            do {
                if let songResponse = try await spotifyManager.getTrack(id: song.id) {
                    let albumArtists = songResponse.album.artists?.map { Artist(id: $0.id, name: $0.name, artistId: $0.id) } ?? []
                    let songArtists = songResponse.artists.map { Artist(id: $0.id, name: $0.name, artistId: $0.id) }
                    let album = Album(id: songResponse.album.id, images: songResponse.album.images, name: songResponse.album.name, releaseDate: songResponse.album.releaseDate, artists: albumArtists, albumType: songResponse.album.albumType)
                    
                    let updatedSong = Song(
                        id: songResponse.id,
                        album: album,
                        artists: songArtists,
                        durationMs: songResponse.durationMs,
                        name: songResponse.name,
                        popularity: songResponse.popularity,
                        explicit: songResponse.explicit,
                        rating: song.rating,
                        comment: song.comment,
                        isCompleted: song.isCompleted
                    )
                    
                    self.song = updatedSong
                }
            } catch {
                print("Error fetching full song details: \(error)")
            }
        }
    }

    private func logAsCompleted() {
        isLogging = true
        DatabaseManager.shared.logSongAsCompleted(withId: song.id, rating: rating, comment: comment) { error in
            Task { @MainActor in
                isLogging = false
                if let error = error {
                    print("Error logging song as completed: \(error.localizedDescription)")
                    errorAlertMessage = "Couldn't save your rating. \(error.localizedDescription)"
                } else {
                    isAlreadyCompleted = true
                    await ListManager.shared.fetchListenList(forceReload: true)
                }
            }
        }
    }
}
