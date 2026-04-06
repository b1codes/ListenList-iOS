// ListenList/ListenList/Managers/ListManager.swift

import SwiftUI

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

    let db: DatabaseService

    static let shared = ListManager()

    init(db: DatabaseService = DatabaseManager.shared) {
        self.db = db
    }

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
            db.fetchSongs { songs in
                continuation.resume(returning: songs)
            }
        }
    }

    private func fetchAlbumList() async -> [Album] {
        await withCheckedContinuation { continuation in
            db.fetchAlbums { albums in
                continuation.resume(returning: albums)
            }
        }
    }

    private func fetchArtistList() async -> [Artist] {
        await withCheckedContinuation { continuation in
            db.fetchArtists { artists in
                continuation.resume(returning: artists)
            }
        }
    }

    private func fetchPodcastList() async -> [Podcast] {
        await withCheckedContinuation { continuation in
            db.fetchPodcasts { podcasts in
                continuation.resume(returning: podcasts)
            }
        }
    }

    private func fetchAudiobookList() async -> [Audiobook] {
        await withCheckedContinuation { continuation in
            db.fetchAudiobooks { audiobooks in
                continuation.resume(returning: audiobooks)
            }
        }
    }

    private func updateUI() {
        let songCards = self.songs.filter { !($0.isCompleted ?? false) }.map { createCard(from: $0) }
        let albumCards = self.albums.filter { !($0.isCompleted ?? false) }.map { createCard(from: $0) }
        let artistCards = self.artists.map { createCard(from: $0) }
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
        Card(input: .song, media: Media(input: .song(song)), id: song.id)
    }

    private func createCard(from album: Album) -> Card {
        Card(input: .album, media: Media(input: .album(album)), id: album.id)
    }

    private func createCard(from artist: Artist) -> Card {
        Card(input: .artist, media: Media(input: .artist(artist)), id: artist.id)
    }

    private func createCard(from podcast: Podcast) -> Card {
        Card(input: .podcast, media: Media(input: .podcast(podcast)), id: podcast.id)
    }

    private func createCard(from audiobook: Audiobook) -> Card {
        Card(input: .audiobook, media: Media(input: .audiobook(audiobook)), id: audiobook.id)
    }

    func delete(card: Card) {
        // Optimistic delete: remove immediately from UI, roll back on error
        withAnimation {
            cards.removeAll { $0.id == card.id }
            completedCards.removeAll { $0.id == card.id }

            switch card.type {
            case .song:      songs.removeAll { $0.id == card.id }
            case .album:     albums.removeAll { $0.id == card.id }
            case .artist:    artists.removeAll { $0.id == card.id }
            case .podcast:   podcasts.removeAll { $0.id == card.id }
            case .audiobook: audiobooks.removeAll { $0.id == card.id }
            }
        }

        switch card.type {
        case .song:
            db.deleteSong(withId: card.id) { error in
                if let error = error {
                    print("Error deleting song: \(error.localizedDescription)")
                    Task { @MainActor in await self.fetchListenList(forceReload: true) }
                }
            }
        case .album:
            db.removeAlbumFromList(withId: card.id) { error in
                if let error = error {
                    print("Error updating album: \(error.localizedDescription)")
                    Task { @MainActor in await self.fetchListenList(forceReload: true) }
                }
            }
        case .artist:
            db.removeArtistFromList(withId: card.id) { error in
                if let error = error {
                    print("Error updating artist: \(error.localizedDescription)")
                    Task { @MainActor in await self.fetchListenList(forceReload: true) }
                }
            }
        case .podcast:
            db.deletePodcast(withId: card.id) { error in
                if let error = error {
                    print("Error deleting podcast: \(error.localizedDescription)")
                    Task { @MainActor in await self.fetchListenList(forceReload: true) }
                }
            }
        case .audiobook:
            db.deleteAudiobook(withId: card.id) { error in
                if let error = error {
                    print("Error deleting audiobook: \(error.localizedDescription)")
                    Task { @MainActor in await self.fetchListenList(forceReload: true) }
                }
            }
        }
    }
}
