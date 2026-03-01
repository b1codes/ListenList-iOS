// ListenList/ListenList/Managers/ListManager.swift

import SwiftUI
import FirebaseFirestore

@MainActor
class ListManager: ObservableObject {
    @Published var cards: [Card] = []
    @Published var completedCards: [Card] = []
    @Published var isLoading = false
    
    private var songs: [Song] = []
    private var albums: [Album] = []
    private var artists: [Artist] = []
    private var podcasts: [Podcast] = []
    private var audiobooks: [Audiobook] = []
    
    static let shared = ListManager()
    
    private init() {}
    
    func fetchListenList(forceReload: Bool = false) async {
        if !forceReload && !cards.isEmpty {
            return
        }
        
        if cards.isEmpty {
            isLoading = true
        }
        
        async let fetchedSongs = fetchSongList()
        async let fetchedAlbums = fetchAlbumList()
        async let fetchedArtists = fetchArtistList()
        async let fetchedPodcasts = fetchPodcastList()
        async let fetchedAudiobooks = fetchAudiobookList()
        
        self.songs = await fetchedSongs
        self.albums = await fetchedAlbums
        self.artists = await fetchedArtists
        self.podcasts = await fetchedPodcasts
        self.audiobooks = await fetchedAudiobooks
        
        self.updateUI()
    }
    
    private func fetchSongList() async -> [Song] {
        await withCheckedContinuation { continuation in
            var songIds: [String] = []
            
            DatabaseManager.shared.fetchSongIds { documents, error in
                if let error = error {
                    print("Error fetching song IDs: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                    return
                }
                
                guard let documents = documents else {
                    continuation.resume(returning: [])
                    return
                }
                
                songIds = documents.map { $0.documentID }
                
                if songIds.isEmpty {
                    continuation.resume(returning: [])
                    return
                }
                
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
                    continuation.resume(returning: fetchedSongs)
                }
            }
        }
    }

    private func fetchAlbumList() async -> [Album] {
        await withCheckedContinuation { continuation in
            DatabaseManager.shared.db.collection("albums").whereField("showOnList", isEqualTo: true).getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching albums: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                    return
                }

                guard let documents = snapshot?.documents else {
                    continuation.resume(returning: [])
                    return
                }
                
                if documents.isEmpty {
                    continuation.resume(returning: [])
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
                    continuation.resume(returning: fetchedAlbums)
                }
            }
        }
    }
    
    private func fetchArtistList() async -> [Artist] {
        await withCheckedContinuation { continuation in
            DatabaseManager.shared.db.collection("artists").whereField("showOnList", isEqualTo: true).getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching artists: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    continuation.resume(returning: [])
                    return
                }
                
                if documents.isEmpty {
                    continuation.resume(returning: [])
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
                    continuation.resume(returning: fetchedArtists)
                }
            }
        }
    }

    private func fetchPodcastList() async -> [Podcast] {
        await withCheckedContinuation { continuation in
            DatabaseManager.shared.db.collection("podcasts").getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching podcasts: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                    return
                }

                guard let documents = snapshot?.documents else {
                    continuation.resume(returning: [])
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
                    let rating = data["rating"] as? Int
                    let comment = data["comment"] as? String
                    let isCompleted = data["isCompleted"] as? Bool ?? false
                    return Podcast(id: id, name: name, publisher: publisher, images: images, explicit: explicit, description: description, total_episodes: total_episodes, rating: rating, comment: comment, isCompleted: isCompleted)
                }
                continuation.resume(returning: podcasts)
            }
        }
    }

    private func fetchAudiobookList() async -> [Audiobook] {
        await withCheckedContinuation { continuation in
            DatabaseManager.shared.db.collection("audiobooks").getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching audiobooks: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                    return
                }

                guard let documents = snapshot?.documents else {
                    continuation.resume(returning: [])
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
                    let rating = data["rating"] as? Int
                    let comment = data["comment"] as? String
                    let isCompleted = data["isCompleted"] as? Bool ?? false
                    return Audiobook(id: id, name: name, authors: authors, images: images, explicit: explicit, description: description, edition: edition, narrators: narrators, publisher: publisher, total_chapters: total_chapters, rating: rating, comment: comment, isCompleted: isCompleted)
                }
                continuation.resume(returning: audiobooks)
            }
        }
    }

    private func updateUI() {
        let songCards = self.songs.filter { !($0.isCompleted ?? false) }.map { createCard(from: $0) }
        let albumCards = self.albums.filter { !($0.isCompleted ?? false) }.map { createCard(from: $0) }
        let artistCards = self.artists.map { createCard(from: $0) } // Artists don't have isCompleted for now
        let podcastCards = self.podcasts.filter { !($0.isCompleted ?? false) }.map { createCard(from: $0) }
        let audiobookCards = self.audiobooks.filter { !($0.isCompleted ?? false) }.map { createCard(from: $0) }
        self.cards = songCards + albumCards + artistCards + podcastCards + audiobookCards
        
        let completedSongCards = self.songs.filter { $0.isCompleted ?? false }.map { createCard(from: $0) }
        let completedAlbumCards = self.albums.filter { $0.isCompleted ?? false }.map { createCard(from: $0) }
        let completedPodcastCards = self.podcasts.filter { $0.isCompleted ?? false }.map { createCard(from: $0) }
        let completedAudiobookCards = self.audiobooks.filter { $0.isCompleted ?? false }.map { createCard(from: $0) }
        self.completedCards = completedSongCards + completedAlbumCards + completedPodcastCards + completedAudiobookCards
        
        self.isLoading = false
    }
    
    private func createCard(from song: Song) -> Card {
        let media = Media(input: .song(song))
        return Card(input: .song, media: media, id: song.id)
    }
    
    private func createCard(from album: Album) -> Card {
        let media = Media(input: .album(album))
        return Card(input: .album, media: media, id: album.id)
    }
    
    private func createCard(from artist: Artist) -> Card {
        let media = Media(input: .artist(artist))
        return Card(input: .artist, media: media, id: artist.id)
    }

    private func createCard(from podcast: Podcast) -> Card {
        let media = Media(input: .podcast(podcast))
        return Card(input: .podcast, media: media, id: podcast.id)
    }

    private func createCard(from audiobook: Audiobook) -> Card {
        let media = Media(input: .audiobook(audiobook))
        return Card(input: .audiobook, media: media, id: audiobook.id)
    }
    
    func delete(card: Card) {
        // Optimistic delete
        withAnimation {
            cards.removeAll { $0.id == card.id }
            
            // Also remove from the underlying source arrays to keep state consistent
            switch card.type {
            case .song:
                songs.removeAll { $0.id == card.id }
            case .album:
                albums.removeAll { $0.id == card.id }
            case .artist:
                artists.removeAll { $0.id == card.id }
            case .podcast:
                podcasts.removeAll { $0.id == card.id }
            case .audiobook:
                audiobooks.removeAll { $0.id == card.id }
            }
        }
        
        switch card.type {
        case .song:
            DatabaseManager.shared.deleteSong(withId: card.id) { error in
                if let error = error {
                    print("Error deleting song: \(error.localizedDescription)")
                    Task { @MainActor in await self.fetchListenList(forceReload: true) }
                }
            }
        case .album:
            DatabaseManager.shared.updateAlbumShowOnList(withId: card.id, showOnList: false) { error in
                if let error = error {
                    print("Error updating album: \(error.localizedDescription)")
                    Task { @MainActor in await self.fetchListenList(forceReload: true) }
                }
            }
        case .artist:
            DatabaseManager.shared.updateArtistShowOnList(withId: card.id, showOnList: false) { error in
                if let error = error {
                    print("Error updating artist: \(error.localizedDescription)")
                    Task { @MainActor in await self.fetchListenList(forceReload: true) }
                }
            }
        case .podcast:
            DatabaseManager.shared.deletePodcast(withId: card.id) { error in
                if let error = error {
                    print("Error deleting podcast: \(error.localizedDescription)")
                    Task { @MainActor in await self.fetchListenList(forceReload: true) }
                }
            }
        case .audiobook:
            DatabaseManager.shared.deleteAudiobook(withId: card.id) { error in
                if let error = error {
                    print("Error deleting audiobook: \(error.localizedDescription)")
                    Task { @MainActor in await self.fetchListenList(forceReload: true) }
                }
            }
        }
    }
}
