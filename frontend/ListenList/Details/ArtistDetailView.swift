// ListenList/ListenList/Details/ArtistDetailView.swift

import SwiftUI

struct ArtistDetailView: View {
    var artist: Artist
    @EnvironmentObject var listManager: ListManager
    @EnvironmentObject var authManager: AuthManager

    @State private var topTracks: [Song] = []
    @State private var albums: [Album] = []
    @State private var isLoading = true
    @State private var isAdding = false

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 30) {
                // Large Artist Image
                if let imageUrl = artist.images?.largest(), let url = URL(string: imageUrl) {
                    CachedAsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Color.gray
                    }
                    .frame(maxWidth: 300)
                    .clipShape(Circle())
                    .shadow(radius: 15)
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 10) {
                    Text(artist.name)
                        .font(.largeTitle)
                        .bold()
                        .multilineTextAlignment(.center)

                    if let popularity = artist.popularity {
                        HStack {
                            Text("Popularity:")
                                .foregroundColor(.secondary)
                            Text("\(popularity)%")
                                .bold()
                        }
                        .font(.headline)
                    }
                    if let genres = artist.genres, !genres.isEmpty {
                        Text(genres.joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal)

                Divider()

                if !listManager.isItemInList(id: artist.id) {
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

                if isLoading {
                    ProgressView("Loading content...")
                        .padding()
                } else {
                    if !topTracks.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Top Tracks")
                                .font(.title2)
                                .bold()
                                .padding(.horizontal)
                            
                            ForEach(topTracks.prefix(5)) { song in
                                NavigationLink(destination: SongDetailView(song: song)) {
                                    HStack {
                                        if let imageUrl = song.album.images.medium(), let url = URL(string: imageUrl) {
                                            CachedAsyncImage(url: url) { image in
                                                image.resizable()
                                            } placeholder: {
                                                ProgressView().tint(.white)
                                            }
                                            .frame(width: 50, height: 50)
                                            .cornerRadius(5)
                                        }
                                        
                                        VStack(alignment: .leading) {
                                            Text(song.name)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            Text(song.album.name)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        if song.explicit {
                                            Image(systemName: "e.square.fill")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        Divider()
                    }
                    
                    if !albums.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Albums")
                                .font(.title2)
                                .bold()
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(albums) { album in
                                        NavigationLink(destination: AlbumDetailView(album: album)) {
                                            VStack(alignment: .leading) {
                                                if let imageUrl = album.images.medium(), let url = URL(string: imageUrl) {
                                                    CachedAsyncImage(url: url) { image in
                                                        image.resizable()
                                                    } placeholder: {
                                                        Color.gray
                                                    }
                                                    .frame(width: 140, height: 140)
                                                    .cornerRadius(10)
                                                }
                                                
                                                Text(album.name)
                                                    .font(.caption)
                                                    .bold()
                                                    .foregroundColor(.primary)
                                                    .lineLimit(2)
                                                    .frame(width: 140, alignment: .leading)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        Divider()
                    }
                }

                // Placeholder for Top Tracks or Albums could go here
                VStack(alignment: .leading, spacing: 10) {
                    Text("About")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)

                    Text("\(artist.name) is a Spotify artist.")
                        .font(.body)
                        .padding(.horizontal)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.top, 20)
        }
        .navigationTitle("Artist Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchArtistContent()
        }
    }

    private func addToLibrary() {
        isAdding = true
        listManager.add(media: Media(input: .artist(artist))) { _ in
            isAdding = false
        }
    }

    private func fetchArtistContent() {
        guard let accessToken = authManager.accessToken, let tokenType = authManager.tokenType else {
            isLoading = false
            return
        }
        let spotifyManager = SpotifyAPIManager(access: accessToken, token: tokenType)
        
        Task {
            do {
                async let tracksResponse = spotifyManager.getArtistTopTracks(artistId: artist.id)
                async let albumsResponse = spotifyManager.getArtistAlbums(artistId: artist.id)
                
                let (tracks, albums) = try await (tracksResponse, albumsResponse)
                
                if let trackItems = tracks?.tracks {
                    self.topTracks = trackItems.map { song in
                        let albumArtists = song.album.artists?.map { Artist(id: $0.id, name: $0.name, artistId: $0.id) } ?? []
                        let songArtists = song.artists.map { Artist(id: $0.id, name: $0.name, artistId: $0.id) }
                        let album = Album(id: song.album.id, images: song.album.images, name: song.album.name, releaseDate: song.album.releaseDate, artists: albumArtists, albumType: song.album.albumType)
                        return Song(id: song.id, album: album, artists: songArtists, durationMs: song.durationMs, name: song.name, popularity: song.popularity, explicit: song.explicit)
                    }
                }
                
                if let albumItems = albums?.items {
                    self.albums = albumItems.map { albumResponse in
                        let artists = albumResponse.artists?.map { Artist(id: $0.id, name: $0.name, artistId: $0.id) } ?? []
                        return Album(id: albumResponse.id, images: albumResponse.images, name: albumResponse.name, releaseDate: albumResponse.releaseDate, artists: artists, albumType: albumResponse.albumType)
                    }
                }
                
                self.isLoading = false
            } catch {
                print("Error fetching artist content: \(error)")
                self.isLoading = false
            }
        }
    }
}
