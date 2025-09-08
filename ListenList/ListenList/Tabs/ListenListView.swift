// ListenList/ListenList/Tabs/ListenListView.swift

import SwiftUI
import FirebaseFirestore

struct ListenListView: View {
    
    @State private var cards: [Card] = []
    @State private var songs: [Song] = []
    @State private var albums: [Album] = []
    @State private var artists: [Artist] = []
    @State private var podcasts: [Podcast] = []
    @State private var audiobooks: [Audiobook] = []
    @State private var isLoading = true
    @State private var isInEditMode = false
    @State private var isGridView = false

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

    func createCard(from podcast: Podcast) -> Card {
        let media = Media(input: .podcast(podcast))
        return Card(input: .podcast, media: media, id: podcast.id)
    }

    func createCard(from audiobook: Audiobook) -> Card {
        let media = Media(input: .audiobook(audiobook))
        return Card(input: .audiobook, media: media, id: audiobook.id)
    }
    
    func fetchListenList() {
        isLoading = true
        let group = DispatchGroup()
        
        var fetchedSongs: [Song] = []
        var fetchedAlbums: [Album] = []
        var fetchedArtists: [Artist] = []
        var fetchedPodcasts: [Podcast] = []
        var fetchedAudiobooks: [Audiobook] = []
        
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

        group.enter()
        fetchPodcastList { podcasts in
            fetchedPodcasts = podcasts
            group.leave()
        }

        group.enter()
        fetchAudiobookList { audiobooks in
            fetchedAudiobooks = audiobooks
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.songs = fetchedSongs
            self.albums = fetchedAlbums
            self.artists = fetchedArtists
            self.podcasts = fetchedPodcasts
            self.audiobooks = fetchedAudiobooks
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
                        return
                    }
                    
                    group.enter()
                    SongDTO.toSong(from: songDTO) { song in
                        if let song = song {
                            fetchedSongs.append(song)
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

    func fetchPodcastList(completion: @escaping ([Podcast]) -> Void) {
        DatabaseManager.shared.db.collection("podcasts").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching podcasts: \(error.localizedDescription)")
                completion([])
                return
            }

            guard let documents = snapshot?.documents else {
                completion([])
                return
            }

            let podcasts = documents.compactMap { doc -> Podcast? in
                let data = doc.data()
                let id = doc.documentID
                let name = data["name"] as? String ?? ""
                let publisher = data["publisher"] as? String ?? ""
                let imagesData = data["images"] as? [[String: Any]] ?? []
                let images = imagesData.compactMap { ImageDTO.toImageResponse(from: $0) }
                let explicit = data["explicit"] as? Bool ?? false
                let description = data["description"] as? String ?? ""
                let total_episodes = data["total_episodes"] as? Int ?? 0
                return Podcast(id: id, name: name, publisher: publisher, images: images, explicit: explicit, description: description, total_episodes: total_episodes)
            }
            completion(podcasts)
        }
    }

    func fetchAudiobookList(completion: @escaping ([Audiobook]) -> Void) {
        DatabaseManager.shared.db.collection("audiobooks").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching audiobooks: \(error.localizedDescription)")
                completion([])
                return
            }

            guard let documents = snapshot?.documents else {
                completion([])
                return
            }

            let audiobooks = documents.compactMap { doc -> Audiobook? in
                let data = doc.data()
                let id = doc.documentID
                let name = data["name"] as? String ?? ""
                let authorsData = data["authors"] as? [[String: Any]] ?? []
                let authors = authorsData.compactMap { Author(name: $0["name"] as? String ?? "") }
                let imagesData = data["images"] as? [[String: Any]] ?? []
                let images = imagesData.compactMap { ImageDTO.toImageResponse(from: $0) }
                let explicit = data["explicit"] as? Bool ?? false
                let description = data["description"] as? String ?? ""
                let edition = data["edition"] as? String ?? ""
                let narratorsData = data["narrators"] as? [[String: Any]] ?? []
                let narrators = narratorsData.compactMap { Narrator(name: $0["name"] as? String ?? "") }
                let publisher = data["publisher"] as? String ?? ""
                let total_chapters = data["total_chapters"] as? Int ?? 0
                return Audiobook(id: id, name: name, authors: authors, images: images, explicit: explicit, description: description, edition: edition, narrators: narrators, publisher: publisher, total_chapters: total_chapters)
            }
            completion(audiobooks)
        }
    }

    private func updateUI() {
        let songCards = self.songs.map { createCard(from: $0) }
        let albumCards = self.albums.map { createCard(from: $0) }
        let artistCards = self.artists.map { createCard(from: $0) }
        let podcastCards = self.podcasts.map { createCard(from: $0) }
        let audiobookCards = self.audiobooks.map { createCard(from: $0) }
        self.cards = songCards + albumCards + artistCards + podcastCards + audiobookCards
        self.isLoading = false
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
            DatabaseManager.shared.updateArtistShowOnList(withId: card.id, showOnList: false) { error in
                if let error = error {
                    print("Error updating artist: \(error.localizedDescription)")
                } else {
                    fetchListenList()
                }
            }
        case .podcast:
            DatabaseManager.shared.deletePodcast(withId: card.id) { error in
                if let error = error {
                    print("Error deleting podcast: \(error.localizedDescription)")
                } else {
                    fetchListenList()
                }
            }
        case .audiobook:
            DatabaseManager.shared.deleteAudiobook(withId: card.id) { error in
                if let error = error {
                    print("Error deleting audiobook: \(error.localizedDescription)")
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
                        if isGridView {
                            CardGrid(results: self.cards, isInEditMode: isInEditMode, onDelete: delete)
                        } else {
                            CardList(results: self.cards, isInEditMode: isInEditMode, onDelete: delete)
                        }
                    }
                }
            }
            .navigationTitle("Your ListenList")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Picker("View Mode", selection: $isGridView) {
                        Image(systemName: "list.bullet").tag(false)
                        Image(systemName: "square.grid.2x2").tag(true)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
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
