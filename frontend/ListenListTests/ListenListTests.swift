//
//  ListenListTests.swift
//  ListenListTests
//
//  Created by Brandon Lamer-Connolly on 10/11/24.
//

import Testing
import Foundation
@testable import ListenList

// MARK: - Helpers

private func makeArtist(id: String = "artist1", name: String = "Test Artist") -> Artist {
    Artist(id: id, images: nil, name: name, popularity: 80, artistId: id, showOnList: nil, genres: nil)
}

private func makeAlbum(id: String = "album1", name: String = "Test Album") -> Album {
    Album(id: id, images: [], name: name, releaseDate: "2024-01-01", artists: [], albumType: "album", isExplicit: false)
}

private func makeSong(id: String = "song1") -> Song {
    Song(id: id, album: makeAlbum(), artists: [makeArtist()], durationMs: 200_000, name: "Test Song", popularity: 75, explicit: false)
}

private func makePodcast(id: String = "podcast1") -> Podcast {
    Podcast(id: id, name: "Test Podcast", publisher: "Test Publisher", images: [], explicit: false, description: "A podcast", totalEpisodes: 100)
}

private func makeAudiobook(id: String = "book1") -> Audiobook {
    Audiobook(id: id, name: "Test Book", authors: [], images: [], explicit: false, description: "A book", edition: "1st", narrators: [], publisher: "Publisher")
}

// MARK: - Song Tests

@Suite("Song Model")
struct SongModelTests {

    @Test func songHasCorrectId() {
        let song = makeSong(id: "track-42")
        #expect(song.id == "track-42")
    }

    @Test func songDefaultIsCompletedIsFalse() {
        let song = makeSong()
        #expect(song.isCompleted == false)
    }

    @Test func songRatingDefaultsToNil() {
        let song = makeSong()
        #expect(song.rating == nil)
    }

    @Test func songCommentDefaultsToNil() {
        let song = makeSong()
        #expect(song.comment == nil)
    }

    @Test func songWithRatingAndComment() {
        var song = makeSong()
        song.rating = 4
        song.comment = "Great track"
        #expect(song.rating == 4)
        #expect(song.comment == "Great track")
    }

    @Test func songMarkedCompleted() {
        var song = makeSong()
        song.isCompleted = true
        #expect(song.isCompleted == true)
    }

    @Test func songIsHashable() {
        let song1 = makeSong(id: "s1")
        let song2 = makeSong(id: "s1")
        let set: Set<Song> = [song1, song2]
        #expect(set.count == 1)
    }

    @Test func distinctSongsHaveDifferentHashes() {
        let song1 = makeSong(id: "s1")
        let song2 = makeSong(id: "s2")
        let set: Set<Song> = [song1, song2]
        #expect(set.count == 2)
    }

    @Test func songExplicitFlag() {
        let explicit = Song(id: "s1", album: makeAlbum(), artists: [], durationMs: 0, name: "E", popularity: 0, explicit: true)
        let clean = Song(id: "s2", album: makeAlbum(), artists: [], durationMs: 0, name: "C", popularity: 0, explicit: false)
        #expect(explicit.explicit == true)
        #expect(clean.explicit == false)
    }
}

// MARK: - Album Tests

@Suite("Album Model")
struct AlbumModelTests {

    @Test func albumHasCorrectId() {
        let album = makeAlbum(id: "alb-99")
        #expect(album.id == "alb-99")
    }

    @Test func albumDefaultIsCompletedIsFalse() {
        let album = makeAlbum()
        #expect(album.isCompleted == false)
    }

    @Test func albumRatingDefaultsToNil() {
        let album = makeAlbum()
        #expect(album.rating == nil)
    }

    @Test func albumCommentDefaultsToNil() {
        let album = makeAlbum()
        #expect(album.comment == nil)
    }

    @Test func albumGenresDefaultsToNil() {
        let album = makeAlbum()
        #expect(album.genres == nil)
    }

    @Test func albumLabelDefaultsToNil() {
        let album = makeAlbum()
        #expect(album.label == nil)
    }

    @Test func albumWithGenresAndLabel() {
        let album = Album(id: "a1", images: [], name: "Rock Album", releaseDate: "2024-01-01",
                          artists: [], albumType: "album", isExplicit: false,
                          genres: ["rock", "pop"], label: "Big Label")
        #expect(album.genres == ["rock", "pop"])
        #expect(album.label == "Big Label")
    }

    @Test func albumInitFromNilDTOReturnsNil() {
        let album = Album(from: nil as AlbumDTO?)
        #expect(album == nil)
    }

    @Test func albumIsHashable() {
        let a1 = makeAlbum(id: "a1")
        let a2 = makeAlbum(id: "a1")
        let set: Set<Album> = [a1, a2]
        #expect(set.count == 1)
    }
}

// MARK: - Artist Tests

@Suite("Artist Model")
struct ArtistModelTests {

    @Test func artistHasCorrectId() {
        let artist = makeArtist(id: "art-7")
        #expect(artist.id == "art-7")
    }

    @Test func artistShowOnListDefaultsToNil() {
        let artist = makeArtist()
        #expect(artist.showOnList == nil)
    }

    @Test func artistGenresDefaultsToNil() {
        let artist = makeArtist()
        #expect(artist.genres == nil)
    }

    @Test func artistImagesDefaultsToNil() {
        let artist = makeArtist()
        #expect(artist.images == nil)
    }

    @Test func artistInitFromDTO() {
        let dto = ArtistDTO(id: "dto-artist", name: "DTO Artist", images: nil, popularity: 90, showOnList: true)
        let artist = Artist(from: dto)
        #expect(artist.id == "dto-artist")
        #expect(artist.name == "DTO Artist")
        #expect(artist.popularity == 90)
        #expect(artist.artistId == "dto-artist")
    }

    @Test func artistInitFromDTOWithNilPopularity() {
        let dto = ArtistDTO(id: "a1", name: "Artist", images: nil, popularity: nil, showOnList: nil)
        let artist = Artist(from: dto)
        #expect(artist.popularity == nil)
    }

    @Test func artistIsHashable() {
        let a1 = makeArtist(id: "art1")
        let a2 = makeArtist(id: "art1")
        let set: Set<Artist> = [a1, a2]
        #expect(set.count == 1)
    }
}

// MARK: - Podcast Tests

@Suite("Podcast Model")
struct PodcastModelTests {

    @Test func podcastHasCorrectId() {
        let podcast = makePodcast(id: "pod-5")
        #expect(podcast.id == "pod-5")
    }

    @Test func podcastDefaultIsCompletedIsFalse() {
        let podcast = makePodcast()
        #expect(podcast.isCompleted == false)
    }

    @Test func podcastRatingDefaultsToNil() {
        let podcast = makePodcast()
        #expect(podcast.rating == nil)
    }

    @Test func podcastCommentDefaultsToNil() {
        let podcast = makePodcast()
        #expect(podcast.comment == nil)
    }

    @Test func podcastWithAllFields() {
        let podcast = Podcast(id: "p1", name: "My Show", publisher: "Publisher",
                              images: [], explicit: true, description: "Desc",
                              totalEpisodes: 200, rating: 5, comment: "Love it", isCompleted: true)
        #expect(podcast.publisher == "Publisher")
        #expect(podcast.explicit == true)
        #expect(podcast.totalEpisodes == 200)
        #expect(podcast.rating == 5)
        #expect(podcast.comment == "Love it")
        #expect(podcast.isCompleted == true)
    }

    @Test func podcastIsHashable() {
        let p1 = makePodcast(id: "p1")
        let p2 = makePodcast(id: "p1")
        let set: Set<Podcast> = [p1, p2]
        #expect(set.count == 1)
    }
}

// MARK: - Audiobook Tests

@Suite("Audiobook Model")
struct AudiobookModelTests {

    @Test func audiobookHasCorrectId() {
        let book = makeAudiobook(id: "book-3")
        #expect(book.id == "book-3")
    }

    @Test func audiobookDefaultIsCompletedIsFalse() {
        let book = makeAudiobook()
        #expect(book.isCompleted == false)
    }

    @Test func audiobookTotalChaptersDefaultsToNil() {
        let book = makeAudiobook()
        #expect(book.totalChapters == nil)
    }

    @Test func audiobookRatingDefaultsToNil() {
        let book = makeAudiobook()
        #expect(book.rating == nil)
    }

    @Test func audiobookWithAuthorsAndNarrators() {
        let book = Audiobook(id: "b1", name: "Book", authors: [Author(name: "J. Smith")],
                             images: [], explicit: false, description: "Desc", edition: "2nd",
                             narrators: [Narrator(name: "Voice Actor")], publisher: "Pub",
                             totalChapters: 30, rating: 4, comment: "Good", isCompleted: false)
        #expect(book.authors.count == 1)
        #expect(book.authors.first?.name == "J. Smith")
        #expect(book.narrators.count == 1)
        #expect(book.narrators.first?.name == "Voice Actor")
        #expect(book.totalChapters == 30)
    }

    @Test func audiobookIsHashable() {
        let b1 = makeAudiobook(id: "b1")
        let b2 = makeAudiobook(id: "b1")
        let set: Set<Audiobook> = [b1, b2]
        #expect(set.count == 1)
    }
}

// MARK: - Card Tests

@Suite("Card")
struct CardTests {

    @Test func cardSongIdMatchesSongId() {
        let song = makeSong(id: "song-id")
        let card = Card(input: .song, media: Media(input: .song(song)), id: song.id)
        #expect(card.id == "song-id")
    }

    @Test func cardAlbumIdMatchesAlbumId() {
        let album = makeAlbum(id: "album-id")
        let card = Card(input: .album, media: Media(input: .album(album)), id: album.id)
        #expect(card.id == "album-id")
    }

    @Test func cardArtistIdMatchesArtistId() {
        let artist = makeArtist(id: "artist-id")
        let card = Card(input: .artist, media: Media(input: .artist(artist)), id: artist.id)
        #expect(card.id == "artist-id")
    }

    @Test func cardPodcastIdMatchesPodcastId() {
        let podcast = makePodcast(id: "podcast-id")
        let card = Card(input: .podcast, media: Media(input: .podcast(podcast)), id: podcast.id)
        #expect(card.id == "podcast-id")
    }

    @Test func cardAudiobookIdMatchesAudiobookId() {
        let book = makeAudiobook(id: "book-id")
        let card = Card(input: .audiobook, media: Media(input: .audiobook(book)), id: book.id)
        #expect(card.id == "book-id")
    }

    @Test func cardTypeSong() {
        let song = makeSong()
        let card = Card(input: .song, media: Media(input: .song(song)), id: song.id)
        guard case .song = card.type else {
            Issue.record("Expected .song card type")
            return
        }
    }

    @Test func cardTypeAlbum() {
        let album = makeAlbum()
        let card = Card(input: .album, media: Media(input: .album(album)), id: album.id)
        guard case .album = card.type else {
            Issue.record("Expected .album card type")
            return
        }
    }

    @Test func cardTypeArtist() {
        let artist = makeArtist()
        let card = Card(input: .artist, media: Media(input: .artist(artist)), id: artist.id)
        guard case .artist = card.type else {
            Issue.record("Expected .artist card type")
            return
        }
    }

    @Test func cardTypePodcast() {
        let podcast = makePodcast()
        let card = Card(input: .podcast, media: Media(input: .podcast(podcast)), id: podcast.id)
        guard case .podcast = card.type else {
            Issue.record("Expected .podcast card type")
            return
        }
    }

    @Test func cardTypeAudiobook() {
        let book = makeAudiobook()
        let card = Card(input: .audiobook, media: Media(input: .audiobook(book)), id: book.id)
        guard case .audiobook = card.type else {
            Issue.record("Expected .audiobook card type")
            return
        }
    }

    @Test func cardIsIdentifiable() {
        let song = makeSong(id: "identifiable-id")
        let card = Card(input: .song, media: Media(input: .song(song)), id: song.id)
        // Accessing .id verifies Identifiable conformance
        let id: String = card.id
        #expect(id == "identifiable-id")
    }
}

// MARK: - Media Tests

@Suite("Media and MediaType")
struct MediaTests {

    @Test func mediaSongExtractsCorrectValues() {
        let song = makeSong(id: "s1")
        let media = Media(input: .song(song))
        guard case .song(let extracted) = media.input else {
            Issue.record("Expected .song media type")
            return
        }
        #expect(extracted.id == "s1")
        #expect(extracted.name == "Test Song")
    }

    @Test func mediaAlbumExtractsCorrectValues() {
        let album = makeAlbum(id: "a1", name: "My Album")
        let media = Media(input: .album(album))
        guard case .album(let extracted) = media.input else {
            Issue.record("Expected .album media type")
            return
        }
        #expect(extracted.id == "a1")
        #expect(extracted.name == "My Album")
    }

    @Test func mediaArtistExtractsCorrectValues() {
        let artist = makeArtist(id: "art1", name: "My Artist")
        let media = Media(input: .artist(artist))
        guard case .artist(let extracted) = media.input else {
            Issue.record("Expected .artist media type")
            return
        }
        #expect(extracted.id == "art1")
        #expect(extracted.name == "My Artist")
    }

    @Test func mediaPodcastExtractsCorrectValues() {
        let podcast = makePodcast(id: "p1")
        let media = Media(input: .podcast(podcast))
        guard case .podcast(let extracted) = media.input else {
            Issue.record("Expected .podcast media type")
            return
        }
        #expect(extracted.id == "p1")
    }

    @Test func mediaAudiobookExtractsCorrectValues() {
        let book = makeAudiobook(id: "b1")
        let media = Media(input: .audiobook(book))
        guard case .audiobook(let extracted) = media.input else {
            Issue.record("Expected .audiobook media type")
            return
        }
        #expect(extracted.id == "b1")
    }
}

// MARK: - ImageDTO Tests

@Suite("ImageDTO")
struct ImageDTOTests {

    @Test func toImageResponseWithValidDict() {
        let dict: [String: Any] = ["url": "https://example.com/img.jpg", "height": 640, "width": 640]
        let result = ImageDTO.toImageResponse(from: dict)
        #expect(result != nil)
        #expect(result?.url == "https://example.com/img.jpg")
        #expect(result?.height == 640)
        #expect(result?.width == 640)
    }

    @Test func toImageResponseMissingUrlReturnsNil() {
        let dict: [String: Any] = ["height": 640, "width": 640]
        let result = ImageDTO.toImageResponse(from: dict)
        #expect(result == nil)
    }

    @Test func toImageResponseMissingDimensionsIsNil() {
        let dict: [String: Any] = ["url": "https://example.com/img.jpg"]
        let result = ImageDTO.toImageResponse(from: dict)
        #expect(result != nil)
        #expect(result?.height == nil)
        #expect(result?.width == nil)
    }

    @Test func toImageResponseEmptyDictReturnsNil() {
        let result = ImageDTO.toImageResponse(from: [:])
        #expect(result == nil)
    }

    @Test func imageResponseFromDTOInit() {
        let dto = ImageDTO(height: 300, width: 300, url: "https://example.com/small.jpg")
        let response = ImageResponse(from: dto)
        #expect(response.url == "https://example.com/small.jpg")
        #expect(response.height == 300)
        #expect(response.width == 300)
    }
}

// MARK: - JSON Decoding Tests

@Suite("JSON Decoding")
struct JSONDecodingTests {

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    @Test func imageResponseDecodes() throws {
        let json = #"{"url":"https://i.scdn.co/img.jpg","height":640,"width":640}"#
        let result = try decoder.decode(ImageResponse.self, from: Data(json.utf8))
        #expect(result.url == "https://i.scdn.co/img.jpg")
        #expect(result.height == 640)
        #expect(result.width == 640)
    }

    @Test func imageResponseOptionalDimensions() throws {
        let json = #"{"url":"https://i.scdn.co/img.jpg"}"#
        let result = try decoder.decode(ImageResponse.self, from: Data(json.utf8))
        #expect(result.height == nil)
        #expect(result.width == nil)
    }

    @Test func artistResponseDecodes() throws {
        let json = """
        {
            "id": "artist1",
            "name": "Test Artist",
            "popularity": 80,
            "images": [{"url":"https://i.scdn.co/img.jpg","height":640,"width":640}],
            "genres": ["rock","indie"]
        }
        """
        let result = try decoder.decode(ArtistResponse.self, from: Data(json.utf8))
        #expect(result.id == "artist1")
        #expect(result.name == "Test Artist")
        #expect(result.popularity == 80)
        #expect(result.images?.count == 1)
        #expect(result.genres == ["rock", "indie"])
    }

    @Test func artistResponseWithNilOptionals() throws {
        let json = #"{"id":"a1","name":"Artist"}"#
        let result = try decoder.decode(ArtistResponse.self, from: Data(json.utf8))
        #expect(result.images == nil)
        #expect(result.popularity == nil)
        #expect(result.genres == nil)
    }

    @Test func albumResponseDecodes() throws {
        let json = """
        {
            "id": "album1",
            "name": "Test Album",
            "release_date": "2024-01-01",
            "album_type": "album",
            "images": [],
            "artists": []
        }
        """
        let result = try decoder.decode(AlbumResponse.self, from: Data(json.utf8))
        #expect(result.id == "album1")
        #expect(result.name == "Test Album")
        #expect(result.releaseDate == "2024-01-01")
        #expect(result.albumType == "album")
        #expect(result.images.isEmpty)
    }

    @Test func songResponseDecodes() throws {
        let json = """
        {
            "id": "track1",
            "name": "Test Song",
            "duration_ms": 210000,
            "popularity": 75,
            "explicit": false,
            "artists": [{"id":"a1","name":"Artist"}],
            "album": {
                "id": "album1",
                "name": "Test Album",
                "release_date": "2024-01-01",
                "album_type": "album",
                "images": []
            }
        }
        """
        let result = try decoder.decode(SongResponse.self, from: Data(json.utf8))
        #expect(result.id == "track1")
        #expect(result.name == "Test Song")
        #expect(result.durationMs == 210000)
        #expect(result.popularity == 75)
        #expect(result.explicit == false)
        #expect(result.artists.count == 1)
    }

    @Test func showResponseDecodes() throws {
        let json = """
        {
            "id": "show1",
            "name": "My Podcast",
            "publisher": "Podcast Co.",
            "explicit": false,
            "description": "A weekly show",
            "total_episodes": 42,
            "images": []
        }
        """
        let result = try decoder.decode(ShowResponse.self, from: Data(json.utf8))
        #expect(result.id == "show1")
        #expect(result.name == "My Podcast")
        #expect(result.publisher == "Podcast Co.")
        #expect(result.totalEpisodes == 42)
        #expect(result.explicit == false)
    }

    @Test func audiobookResponseDecodes() throws {
        let json = """
        {
            "id": "book1",
            "name": "A Great Book",
            "explicit": false,
            "description": "An epic adventure",
            "edition": "1st Edition",
            "publisher": "Big Publisher",
            "total_chapters": 20,
            "images": [],
            "authors": [{"name": "John Author"}],
            "narrators": [{"name": "Jane Narrator"}]
        }
        """
        let result = try decoder.decode(AudiobookResponse.self, from: Data(json.utf8))
        #expect(result.id == "book1")
        #expect(result.name == "A Great Book")
        #expect(result.totalChapters == 20)
        #expect(result.authors.count == 1)
        #expect(result.authors.first?.name == "John Author")
        #expect(result.narrators.count == 1)
        #expect(result.narrators.first?.name == "Jane Narrator")
    }

    @Test func audiobookResponseNilTotalChapters() throws {
        let json = """
        {
            "id": "book1",
            "name": "Incomplete Book",
            "explicit": false,
            "description": "Desc",
            "edition": "1st",
            "publisher": "Pub",
            "images": [],
            "authors": [],
            "narrators": []
        }
        """
        let result = try decoder.decode(AudiobookResponse.self, from: Data(json.utf8))
        #expect(result.totalChapters == nil)
    }

    @Test func accessTokenResponseDecodes() throws {
        let json = """
        {
            "access_token": "tok123",
            "token_type": "Bearer",
            "scope": "user-read-private streaming",
            "expires_in": 3600,
            "refresh_token": "refresh456"
        }
        """
        let result = try decoder.decode(AccessTokenResponse.self, from: Data(json.utf8))
        #expect(result.accessToken == "tok123")
        #expect(result.tokenType == "Bearer")
        #expect(result.scope == "user-read-private streaming")
        #expect(result.expiresIn == 3600)
        #expect(result.refreshToken == "refresh456")
    }

    @Test func accessTokenResponseNilRefreshToken() throws {
        let json = """
        {
            "access_token": "tok123",
            "token_type": "Bearer",
            "scope": "user-read-private",
            "expires_in": 3600
        }
        """
        let result = try decoder.decode(AccessTokenResponse.self, from: Data(json.utf8))
        #expect(result.refreshToken == nil)
    }

    @Test func userProfileResponseDecodes() throws {
        let json = """
        {
            "id": "user123",
            "display_name": "Jane Doe",
            "email": "jane@example.com",
            "images": []
        }
        """
        let result = try decoder.decode(UserProfileResponse.self, from: Data(json.utf8))
        #expect(result.id == "user123")
        #expect(result.displayName == "Jane Doe")
        #expect(result.email == "jane@example.com")
    }

    @Test func userProfileResponseOptionalFields() throws {
        let json = #"{"id":"user1"}"#
        let result = try decoder.decode(UserProfileResponse.self, from: Data(json.utf8))
        #expect(result.displayName == nil)
        #expect(result.email == nil)
        #expect(result.images == nil)
    }

    @Test func trackItemDecodes() throws {
        let json = #"{"explicit":true,"name":"Explicit Track"}"#
        let result = try decoder.decode(TrackItem.self, from: Data(json.utf8))
        #expect(result.explicit == true)
        #expect(result.name == "Explicit Track")
    }

    @Test func trackItemNilName() throws {
        let json = #"{"explicit":false}"#
        let result = try decoder.decode(TrackItem.self, from: Data(json.utf8))
        #expect(result.name == nil)
    }

    @Test func searchResponseDecodesWithAlbums() throws {
        let json = """
        {
            "albums": {
                "href": "https://api.spotify.com/v1/search",
                "limit": 20,
                "offset": 0,
                "total": 1,
                "items": []
            }
        }
        """
        let result = try decoder.decode(SearchResponse.self, from: Data(json.utf8))
        #expect(result.albums != nil)
        #expect(result.tracks == nil)
        #expect(result.artists == nil)
        #expect(result.shows == nil)
        #expect(result.audiobooks == nil)
    }
}

// MARK: - SearchManager Tests

@Suite("SearchManager")
struct SearchManagerTests {

    @Test @MainActor func initialSearchTextIsEmpty() {
        #expect(SearchManager.shared.searchText == "")
    }

    @Test @MainActor func initialSearchByIsAlbum() {
        #expect(SearchManager.shared.searchBy == .album)
    }
}

// MARK: - MockDatabaseService

/// In-memory DatabaseService for use in tests. Completions are called synchronously.
final class MockDatabaseService: DatabaseService {
    var songsToReturn: [Song] = []
    var albumsToReturn: [Album] = []
    var artistsToReturn: [Artist] = []
    var podcastsToReturn: [Podcast] = []
    var audiobooksToReturn: [Audiobook] = []

    var shouldFailDelete = false

    private(set) var deletedSongIds: [String] = []
    private(set) var removedAlbumIds: [String] = []
    private(set) var removedArtistIds: [String] = []
    private(set) var deletedPodcastIds: [String] = []
    private(set) var deletedAudiobookIds: [String] = []

    func fetchSongs(completion: @escaping ([Song]) -> Void)         { completion(songsToReturn) }
    func fetchAlbums(completion: @escaping ([Album]) -> Void)       { completion(albumsToReturn) }
    func fetchArtists(completion: @escaping ([Artist]) -> Void)     { completion(artistsToReturn) }
    func fetchPodcasts(completion: @escaping ([Podcast]) -> Void)   { completion(podcastsToReturn) }
    func fetchAudiobooks(completion: @escaping ([Audiobook]) -> Void) { completion(audiobooksToReturn) }

    func deleteSong(withId id: String, completion: @escaping (Error?) -> Void) {
        deletedSongIds.append(id)
        completion(shouldFailDelete ? NSError(domain: "test", code: 1) : nil)
    }

    func removeAlbumFromList(withId id: String, completion: @escaping (Error?) -> Void) {
        removedAlbumIds.append(id)
        completion(shouldFailDelete ? NSError(domain: "test", code: 1) : nil)
    }

    func removeArtistFromList(withId id: String, completion: @escaping (Error?) -> Void) {
        removedArtistIds.append(id)
        completion(shouldFailDelete ? NSError(domain: "test", code: 1) : nil)
    }

    func deletePodcast(withId id: String, completion: @escaping (Error?) -> Void) {
        deletedPodcastIds.append(id)
        completion(shouldFailDelete ? NSError(domain: "test", code: 1) : nil)
    }

    func deleteAudiobook(withId id: String, completion: @escaping (Error?) -> Void) {
        deletedAudiobookIds.append(id)
        completion(shouldFailDelete ? NSError(domain: "test", code: 1) : nil)
    }

    func addSong(song: Song, completion: @escaping (Error?) -> Void) { completion(nil) }
    func addAlbum(album: Album, showOnList: Bool, completion: @escaping (Error?) -> Void) { completion(nil) }
    func addArtist(artist: Artist, showOnList: Bool, completion: @escaping (Error?) -> Void) { completion(nil) }
    func addPodcast(podcast: Podcast, completion: @escaping (Error?) -> Void) { completion(nil) }
    func addAudiobook(audiobook: Audiobook, completion: @escaping (Error?) -> Void) { completion(nil) }
}

// MARK: - ListManager Tests

@Suite("ListManager")
struct ListManagerTests {

    // Builds a fresh ListManager backed by a mock pre-loaded with the given data.
    @MainActor
    private func makeManager(
        songs: [Song] = [],
        albums: [Album] = [],
        artists: [Artist] = [],
        podcasts: [Podcast] = [],
        audiobooks: [Audiobook] = []
    ) -> (ListManager, MockDatabaseService) {
        let mock = MockDatabaseService()
        mock.songsToReturn = songs
        mock.albumsToReturn = albums
        mock.artistsToReturn = artists
        mock.podcastsToReturn = podcasts
        mock.audiobooksToReturn = audiobooks
        return (ListManager(db: mock), mock)
    }

    // MARK: Fetch

    @Test @MainActor func fetchPopulatesCards() async {
        let (manager, _) = makeManager(songs: [makeSong(id: "s1")], albums: [makeAlbum(id: "a1")])
        await manager.fetchListenList()
        #expect(manager.cards.count == 2)
        #expect(manager.cards.contains { $0.id == "s1" })
        #expect(manager.cards.contains { $0.id == "a1" })
    }

    @Test @MainActor func fetchSetsIsLoadingFalseWhenDone() async {
        let (manager, _) = makeManager(songs: [makeSong()])
        await manager.fetchListenList()
        #expect(manager.isLoading == false)
    }

    @Test @MainActor func emptyDataSourceProducesEmptyCards() async {
        let (manager, _) = makeManager()
        await manager.fetchListenList()
        #expect(manager.cards.isEmpty)
        #expect(manager.completedCards.isEmpty)
    }

    @Test @MainActor func allMediaTypesAppearInCards() async {
        let (manager, _) = makeManager(
            songs: [makeSong(id: "s1")],
            albums: [makeAlbum(id: "a1")],
            artists: [makeArtist(id: "art1")],
            podcasts: [makePodcast(id: "p1")],
            audiobooks: [makeAudiobook(id: "b1")]
        )
        await manager.fetchListenList()
        #expect(manager.cards.count == 5)
    }

    // MARK: Completed / active separation

    @Test @MainActor func completedSongGoesToCompletedCards() async {
        var done = makeSong(id: "done"); done.isCompleted = true
        let active = makeSong(id: "active")
        let (manager, _) = makeManager(songs: [done, active])
        await manager.fetchListenList()
        #expect(manager.cards.map(\.id) == ["active"])
        #expect(manager.completedCards.map(\.id) == ["done"])
    }

    @Test @MainActor func completedAlbumGoesToCompletedCards() async {
        var done = makeAlbum(id: "done-album"); done.isCompleted = true
        let (manager, _) = makeManager(albums: [done])
        await manager.fetchListenList()
        #expect(manager.cards.isEmpty)
        #expect(manager.completedCards.count == 1)
        #expect(manager.completedCards.first?.id == "done-album")
    }

    @Test @MainActor func completedPodcastGoesToCompletedCards() async {
        var done = makePodcast(id: "done-pod")
        done = Podcast(id: "done-pod", name: done.name, publisher: done.publisher,
                       images: done.images, explicit: done.explicit,
                       description: done.description, totalEpisodes: done.totalEpisodes,
                       rating: nil, comment: nil, isCompleted: true)
        let (manager, _) = makeManager(podcasts: [done])
        await manager.fetchListenList()
        #expect(manager.cards.isEmpty)
        #expect(manager.completedCards.count == 1)
    }

    @Test @MainActor func artistsAreNeverInCompletedCards() async {
        // Artists don't have isCompleted — they always go to active cards
        let (manager, _) = makeManager(artists: [makeArtist(id: "art1")])
        await manager.fetchListenList()
        #expect(manager.cards.count == 1)
        #expect(manager.completedCards.isEmpty)
    }

    // MARK: Cache / forceReload

    @Test @MainActor func secondFetchWithoutForceReloadUsesCache() async {
        let (manager, mock) = makeManager(songs: [makeSong(id: "s1")])
        await manager.fetchListenList()
        mock.songsToReturn = [makeSong(id: "s1"), makeSong(id: "s2")]

        await manager.fetchListenList(forceReload: false)
        #expect(manager.cards.count == 1)
    }

    @Test @MainActor func forceReloadBypassesCache() async {
        let (manager, mock) = makeManager(songs: [makeSong(id: "s1")])
        await manager.fetchListenList()
        mock.songsToReturn = [makeSong(id: "s1"), makeSong(id: "s2")]

        await manager.fetchListenList(forceReload: true)
        #expect(manager.cards.count == 2)
    }

    // MARK: Delete

    @Test @MainActor func deleteSongRemovesCardOptimisticallyAndCallsDB() async {
        let (manager, mock) = makeManager(songs: [makeSong(id: "to-delete")])
        await manager.fetchListenList()

        manager.delete(card: manager.cards.first!)

        #expect(manager.cards.isEmpty)
        #expect(mock.deletedSongIds == ["to-delete"])
    }

    @Test @MainActor func deleteAlbumRemovesCardAndCallsRemoveAlbum() async {
        let (manager, mock) = makeManager(albums: [makeAlbum(id: "alb-hide")])
        await manager.fetchListenList()

        manager.delete(card: manager.cards.first!)

        #expect(manager.cards.isEmpty)
        #expect(mock.removedAlbumIds == ["alb-hide"])
        #expect(mock.deletedSongIds.isEmpty)
    }

    @Test @MainActor func deleteArtistRemovesCardAndCallsRemoveArtist() async {
        let (manager, mock) = makeManager(artists: [makeArtist(id: "art-hide")])
        await manager.fetchListenList()

        manager.delete(card: manager.cards.first!)

        #expect(manager.cards.isEmpty)
        #expect(mock.removedArtistIds == ["art-hide"])
    }

    @Test @MainActor func deletePodcastRemovesCardAndCallsDeletePodcast() async {
        let (manager, mock) = makeManager(podcasts: [makePodcast(id: "pod-del")])
        await manager.fetchListenList()

        manager.delete(card: manager.cards.first!)

        #expect(manager.cards.isEmpty)
        #expect(mock.deletedPodcastIds == ["pod-del"])
    }

    @Test @MainActor func deleteAudiobookRemovesCardAndCallsDeleteAudiobook() async {
        let (manager, mock) = makeManager(audiobooks: [makeAudiobook(id: "book-del")])
        await manager.fetchListenList()

        manager.delete(card: manager.cards.first!)

        #expect(manager.cards.isEmpty)
        #expect(mock.deletedAudiobookIds == ["book-del"])
    }

    @Test @MainActor func deleteOnlyAffectsTargetCard() async {
        let (manager, _) = makeManager(songs: [makeSong(id: "keep"), makeSong(id: "remove")])
        await manager.fetchListenList()

        let target = manager.cards.first { $0.id == "remove" }!
        manager.delete(card: target)

        #expect(manager.cards.count == 1)
        #expect(manager.cards.first?.id == "keep")
    }

    @Test @MainActor func deleteFromCompletedCardsWorks() async {
        var done = makeSong(id: "done"); done.isCompleted = true
        let (manager, mock) = makeManager(songs: [done])
        await manager.fetchListenList()

        #expect(manager.completedCards.count == 1)
        manager.delete(card: manager.completedCards.first!)

        #expect(manager.completedCards.isEmpty)
        #expect(mock.deletedSongIds == ["done"])
    }
}

// MARK: - SessionResponse Tests

@Suite("SessionResponse JSON Decoding")
struct SessionResponseTests {

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    @Test func sessionResponseDecodesFullPayload() throws {
        let json = """
        {
            "access_token": "header.payload.sig",
            "token_type": "bearer",
            "user_id": "abc12345678901234567",
            "email": "user@example.com",
            "spotify_linked": false
        }
        """
        let result = try decoder.decode(SessionResponse.self, from: Data(json.utf8))
        #expect(result.accessToken == "header.payload.sig")
        #expect(result.tokenType == "bearer")
        #expect(result.userId == "abc12345678901234567")
        #expect(result.email == "user@example.com")
        #expect(result.spotifyLinked == false)
    }

    @Test func sessionResponseNilEmailDecodes() throws {
        let json = """
        {
            "access_token": "tok",
            "token_type": "bearer",
            "user_id": "uid1",
            "spotify_linked": true
        }
        """
        let result = try decoder.decode(SessionResponse.self, from: Data(json.utf8))
        #expect(result.email == nil)
        #expect(result.spotifyLinked == true)
    }
}

// MARK: - AuthManager JWT Helper Tests

@Suite("AuthManager.isTokenExpired")
struct AuthManagerJWTTests {

    private func makeJWT(expOffset: TimeInterval) -> String {
        let exp = Int(Date().timeIntervalSince1970 + expOffset)
        let header = Data(#"{"alg":"RS256","typ":"JWT"}"#.utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .trimmingCharacters(in: .init(charactersIn: "="))
        let payload = Data("{\"sub\":\"test|123\",\"exp\":\(exp)}".utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .trimmingCharacters(in: .init(charactersIn: "="))
        return "\(header).\(payload).fakesig"
    }

    @Test func validFutureTokenIsNotExpired() {
        let token = makeJWT(expOffset: 3600)
        #expect(AuthManager.isTokenExpired(token) == false)
    }

    @Test func pastTokenIsExpired() {
        let token = makeJWT(expOffset: -1)
        #expect(AuthManager.isTokenExpired(token) == true)
    }

    @Test func twoPartStringIsExpired() {
        #expect(AuthManager.isTokenExpired("only.two") == true)
    }

    @Test func emptyStringIsExpired() {
        #expect(AuthManager.isTokenExpired("") == true)
    }

    @Test func invalidBase64PayloadIsExpired() {
        #expect(AuthManager.isTokenExpired("header.!!!invalid!!!.sig") == true)
    }
}
