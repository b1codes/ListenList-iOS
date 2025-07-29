// ListenList/ListenList/Tabs/ListenListView.swift

import SwiftUI
import FirebaseFirestore

struct ListenListView: View {
    
    @State private var cards: [Card] = [] // Holds the list of cards
    @State private var songs: [Song] = []   // Use the SwiftUI-compatible Song type
    @State private var albums: [Album] = []
    @State private var artists: [Artist] = []
    @State private var isLoading = true     // Track loading state
    @State private var isInEditMode = false // State for edit mode

    func createCard(from song: Song) -> Card {
        let media = Media(input: .song(song))
        return Card(input: .song, media: media, id: song.id)
    }
    
    func createCard(from album: Album) -> Card {
        let media = Media(input: .album(album))
        return Card(input: .album, media: media, id: album.id)
    }
    
    func createCard(from artist: Artist) -> Card {
        let media = Media(input: .artist(artist))
        return Card(input: .artist, media: media, id: artist.id)
    }
    
    func fetchListenList() {
        isLoading = true
        let group = DispatchGroup()
        
        var fetchedSongs: [Song] = []
        var fetchedAlbums: [Album] = []
        var fetchedArtists: [Artist] = []
        
        group.enter()
        fetchSongList { songs in
            fetchedSongs = songs
            group.leave()
        }
        
        group.enter()
        fetchAlbumList { albums in
            fetchedAlbums = albums
            group.leave()
        }
        
        group.enter()
        fetchArtistList { artists in
            fetchedArtists = artists
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.songs = fetchedSongs
            self.albums = fetchedAlbums
            self.artists = fetchedArtists
            updateUI()
        }
    }
    
    func fetchSongList(completion: @escaping ([Song]) -> Void) {
        var songIds: [String] = []
        
        DatabaseManager.shared.fetchSongIds { documents, error in
            if let error = error {
                print("Error fetching song IDs: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let documents = documents else {
                print("No song documents found.")
                completion([])
                return
            }
            
            songIds = documents.map { $0.documentID }
            
            var fetchedSongs: [Song] = []
            let group = DispatchGroup()
            
            for songId in songIds {
                group.enter()
                DatabaseManager.shared.fetchSong(withId: songId) { songDTO, error in
                    defer { group.leave() }
                    
                    if let error = error {
                        print("Error fetching song with ID \(songId): \(error.localizedDescription)")
                        return
                    }
                    
                    guard let songDTO = songDTO else {
                        print("No songDTO found for ID \(songId).")
                        return
                    }
                    
                    group.enter()
                    SongDTO.toSong(from: songDTO) { song in
                        if let song = song {
                            fetchedSongs.append(song)
                        } else {
                            print("Failed to convert songDTO to Song for ID \(songId).")
                        }
                        group.leave()
                    }
                }
            }
            
            group.notify(queue: .main) {
                completion(fetchedSongs)
            }
        }
    }

    func fetchAlbumList(completion: @escaping ([Album]) -> Void) {
        DatabaseManager.shared.db.collection("albums").whereField("showOnList", isEqualTo: true).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching albums: \(error.localizedDescription)")
                completion([])
                return
            }

            guard let documents = snapshot?.documents else {
                completion([])
                return
            }

            var fetchedAlbums: [Album] = []
            let group = DispatchGroup()

            for document in documents {
                group.enter()
                DatabaseManager.shared.fetchAlbum(withId: document.documentID) { album in
                    if let album = album {
                        fetchedAlbums.append(album)
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                completion(fetchedAlbums)
            }
        }
    }
    
    func fetchArtistList(completion: @escaping ([Artist]) -> Void) {
        DatabaseManager.shared.db.collection("artists").whereField("showOnList", isEqualTo: true).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching artists: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion([])
                return
            }
            
            var fetchedArtists: [Artist] = []
            let group = DispatchGroup()
            
            for document in documents {
                group.enter()
                ArtistDTO.toArtist(from: document.reference) { artist in
                    if let artist = artist {
                        fetchedArtists.append(artist)
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                completion(fetchedArtists)
            }
        }
    }

    private func updateUI() {
        let songCards = self.songs.map { createCard(from: $0) }
        let albumCards = self.albums.map { createCard(from: $0) }
        let artistCards = self.artists.map { createCard(from: $0) }
        self.cards = songCards + albumCards + artistCards
        self.isLoading = false
        print("Successfully loaded \(self.songs.count) songs, \(self.albums.count) albums, and \(self.artists.count) artists.")
    }

    private func delete(card: Card) {
        switch card.type {
        case .song:
            DatabaseManager.shared.deleteSong(withId: card.id) { error in
                if let error = error {
                    print("Error deleting song: \(error.localizedDescription)")
                } else {
                    fetchListenList()
                }
            }
        case .album:
            DatabaseManager.shared.deleteAlbum(withId: card.id) { error in
                if let error = error {
                    print("Error deleting album: \(error.localizedDescription)")
                } else {
                    fetchListenList()
                }
            }
        case .artist:
            DatabaseManager.shared.deleteArtist(withId: card.id) { error in
                if let error = error {
                    print("Error deleting artist: \(error.localizedDescription)")
                } else {
                    fetchListenList()
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    if isLoading {
                        ProgressView("Loading...")
                    } else if cards.isEmpty {
                        Text("No items found.")
                    } else {
                        CardList(results: self.cards, isInEditMode: isInEditMode, onDelete: delete)
                    }
                }
            }
            .navigationTitle("Your ListenList")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isInEditMode ? "Done" : "Edit") {
                        withAnimation {
                            isInEditMode.toggle()
                        }
                    }
                }
            }
            .onAppear {
                fetchListenList()
            }
        }
    }
}
