//
//  IdentifiableTypes.swift
//  ListenList
//
//  Created by Brandon Lamer-Connolly on 10/11/24.
//

import Foundation

struct Song: Identifiable, Hashable {
    var id: String
    var album: Album
    var artists: [Artist]
    var duration_ms: Int
    var name: String
    var popularity: Int
    var explicit: Bool
}

struct Artist: Identifiable, Hashable {
    var id: String
    var images: [ImageResponse]?
    var name: String
    var popularity: Int?
    var artistId: String
    var showOnList: Bool? // Add this new property
}

struct Album: Identifiable, Hashable {
    var id: String
    var images: [ImageResponse]
    var name: String
    var release_date: String
    var artists: [Artist]
    var album_type: String
    var isExplicit: Bool? = false
}

extension Album {
    // This initializer takes an array of Artist objects.
    init?(from dto: AlbumDTO?, artists: [Artist]) {
        guard let dto = dto else { return nil }
        self.id = dto.id
        self.images = dto.images
        self.name = dto.name
        self.release_date = dto.releaseDate
        self.artists = artists
        self.album_type = dto.albumType
        self.isExplicit = dto.isExplicit
    }
    
    // Keep the old initializer for now, but we'll phase it out.
    init?(from dto: AlbumDTO?) {
        guard let dto = dto else { return nil }
        self.id = dto.id
        self.images = dto.images
        self.name = dto.name
        self.release_date = dto.releaseDate
        // Initialize artists as an empty array, to be populated later.
        self.artists = []
        self.album_type = dto.albumType
        self.isExplicit = dto.isExplicit
    }
    
    init(id: String, images: [ImageResponse], name: String, release_date: String, artists: [Artist], album_type: String, isExplicit: Bool) {
        self.id = id
        self.images = images
        self.name = name
        self.release_date = release_date
        self.artists = artists
        self.album_type = album_type
        self.isExplicit = isExplicit
    }

}

extension Artist {
    init(from dto: ArtistDTO) {
        self.id = dto.id
        // Here, if dto.images were to be processed further, include the logic.
        self.images = nil // For now, assign nil or later process the images
        self.name = dto.name
        self.popularity = dto.popularity
        self.artistId = dto.id
    }
}

struct Podcast: Identifiable, Hashable {
    var id: String
    var name: String
    var publisher: String
    var images: [ImageResponse]
    var explicit: Bool
    var description: String
    var total_episodes: Int
}

struct Audiobook: Identifiable, Hashable {
    var id: String
    var name: String
    var authors: [Author]
    var images: [ImageResponse]
    var explicit: Bool
    var description: String
    var edition: String
    var narrators: [Narrator]
    var publisher: String
    var total_chapters: Int
}

struct Narrator: Hashable {
    var name: String
}

struct Author: Hashable {
    var name: String
}
