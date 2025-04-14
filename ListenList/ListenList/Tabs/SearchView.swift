import SwiftUI

struct SearchView: View {
    var searchManager: SpotifyAPIManager
    var accessToken: String
    var tokenType: String
    @State private var cards = [Card]()
    @State private var searchBy = 0
    @State private var searchText: String = ""
    @State private var isLoading = false
    @FocusState private var isTextFieldFocused: Bool // Focus management for TextField
    @State private var currentSearchTask: Task<Void, Never>? = nil

    
    init(access: String, type: String) {
        self.accessToken = access
        self.tokenType = type
        self.searchManager = SpotifyAPIManager(access: access, token: type)
        self.cards = []
    }
    
    @MainActor
    func performSearch() async -> [Card] {
        self.isLoading = true
        defer { self.isLoading = false }

        switch self.searchBy {
            case 0: return await searchAlbums()
            case 1: return await searchArtists()
            default: return await searchSongs()
        }
    }

    func searchAlbums() async -> [Card] {
        do {
            if let albumSearchResults = try await searchManager.search(query: searchText, type: "album"),
               let albums = albumSearchResults.albums {
                return albums.items.map { album in
                    let artists = album.artists?.map { Artist(id: $0.id, name: $0.name, artistId: $0.id) } ?? []
                    return Card(input: .album, media: Media(input: .album(Album(id: album.id, images: album.images, name: album.name, release_date: album.release_date, artists: artists))), id: album.id)
                }
            }
        } catch {
            print("Error during album search: \(error)")
        }
        return []
    }

    func searchSongs() async -> [Card] {
        do {
            if let songSearchResults = try await searchManager.search(query: searchText, type: "track"),
               let songs = songSearchResults.tracks {
                
                return songs.items.map { song in
                    let albumArtists = song.album.artists?.map { Artist(id: $0.id, name: $0.name, artistId: $0.id) } ?? []
                    let songArtists = song.artists.map { Artist(id: $0.id, name: $0.name, artistId: $0.id) }
                    return Card(input: .song, media: Media(input: .song(Song(id: song.id, album: Album(id: song.album.id, images: song.album.images, name: song.album.name, release_date: song.album.release_date, artists: albumArtists), artists: songArtists, duration_ms: song.duration_ms, name: song.name, popularity: song.popularity, explicit: song.explicit))), id: song.id)
                    
                }
            }
        } catch {
            print("Error during song search: \(error)")
        }
        return []
    }
    
    func searchArtists() async -> [Card] {
        do {
            if let artistSearchResults = try await searchManager.search(query: searchText, type: "artist"),
               let artists = artistSearchResults.artists {
                    
                    return artists.items.map { artist in
                        return Card(input: .artist, media: Media(input: .artist(Artist(id: artist.id, images: artist.images, name: artist.name, popularity: artist.popularity, artistId: artist.id))), id: artist.id)
                    
                }
            }
        } catch {
            print("Error during song search: \(error)")
        }
        return []
    }
    
    @MainActor
    func startSearch() async {
        guard !self.searchText.isEmpty else { return }
        
        // Cancel any ongoing search
        currentSearchTask?.cancel()
        
        let thisQuery = self.searchText
        self.isLoading = true
        self.cards = []
        self.isTextFieldFocused = false
        
        // Create a new task for the search
        currentSearchTask = Task {
            let results: [Card] = await performSearch()
            
            // Check if the search text hasn’t changed in the meantime
            if self.searchText == thisQuery {
                self.cards = results
            }
            self.isLoading = false
            print("done searching!")
        }
    }


    func resetSearch() {
        // Reset all states explicitly
        searchText = ""
        cards = []
        isLoading = false
        isTextFieldFocused = false // Clear keyboard focus
    }



    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    Picker(selection: $searchBy, label: Text("Search Filter")) {
                        Text("Album").tag(0)
                        Text("Artist").tag(1)
                        Text("Song").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()

                    
                    HStack {
                        TextField("Search...", text: $searchText)
                            .focused($isTextFieldFocused)
                            .onChange(of: searchText) {
                                print("Search text changed to: \(searchText)")
                            }
                            .onSubmit {
                                Task { await startSearch() }
                            }
                            .padding(7)
                            .padding(.horizontal, 25)
                            .background(Color(.systemGray4))
                            .cornerRadius(8)
                            .padding(.horizontal, 10)
                        
                        if !searchText.isEmpty {
                            Button("Cancel") {
                                resetSearch()
                            }
                            .foregroundColor(.blue)
                            .padding(.trailing, 10)
                        }
                    }
                    
                    if isLoading {
                        ProgressView("Searching...").padding()
                    }
                    
                    CardList(results: cards)
                }
                
            }
            .onTapGesture { isTextFieldFocused = false }
            .navigationTitle("Search")
        }
    }



}
