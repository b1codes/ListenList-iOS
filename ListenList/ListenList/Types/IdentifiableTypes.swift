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
}

extension Album {
    init?(from dto: AlbumDTO?) {
        guard let dto = dto else { return nil }
        self.id = dto.id // Use the provided album document ID
        // Convert the array of image DocumentReferences using the helper in AlbumDTO.toAlbum.
        // Since we already fetched and converted images inside AlbumDTO.toAlbum, here we assume dto.images have been handled.
        // For simplicity, we assume that by now the images are available as ImageResponse objects.
        // If not, you may need to fetch these asynchronously.
        // Here, we use a simple mapping if possible.
        self.images = [] // As a placeholder. Alternatively, you can perform a similar mapping as done in AlbumDTO.toAlbum.
        self.name = dto.name
        self.release_date = dto.releaseDate
        self.artists = [] // We cannot synchronously convert [DocumentReference] to [Artist]; fetch these separately.
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
