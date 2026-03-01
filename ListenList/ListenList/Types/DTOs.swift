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

    static func toArtist(from ref: DocumentReference, completion: @escaping (Artist?) -> Void) {
        ref.getDocument { (document, error) in
            if let error = error {
                print("Error getting artist document: \(error)")
                completion(nil)
                return
            }
            guard let document = document, document.exists, let data = document.data() else {
                print("Artist document does not exist")
                completion(nil)
                return
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
            completion(artist)
        }
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

    static func toAlbum(from ref: DocumentReference, completion: @escaping (AlbumDTO?) -> Void) {
        ref.getDocument { (document, error) in
            if let error = error {
                print("Error getting album document: \(error)")
                completion(nil)
                return
            }
            guard let document = document, document.exists, let data = document.data() else {
                print("Album document does not exist")
                completion(nil)
                return
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
                let albumDTO = AlbumDTO(id: id, name: name, releaseDate: releaseDate, albumType: albumType, images: images, artists: artistRefs, showOnList: showOnList, isExplicit: isExplicit, rating: rating, comment: comment, isCompleted: isCompleted)
                completion(albumDTO)
            } else if let imageRefs = data["images"] as? [DocumentReference] {
                var fetchedImages: [ImageResponse] = []
                let group = DispatchGroup()
                
                for imageRef in imageRefs {
                    group.enter()
                    ImageDTO.toImageResponse(from: imageRef) { image in
                        if let image = image {
                            fetchedImages.append(image)
                        }
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    let albumDTO = AlbumDTO(id: id, name: name, releaseDate: releaseDate, albumType: albumType, images: fetchedImages, artists: artistRefs, showOnList: showOnList, isExplicit: isExplicit, rating: rating, comment: comment, isCompleted: isCompleted)
                    completion(albumDTO)
                }
            } else {
                let albumDTO = AlbumDTO(id: id, name: name, releaseDate: releaseDate, albumType: albumType, images: [], artists: artistRefs, showOnList: showOnList, isExplicit: isExplicit, rating: rating, comment: comment, isCompleted: isCompleted)
                completion(albumDTO)
            }
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
    
    static func toSong(from dto: SongDTO, completion: @escaping (Song?) -> Void) {
        guard let albumRef = dto.album else {
            print("Album reference is missing")
            completion(nil)
            return
        }
        
        // Fetch the album using our custom mapping.
        AlbumDTO.toAlbum(from: albumRef) { albumDTO in
            guard let albumDTO = albumDTO else {
                print("Failed to fetch album")
                completion(nil)
                return
            }
            
            var artists: [Artist] = []
            let group = DispatchGroup()
            for artistRef in dto.artists {
                group.enter()
                ArtistDTO.toArtist(from: artistRef) { artist in
                    if let artist = artist {
                        artists.append(artist)
                    }
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                let song = Song(
                    id: dto.id,
                    album: Album(
                        id: albumDTO.id,
                        images: albumDTO.images, // Now we include fetched images.
                        name: albumDTO.name,
                        release_date: albumDTO.releaseDate,
                        artists: [],
                        album_type: albumDTO.albumType, // Fetch album artists if required.
                        rating: albumDTO.rating,
                        comment: albumDTO.comment,
                        isCompleted: albumDTO.isCompleted
                    ),
                    artists: artists,
                    duration_ms: dto.durationMs,
                    name: dto.name,
                    popularity: dto.popularity,
                    explicit: dto.isExplicit,
                    rating: dto.rating,
                    comment: dto.comment,
                    isCompleted: dto.isCompleted
                )
                completion(song)
            }
        }
    }
}

// MARK: - ImageDTO

struct ImageDTO: Codable {
    let height: Int
    let width: Int
    let url: String
    
    static func toImageResponse(from ref: DocumentReference, completion: @escaping (ImageResponse?) -> Void) {
        ref.getDocument { (document, error) in
            if let error = error {
                print("Error getting image document: \(error)")
                completion(nil)
                return
            }
            guard let document = document, document.exists, let data = document.data() else {
                print("Image document does not exist")
                completion(nil)
                return
            }
            let url = data["url"] as? String ?? ""
            let height = data["height"] as? Int ?? 0
            let width = data["width"] as? Int ?? 0
            let imageResponse = ImageResponse(url: url, height: height, width: width)
            completion(imageResponse)
        }
    }
    
    static func toImageResponse(from dict: [String: Any]) -> ImageResponse? {
        guard let url = dict["url"] as? String else { return nil }
        let height = dict["height"] as? Int
        let width = dict["width"] as? Int
        return ImageResponse(url: url, height: height, width: width)
    }
}
