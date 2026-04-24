//
//  DTOs.swift
//  ListenList
//
//  Created by Brandon Lamer-Connolly on 1/3/25.
//

import Foundation
import FirebaseFirestore

// MARK: - ArtistDTO

struct ArtistDTO: Codable {
    let id: String
    let name: String
    var images: [DocumentReference]?
    var popularity: Int?
    var showOnList: Bool? // Add this new field

    static func toArtist(from ref: DocumentReference) async throws -> Artist? {
        let document = try await ref.getDocument()
        guard document.exists, let data = document.data() else {
            print("Artist document does not exist")
            return nil
        }
        let id = ref.documentID
        let name = data["name"] as? String ?? ""
        let popularity = data["popularity"] as? Int ?? 0
        let showOnList = data["showOnList"] as? Bool ?? false

        // Attempt to read images as an array of dictionaries.
        let imagesData = data["images"] as? [[String: Any]] ?? []
        let images = imagesData.compactMap { imageDict -> ImageResponse? in
            return ImageDTO.toImageResponse(from: imageDict)
        }

        let artist = Artist(
            id: id,
            images: images,
            name: name,
            popularity: popularity,
            artistId: id,
            showOnList: showOnList
        )
        return artist
    }
}

// MARK: - AlbumDTO

struct AlbumDTO: Codable {
    let id: String
    let name: String
    let releaseDate: String
    let albumType: String
    let images: [ImageResponse]
    let artists: [DocumentReference]  // If needed, you can later fetch these.
    var showOnList: Bool? // Add this new field
    let isExplicit: Bool?
    var rating: Int?
    var comment: String?
    var isCompleted: Bool?

    static func toAlbum(from ref: DocumentReference) async throws -> AlbumDTO? {
        let document = try await ref.getDocument()
        guard document.exists, let data = document.data() else {
            print("Album document does not exist")
            return nil
        }

        let id = ref.documentID
        let name = data["name"] as? String ?? ""
        let releaseDate = data["release_date"] as? String ?? ""
        let albumType = data["album_type"] as? String ?? ""
        let showOnList = data["showOnList"] as? Bool ?? false
        let isExplicit = data["isExplicit"] as? Bool ?? false
        let rating = data["rating"] as? Int
        let comment = data["comment"] as? String
        let isCompleted = data["isCompleted"] as? Bool ?? false

        // Correctly get the artist document references
        let artistRefs = data["artists"] as? [DocumentReference] ?? []

        if let imageDicts = data["images"] as? [[String: Any]] {
            let images = imageDicts.compactMap { ImageDTO.toImageResponse(from: $0) }
            return AlbumDTO(id: id, name: name, releaseDate: releaseDate, albumType: albumType, images: images, artists: artistRefs, showOnList: showOnList, isExplicit: isExplicit, rating: rating, comment: comment, isCompleted: isCompleted)
        } else if let imageRefs = data["images"] as? [DocumentReference] {
            let fetchedImages = try await withThrowingTaskGroup(of: ImageResponse?.self) { group -> [ImageResponse] in
                for imageRef in imageRefs {
                    group.addTask {
                        try await ImageDTO.toImageResponse(from: imageRef)
                    }
                }
                var results: [ImageResponse] = []
                for try await image in group {
                    if let image = image {
                        results.append(image)
                    }
                }
                return results
            }
            return AlbumDTO(id: id, name: name, releaseDate: releaseDate, albumType: albumType, images: fetchedImages, artists: artistRefs, showOnList: showOnList, isExplicit: isExplicit, rating: rating, comment: comment, isCompleted: isCompleted)
        } else {
            return AlbumDTO(id: id, name: name, releaseDate: releaseDate, albumType: albumType, images: [], artists: artistRefs, showOnList: showOnList, isExplicit: isExplicit, rating: rating, comment: comment, isCompleted: isCompleted)
        }
    }
}

// MARK: - SongDTO

struct SongDTO: Codable {
    var id: String = ""
    let name: String
    let popularity: Int
    let durationMs: Int
    var isExplicit: Bool
    var album: DocumentReference?
    var artists: [DocumentReference] = []
    var rating: Int?
    var comment: String?
    var isCompleted: Bool?

    enum CodingKeys: String, CodingKey {
        case name, popularity, durationMs, isExplicit, album, artists, rating, comment, isCompleted
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        popularity = try container.decode(Int.self, forKey: .popularity)
        durationMs = try container.decode(Int.self, forKey: .durationMs)
        if let explicit = try? container.decode(Bool.self, forKey: .isExplicit) {
            isExplicit = explicit
        } else if let explicitInt = try? container.decode(Int.self, forKey: .isExplicit) {
            isExplicit = explicitInt != 0
        } else {
            isExplicit = false
        }
        album = try? container.decode(DocumentReference.self, forKey: .album)
        artists = (try? container.decode([DocumentReference].self, forKey: .artists)) ?? []
        rating = try? container.decode(Int.self, forKey: .rating)
        comment = try? container.decode(String.self, forKey: .comment)
        isCompleted = (try? container.decode(Bool.self, forKey: .isCompleted)) ?? false
    }

    static func toSong(from dto: SongDTO) async throws -> Song? {
        guard let albumRef = dto.album else {
            print("Album reference is missing")
            return nil
        }

        // Fetch the album using our custom mapping.
        guard let albumDTO = try await AlbumDTO.toAlbum(from: albumRef) else {
            print("Failed to fetch album")
            return nil
        }

        let artists = try await withThrowingTaskGroup(of: Artist?.self) { group -> [Artist] in
            for artistRef in dto.artists {
                group.addTask {
                    try await ArtistDTO.toArtist(from: artistRef)
                }
            }
            var results: [Artist] = []
            for try await artist in group {
                if let artist = artist {
                    results.append(artist)
                }
            }
            return results
        }

        return Song(
            id: dto.id,
            album: Album(
                id: albumDTO.id,
                images: albumDTO.images, // Now we include fetched images.
                name: albumDTO.name,
                releaseDate: albumDTO.releaseDate,
                artists: [],
                albumType: albumDTO.albumType, // Fetch album artists if required.
                rating: albumDTO.rating,
                comment: albumDTO.comment,
                isCompleted: albumDTO.isCompleted
            ),
            artists: artists,
            durationMs: dto.durationMs,
            name: dto.name,
            popularity: dto.popularity,
            explicit: dto.isExplicit,
            rating: dto.rating,
            comment: dto.comment,
            isCompleted: dto.isCompleted
        )
    }
}

// MARK: - ImageDTO

struct ImageDTO: Codable {
    let height: Int
    let width: Int
    let url: String

    static func toImageResponse(from ref: DocumentReference) async throws -> ImageResponse? {
        let document = try await ref.getDocument()
        guard document.exists, let data = document.data() else {
            print("Image document does not exist")
            return nil
        }
        let url = data["url"] as? String ?? ""
        let height = data["height"] as? Int ?? 0
        let width = data["width"] as? Int ?? 0
        return ImageResponse(url: url, height: height, width: width)
    }

    static func toImageResponse(from dict: [String: Any]) -> ImageResponse? {
        guard let url = dict["url"] as? String else { return nil }
        let height = dict["height"] as? Int
        let width = dict["width"] as? Int
        return ImageResponse(url: url, height: height, width: width)
    }
}
