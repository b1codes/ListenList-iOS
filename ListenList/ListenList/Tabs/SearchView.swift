// ListenList/ListenList/Tabs/SearchView.swift

import SwiftUI
import FirebaseFirestore

struct SearchView: View {
    var spotifyManager: SpotifyAPIManager
    var accessToken: String
    var tokenType: String
    
    @EnvironmentObject var listManager: ListManager
    @EnvironmentObject var searchManager: SearchManager
    @Binding var searchText: String
    
    @State private var cards = [Card]()
    @State private var suggestionCards = [Card]()
    @State private var isLoading = false
    @State private var isLoadingSuggestions = false
    @State private var currentSearchTask: Task<Void, Never>? = nil
    @State private var listenListIDs = Set<String>()
    
    init(access: String, type: String, searchText: Binding<String>) {
        self.accessToken = access
        self.tokenType = type
        self.spotifyManager = SpotifyAPIManager(access: access, token: type)
        self._searchText = searchText
        self.cards = []
    }

    func fetchListenListIDs() {
        let collections = ["songs", "albums", "podcasts", "audiobooks"]
        var allIDs = Set<String>()
        let group = DispatchGroup()

        for collection in collections {
            group.enter()
            DatabaseManager.shared.fetchDocumentIds(fromCollection: collection) { ids, error in
                if let error = error {
                    print("Error fetching IDs from \(collection): \(error.localizedDescription)")
                } else {
                    allIDs.formUnion(ids)
                }
                group.leave()
            }
        }

        group.enter()
        DatabaseManager.shared.fetchArtistIdsInListenList { ids, error in
            if let error = error {
                print("Error fetching artist IDs from ListenList: \(error.localizedDescription)")
            } else {
                allIDs.formUnion(ids)
            }
            group.leave()
        }

        group.notify(queue: .main) {
            self.listenListIDs = allIDs
        }
    }
    
    @MainActor
    func fetchSuggestions() async {
        guard searchText.isEmpty else { return }
        self.isLoadingSuggestions = true
        defer { self.isLoadingSuggestions = false }
        
        var contextQueries: [String] = []
        
        if let topArtists = try? await spotifyManager.getTopArtists() {
            contextQueries.append(contentsOf: topArtists.items.prefix(3).map { $0.name })
        }
        if let topTracks = try? await spotifyManager.getTopTracks() {
            contextQueries.append(contentsOf: topTracks.items.prefix(3).map { $0.name })
        }
        
        let highRatedSongs: [String] = await withCheckedContinuation { continuation in
            DatabaseManager.shared.fetchHighRatedMedia(collection: "songs") { docs, error in
                let names = docs?.compactMap { $0.data()["name"] as? String } ?? []
                continuation.resume(returning: names)
            }
        }
        contextQueries.append(contentsOf: highRatedSongs.prefix(3))
        
        let highRatedAlbums: [String] = await withCheckedContinuation { continuation in
            DatabaseManager.shared.fetchHighRatedMedia(collection: "albums") { docs, error in
                let names = docs?.compactMap { $0.data()["name"] as? String } ?? []
                continuation.resume(returning: names)
            }
        }
        contextQueries.append(contentsOf: highRatedAlbums.prefix(3))
        
        do {
            var rawResults: [Card] = []
            
            switch searchManager.searchBy {
            case 0: // Albums
                if let newResults = try? await spotifyManager.search(query: "tag:new", type: "album"), let items = newResults.albums?.items {
                    rawResults.append(contentsOf: items.prefix(3).map { albumResponse in
                        let artists = albumResponse.artists?.map { Artist(id: $0.id, name: $0.name, artistId: $0.id) } ?? []
                        let album = Album(id: albumResponse.id, images: albumResponse.images, name: albumResponse.name, release_date: albumResponse.release_date, artists: artists, album_type: albumResponse.album_type, isExplicit: false)
                        return Card(input: .album, media: Media(input: .album(album)), id: album.id)
                    })
                }
                let seeds = contextQueries.shuffled().prefix(2)
                for seed in seeds {
                    if let contextResults = try? await spotifyManager.search(query: seed, type: "album"),
                       let items = contextResults.albums?.items {
                        rawResults.append(contentsOf: items.prefix(2).map { albumResponse in
                            let artists = albumResponse.artists?.map { Artist(id: $0.id, name: $0.name, artistId: $0.id) } ?? []
                            let album = Album(id: albumResponse.id, images: albumResponse.images, name: albumResponse.name, release_date: albumResponse.release_date, artists: artists, album_type: albumResponse.album_type, isExplicit: false)
                            return Card(input: .album, media: Media(input: .album(album)), id: album.id)
                        })
                    }
                }
                
            case 1: // Artists
                let seeds = contextQueries.shuffled().prefix(3)
                for query in seeds {
                    if let results = try? await spotifyManager.search(query: query, type: "artist"), let items = results.artists?.items {
                        rawResults.append(contentsOf: items.prefix(2).map { artist in
                            return Card(input: .artist, media: Media(input: .artist(Artist(id: artist.id, images: artist.images, name: artist.name, popularity: artist.popularity, artistId: artist.id, genres: artist.genres))), id: artist.id)
                        })
                    }
                }
                
            case 2: // Songs
                if let newResults = try? await spotifyManager.search(query: "tag:new", type: "track"), let items = newResults.tracks?.items {
                    rawResults.append(contentsOf: items.prefix(3).map { song in
                        let albumArtists = song.album.artists?.map { Artist(id: $0.id, name: $0.name, artistId: $0.id) } ?? []
                        let songArtists = song.artists.map { Artist(id: $0.id, name: $0.name, artistId: $0.id) }
                        let album = Album(id: song.album.id, images: song.album.images, name: song.album.name, release_date: song.album.release_date, artists: albumArtists, album_type: song.album.album_type)
                        return Card(input: .song, media: Media(input: .song(Song(id: song.id, album: album, artists: songArtists, duration_ms: song.duration_ms, name: song.name, popularity: song.popularity, explicit: song.explicit))), id: song.id)
                    })
                }
                let seeds = contextQueries.shuffled().prefix(2)
                for seed in seeds {
                    if let contextResults = try? await spotifyManager.search(query: seed, type: "track"),
                       let items = contextResults.tracks?.items {
                        rawResults.append(contentsOf: items.prefix(2).map { song in
                            let albumArtists = song.album.artists?.map { Artist(id: $0.id, name: $0.name, artistId: $0.id) } ?? []
                            let songArtists = song.artists.map { Artist(id: $0.id, name: $0.name, artistId: $0.id) }
                            let album = Album(id: song.album.id, images: song.album.images, name: song.album.name, release_date: song.album.release_date, artists: albumArtists, album_type: song.album.album_type)
                            return Card(input: .song, media: Media(input: .song(Song(id: song.id, album: album, artists: songArtists, duration_ms: song.duration_ms, name: song.name, popularity: song.popularity, explicit: song.explicit))), id: song.id)
                        })
                    }
                }
                
            case 3: // Podcasts
                if let results = try? await spotifyManager.search(query: "podcast", type: "show"), let items = results.shows?.items {
                    rawResults = items.map { show in
                        let podcast = Podcast(id: show.id, name: show.name, publisher: show.publisher, images: show.images, explicit: show.explicit, description: show.description, total_episodes: show.total_episodes)
                        return Card(input: .podcast, media: Media(input: .podcast(podcast)), id: podcast.id)
                    }
                }
                
            case 4: // Audiobooks
                if let results = try? await spotifyManager.search(query: "audiobook", type: "audiobook"), let items = results.audiobooks?.items {
                    rawResults = items.map { audiobookResponse in
                        let authors = audiobookResponse.authors.map { Author(name: $0.name) }
                        let narrators = audiobookResponse.narrators.map { Narrator(name: $0.name) }
                        let audiobook = Audiobook(id: audiobookResponse.id, name: audiobookResponse.name, authors: authors, images: audiobookResponse.images, explicit: audiobookResponse.explicit, description: audiobookResponse.description, edition: audiobookResponse.edition, narrators: narrators, publisher: audiobookResponse.publisher, total_chapters: audiobookResponse.total_chapters ?? 0)
                        return Card(input: .audiobook, media: Media(input: .audiobook(audiobook)), id: audiobook.id)
                    }
                }
                
            default:
                rawResults = []
            }
            
            var uniqueIds = Set<String>()
            var uniqueResults: [Card] = []
            for card in rawResults {
                if !uniqueIds.contains(card.id) {
                    uniqueIds.insert(card.id)
                    uniqueResults.append(card)
                }
            }
            
            self.suggestionCards = Array(uniqueResults.prefix(6))
        }
    }

    @MainActor
    func performSearch() async -> [Card] {
        self.isLoading = true
        defer { self.isLoading = false }

        switch searchManager.searchBy {
            case 0: return await searchAlbums()
            case 1: return await searchArtists()
            case 2: return await searchSongs()
            case 3: return await searchPodcasts()
            default: return await searchAudiobooks()
        }
    }

    func searchAlbums() async -> [Card] {
        do {
            if let albumSearchResults = try await spotifyManager.search(query: searchText, type: "album"),
               let albums = albumSearchResults.albums {
                
                var albumCards: [Card] = []
                for albumResponse in albums.items {
                    var isExplicit = false
                    if let tracksResponse = try await spotifyManager.getAlbumTracks(albumId: albumResponse.id) {
                        if tracksResponse.items.contains(where: { $0.explicit }) {
                            isExplicit = true
                        }
                    }

                    let artists = albumResponse.artists?.map { Artist(id: $0.id, name: $0.name, artistId: $0.id) } ?? []
                    let album = Album(
                        id: albumResponse.id,
                        images: albumResponse.images,
                        name: albumResponse.name,
                        release_date: albumResponse.release_date,
                        artists: artists,
                        album_type: albumResponse.album_type,
                        isExplicit: isExplicit,
                        genres: albumResponse.genres,
                        label: albumResponse.label
                    )
                    albumCards.append(Card(input: .album, media: Media(input: .album(album)), id: album.id))
                }
                return albumCards
            }
        } catch {
            print("Error during album search: \(error)")
        }
        return []
    }

    func searchSongs() async -> [Card] {
        do {
            if let songSearchResults = try await spotifyManager.search(query: searchText, type: "track"),
               let songs = songSearchResults.tracks {
                
                return songs.items.map { song in
                    let albumArtists = song.album.artists?.map { Artist(id: $0.id, name: $0.name, artistId: $0.id) } ?? []
                    let songArtists = song.artists.map { Artist(id: $0.id, name: $0.name, artistId: $0.id) }
                    return Card(input: .song, media: Media(input: .song(Song(id: song.id, album: Album(id: song.album.id, images: song.album.images, name: song.album.name, release_date: song.album.release_date, artists: albumArtists, album_type: song.album.album_type), artists: songArtists, duration_ms: song.duration_ms, name: song.name, popularity: song.popularity, explicit: song.explicit))), id: song.id)
                    
                }
            }
        } catch {
            print("Error during song search: \(error)")
        }
        return []
    }
    
    func searchArtists() async -> [Card] {
        do {
            if let artistSearchResults = try await spotifyManager.search(query: searchText, type: "artist"),
               let artists = artistSearchResults.artists {
                    
                    return artists.items.map { artist in
                        return Card(input: .artist, media: Media(input: .artist(Artist(id: artist.id, images: artist.images, name: artist.name, popularity: artist.popularity, artistId: artist.id, genres: artist.genres))), id: artist.id)
                    
                }
            }
        } catch {
            print("Error during artist search: \(error)")
        }
        return []
    }

    func searchPodcasts() async -> [Card] {
        do {
            if let showSearchResults = try await spotifyManager.search(query: searchText, type: "show"),
               let shows = showSearchResults.shows {
                return shows.items.map { show in
                    let podcast = Podcast(id: show.id, name: show.name, publisher: show.publisher, images: show.images, explicit: show.explicit, description: show.description, total_episodes: show.total_episodes)
                    return Card(input: .podcast, media: Media(input: .podcast(podcast)), id: podcast.id)
                }
            }
        } catch {
            print("Error during podcast search: \(error)")
        }
        return []
    }

    func searchAudiobooks() async -> [Card] {
        do {
            if let audiobookSearchResults = try await spotifyManager.search(query: searchText, type: "audiobook"),
               let audiobooks = audiobookSearchResults.audiobooks {
                return audiobooks.items.map { audiobookResponse in
                    let authors = audiobookResponse.authors.map { Author(name: $0.name) }
                    let narrators = audiobookResponse.narrators.map { Narrator(name: $0.name) }
                    let audiobook = Audiobook(id: audiobookResponse.id, name: audiobookResponse.name, authors: authors, images: audiobookResponse.images, explicit: audiobookResponse.explicit, description: audiobookResponse.description, edition: audiobookResponse.edition, narrators: narrators, publisher: audiobookResponse.publisher, total_chapters: audiobookResponse.total_chapters ?? 0) // Provide default value
                    return Card(input: .audiobook, media: Media(input: .audiobook(audiobook)), id: audiobook.id)
                }
            }
        } catch {
            print("Error during audiobook search: \(error)")
        }
        return []
    }

    @MainActor
    func startSearch() async {
        guard !searchText.isEmpty else { return }
        
        currentSearchTask?.cancel()
        
        let thisQuery = searchText
        self.isLoading = true
        self.cards = []
        
        currentSearchTask = Task {
            let results: [Card] = await performSearch()
            
            if searchText == thisQuery {
                self.cards = results
            }
            self.isLoading = false
        }
    }

    func onAdd(card: Card) {
        switch card.type {
        case .song:
            if case let .song(song) = card.input.input {
                DatabaseManager.shared.addSong(song: song) { error in
                    if let error = error {
                        print("Error adding song to database: \(error.localizedDescription)")
                    } else {
                        listenListIDs.insert(song.id)
                        Task { await listManager.fetchListenList(forceReload: true) }
                    }
                }
            }
        case .album:
            if case let .album(album) = card.input.input {
                DatabaseManager.shared.addAlbum(album: album, showOnList: true) { error in
                    if let error = error {
                        print("Error adding album to database: \(error.localizedDescription)")
                    } else {
                        listenListIDs.insert(album.id)
                        Task { await listManager.fetchListenList(forceReload: true) }
                    }
                }
            }
        case .artist:
            if case let .artist(artist) = card.input.input {
                DatabaseManager.shared.addArtist(artist: artist, showOnList: true) { error in
                    if let error = error {
                        print("Error adding artist to database: \(error.localizedDescription)")
                    } else {
                        listenListIDs.insert(artist.id)
                        Task { await listManager.fetchListenList(forceReload: true) }
                    }
                }
            }
        case .podcast:
            if case let .podcast(podcast) = card.input.input {
                DatabaseManager.shared.addPodcast(podcast: podcast) { error in
                    if let error = error {
                        print("Error adding podcast to database: \(error.localizedDescription)")
                    } else {
                        listenListIDs.insert(podcast.id)
                        Task { await listManager.fetchListenList(forceReload: true) }
                    }
                }
            }
        case .audiobook:
            if case let .audiobook(audiobook) = card.input.input {
                DatabaseManager.shared.addAudiobook(audiobook: audiobook) { error in
                    if let error = error {
                        print("Error adding audiobook to database: \(error.localizedDescription)")
                    } else {
                        listenListIDs.insert(audiobook.id)
                        Task { await listManager.fetchListenList(forceReload: true) }
                    }
                }
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack {
                Picker(selection: $searchManager.searchBy, label: Text("Search Filter")) {
                    Text("Album").tag(0)
                    Text("Artist").tag(1)
                    Text("Song").tag(2)
                    Text("Podcast").tag(3)
                    Text("Audiobook").tag(4)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if isLoading {
                    ProgressView("Searching...").padding()
                } else if isLoadingSuggestions && searchText.isEmpty {
                    ProgressView("Loading Suggestions...").padding()
                }
                
                if searchText.isEmpty && !suggestionCards.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Recommended for You")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top, 5)
                        
                        CardList(results: suggestionCards, onAdd: onAdd, listenListIDs: listenListIDs)
                    }
                } else {
                    CardList(results: cards, onAdd: onAdd, listenListIDs: listenListIDs)
                }
            }
        }
        .navigationTitle("Search")
        .onAppear {
            fetchListenListIDs()
            Task { await fetchSuggestions() }
        }
        .onChange(of: searchManager.searchBy) {
            if searchText.isEmpty {
                Task { await fetchSuggestions() }
            } else {
                Task { await startSearch() }
            }
        }
        .onChange(of: searchText) {
            if searchText.isEmpty {
                cards = []
            } else {
                currentSearchTask?.cancel()
                currentSearchTask = Task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    if !Task.isCancelled {
                        await startSearch()
                    }
                }
            }
        }
    }
}
