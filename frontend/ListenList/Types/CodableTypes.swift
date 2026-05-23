//
//  CodableTypes.swift
//  ListenList
//
//  Created by Brandon Lamer-Connolly on 10/11/24.
//

struct SongSearchResponse: Codable, Hashable {
    var href: String
    var limit: Int
    var next: String?
    var offset: Int
    var previous: String?
    var total: Int
    var items: [SongResponse]
}

struct ArtistSearchResponse: Codable, Hashable {
    var href: String
    var limit: Int
    var next: String?
    var offset: Int
    var previous: String?
    var total: Int
    var items: [ArtistResponse]
}

struct AlbumSearchResponse: Codable, Hashable {
    var href: String
    var limit: Int
    var next: String?
    var offset: Int
    var previous: String?
    var total: Int
    var items: [AlbumResponse]
}

struct SongResponse: Codable, Hashable {
    var album: AlbumResponse
    var artists: [ArtistResponse]
    var durationMs: Int // in milliseconds
    var name: String
    var id: String
    var popularity: Int
    var explicit: Bool
}

struct ArtistResponse: Codable, Hashable {
    var images: [ImageResponse]?
    var name: String
    var popularity: Int?
    var id: String
    var genres: [String]?
}

struct AlbumResponse: Codable, Hashable {
    var images: [ImageResponse]
    var name: String
    var releaseDate: String
    var artists: [ArtistResponse]?
    var albumType: String
    var id: String
    var genres: [String]?
    var label: String?
}

struct ImageResponse: Codable, Hashable {
    var url: String
    var height: Int?
    var width: Int?
}

extension Array where Element == ImageResponse {
    /// Returns the URL for the smallest image (typically 64x64).
    func smallest() -> String? {
        // Spotify typically returns images in descending order of size.
        return self.last?.url
    }
    
    /// Returns the URL for a medium-sized image (typically 300x300).
    func medium() -> String? {
        if self.count >= 2 {
            // Index 1 is often the medium size (300x300).
            return self[1].url
        }
        return self.first?.url
    }
    
    /// Returns the URL for the largest image (typically 640x640).
    func largest() -> String? {
        return self.first?.url
    }
}

extension ImageResponse {
    init(from dto: ImageDTO) {
        self.height = dto.height
        self.width = dto.width
        self.url = dto.url
    }
}

struct AccessTokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let scope: String
    let expiresIn: Int
    let refreshToken: String?
}

struct AlbumTracksResponse: Codable, Hashable {
    var items: [TrackItem]
}

struct ArtistTopTracksResponse: Codable, Hashable {
    var tracks: [SongResponse]
}

struct TrackItem: Codable, Hashable {
    var id: String
    var name: String
    var durationMs: Int
    var explicit: Bool
    var artists: [ArtistResponse]
}

struct ShowSearchResponse: Codable, Hashable {
    var href: String
    var limit: Int
    var next: String?
    var offset: Int
    var previous: String?
    var total: Int
    var items: [ShowResponse]
}

struct AudiobookSearchResponse: Codable, Hashable {
    var href: String
    var limit: Int
    var next: String?
    var offset: Int
    var previous: String?
    var total: Int
    var items: [AudiobookResponse]
}

struct ShowResponse: Codable, Hashable {
    var id: String
    var name: String
    var publisher: String
    var images: [ImageResponse]
    var explicit: Bool
    var description: String
    var totalEpisodes: Int
}

struct AudiobookResponse: Codable, Hashable {
    var id: String
    var name: String
    var authors: [AuthorResponse]
    var images: [ImageResponse]
    var explicit: Bool
    var description: String
    var edition: String
    var narrators: [NarratorResponse]
    var publisher: String
    var totalChapters: Int?
}

struct NarratorResponse: Codable, Hashable {
    var name: String
}

struct AuthorResponse: Codable, Hashable {
    var name: String
}

struct SearchResponse: Codable, Hashable {
    var albums: AlbumSearchResponse?
    var tracks: SongSearchResponse?
    var artists: ArtistSearchResponse?
    var shows: ShowSearchResponse?
    var audiobooks: AudiobookSearchResponse?
}

struct UserProfileResponse: Codable, Hashable {
    var displayName: String?
    var email: String?
    var id: String
    var images: [ImageResponse]?
}
