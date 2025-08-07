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

struct SearchResponse: Codable, Hashable {
    var albums: AlbumSearchResponse?
    var tracks: SongSearchResponse?
    var artists: ArtistSearchResponse?
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
    var duration_ms: Int //in milliseconds
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
}

struct AlbumResponse: Codable, Hashable {
    var images: [ImageResponse]
    var name: String
    var release_date: String
    var artists: [ArtistResponse]?
    var album_type: String
    var id: String
}

struct ImageResponse: Codable, Hashable {
    var url: String
    var height: Int?
    var width: Int?
}

extension ImageResponse {
    init(from dto: ImageDTO) {
        self.height = dto.height
        self.width = dto.width
        self.url = dto.url
    }
}

struct AccessTokenResponse: Codable {
    let access_token: String
    let token_type: String
    let scope: String
    let expires_in: Int
    let refresh_token: String?
}

struct AlbumTracksResponse: Codable, Hashable {
    var items: [TrackItem]
}

struct TrackItem: Codable, Hashable {
    var explicit: Bool
}
