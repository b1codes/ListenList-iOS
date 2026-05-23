//
//  DatabaseManager.swift
//  ListenList
//
//  Created by Brandon Lamer-Connolly on 10/12/24.
//

import Foundation
import FirebaseCore
import FirebaseFirestore

class DatabaseManager {
    static let shared = DatabaseManager()
    let db = Firestore.firestore()

    private init() {}

    func addUser(name: String, age: Int, completion: @escaping (Error?) -> Void) {
        let userData: [String: Any] = ["name": name, "age": age]
        db.collection("users").addDocument(data: userData, completion: completion)
    }

    func fetchUsers(completion: @escaping ([DocumentSnapshot]?, Error?) -> Void) {
        db.collection("users").getDocuments { snapshot, error in
            completion(snapshot?.documents, error)
        }
    }

    func fetchSongIds(completion: @escaping ([DocumentSnapshot]?, Error?) -> Void) {
        db.collection("songs").getDocuments { snapshot, error in
            completion(snapshot?.documents, error)
        }
    }

    func fetchAlbumIds(completion: @escaping ([DocumentSnapshot]?, Error?) -> Void) {
        db.collection("albums").getDocuments { snapshot, error in
            completion(snapshot?.documents, error)
        }
    }

    func fetchDocumentIds(fromCollection collection: String, completion: @escaping (Set<String>, Error?) -> Void) {
        db.collection(collection).getDocuments { snapshot, error in
            if let error = error {
                completion([], error)
                return
            }

            guard let documents = snapshot?.documents else {
                completion([], nil)
                return
            }

            let ids = Set(documents.map { $0.documentID })
            completion(ids, nil)
        }
    }

    func fetchArtistIdsInListenList(completion: @escaping (Set<String>, Error?) -> Void) {
        db.collection("artists").whereField("showOnList", isEqualTo: true).getDocuments { snapshot, error in
            if let error = error {
                completion([], error)
                return
            }

            guard let documents = snapshot?.documents else {
                completion([], nil)
                return
            }

            let ids = Set(documents.map { $0.documentID })
            completion(ids, nil)
        }
    }

    func fetchSong(withId songId: String, completion: @escaping (SongDTO?, Error?) -> Void) {
        let songRef = db.collection("songs").document(songId)
        songRef.getDocument { snapshot, error in
            guard let snapshot = snapshot,
                  let data = snapshot.data(), error == nil else {
                print("Error fetching song data for ID \(songId): \(error?.localizedDescription ?? "Unknown error")")
                completion(nil, error)
                return
            }

            // Debug log of raw data.
            print("Raw song data for ID \(songId): \(data)")

            do {
                var songDTO = try Firestore.Decoder().decode(SongDTO.self, from: data)
                // Set the SongDTO's id from the document's snapshot.
                songDTO.id = snapshot.documentID

                // Optionally fetch the album and artists for debugging purposes.
                if let albumRef = data["album"] as? DocumentReference {
                    self.fetchAlbum(from: albumRef) { albumDTO, _ in
                        if let albumDTO = albumDTO {
                            print("Fetched album: \(albumDTO)")
                        }

                        if let artistRefs = data["artists"] as? [DocumentReference] {
                            self.fetchArtists(from: artistRefs) { artists, _ in
                                if let artists = artists {
                                    print("Fetched artists: \(artists)")
                                }
                                completion(songDTO, nil)
                            }
                        } else {
                            completion(songDTO, nil)
                        }
                    }
                } else {
                    if let artistRefs = data["artists"] as? [DocumentReference] {
                        self.fetchArtists(from: artistRefs) { artists, _ in
                            if let artists = artists {
                                print("Fetched artists: \(artists)")
                            }
                            completion(songDTO, nil)
                        }
                    } else {
                        completion(songDTO, nil)
                    }
                }
            } catch let error as DecodingError {
                print("Decoding error for song ID \(songId): \(error.localizedDescription)")
                switch error {
                case .typeMismatch(let type, let context):
                    print("Type mismatch error: \(type) at \(context.codingPath)")
                case .valueNotFound(let value, let context):
                    print("Value not found error: \(value) at \(context.codingPath)")
                case .keyNotFound(let key, let context):
                    print("Key not found error: \(key) at \(context.codingPath)")
                case .dataCorrupted(let context):
                    print("Data corrupted error: \(context)")
                default:
                    print("Unknown decoding error: \(error.localizedDescription)")
                }
                completion(nil, error)
            } catch {
                print("Unexpected error for song ID \(songId): \(error.localizedDescription)")
                completion(nil, error)
            }
        }
    }

    // Instead of using Firestore.Decoder(), use the custom static method for mapping.
    func fetchAlbum(from ref: DocumentReference, completion: @escaping (AlbumDTO?, Error?) -> Void) {
        Task {
            do {
                let albumDTO = try await AlbumDTO.toAlbum(from: ref)
                if let albumDTO = albumDTO {
                    completion(albumDTO, nil)
                } else {
                    let error = NSError(domain: "Album decode", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to decode album data"])
                    completion(nil, error)
                }
            } catch {
                completion(nil, error)
            }
        }
    }

    func fetchAlbum(withId albumId: String, completion: @escaping (Album?) -> Void) {
        let albumRef = db.collection("albums").document(albumId)

        Task {
            do {
                guard let albumDTO = try await AlbumDTO.toAlbum(from: albumRef) else {
                    completion(nil)
                    return
                }

                self.fetchArtists(from: albumDTO.artists) { artists, error in
                    if let error = error {
                        print("Error fetching artists for album \(albumId): \(error.localizedDescription)")
                        let album = Album(from: albumDTO, artists: [])
                        completion(album)
                        return
                    }

                    let album = Album(from: albumDTO, artists: artists ?? [])
                    completion(album)
                }
            } catch {
                print("Error fetching album \(albumId): \(error.localizedDescription)")
                completion(nil)
            }
        }
    }

    // Update fetchArtists to use the custom mapping from ArtistDTO.toArtist
    func fetchArtists(from refs: [DocumentReference], completion: @escaping ([Artist]?, Error?) -> Void) {
        Task {
            do {
                let artists = try await withThrowingTaskGroup(of: Artist?.self) { group -> [Artist] in
                    for ref in refs {
                        group.addTask {
                            try await ArtistDTO.toArtist(from: ref)
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
                completion(artists, nil)
            } catch {
                completion(nil, error)
            }
        }
    }

    private func fetchImages(from imageRefs: [DocumentReference], completion: @escaping ([ImageDTO], Error?) -> Void) {
        var images: [ImageDTO] = []
        let dispatchGroup = DispatchGroup()

        for ref in imageRefs {
            dispatchGroup.enter()
            ref.getDocument { snapshot, error in
                if let error = error {
                    print("Error fetching image data for \(ref.path): \(error.localizedDescription)")
                } else if let data = snapshot?.data() {
                    do {
                        let image = try Firestore.Decoder().decode(ImageDTO.self, from: data)
                        images.append(image)
                    } catch {
                        print("Error decoding image data for \(ref.path): \(error.localizedDescription)")
                    }
                } else {
                    print("Image document is missing or empty for \(ref.path)")
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion(images, nil)
        }
    }

    // MARK: - Add Functions

    func addSong(song: Song, completion: @escaping (Error?) -> Void) {
        // Add the album but mark it as not to be shown on the list
        addAlbum(album: song.album, showOnList: false) { error in
            if let error = error {
                print("Error adding album from song: \(error.localizedDescription)")
            }
        }

        // Add each artist but mark them as not to be shown on the list
        for artist in song.artists {
            addArtist(artist: artist, showOnList: false) { error in
                if let error = error {
                    print("Error adding artist from song: \(error.localizedDescription)")
                }
            }
        }

        let songData: [String: Any] = [
            "name": song.name,
            "popularity": song.popularity,
            "durationMs": song.durationMs,
            "isExplicit": song.explicit,
            "album": db.collection("albums").document(song.album.id),
            "artists": song.artists.map { db.collection("artists").document($0.id) }
        ]
        db.collection("songs").document(song.id).setData(songData, completion: completion)
    }

    func addAlbum(album: Album, showOnList: Bool, completion: @escaping (Error?) -> Void) {
        // Add each artist but mark them as not to be shown on the list
        for artist in album.artists {
            addArtist(artist: artist, showOnList: false) { error in
                if let error = error {
                    print("Error adding artist from album: \(error.localizedDescription)")
                }
            }
        }

        let albumRef = db.collection("albums").document(album.id)
        albumRef.getDocument { (document, _) in
            var albumData: [String: Any] = [
                "name": album.name,
                "release_date": album.releaseDate,
                "images": album.images.map { ["url": $0.url, "height": $0.height ?? 0, "width": $0.width ?? 0] },
                "artists": album.artists.map { self.db.collection("artists").document($0.id) },
                "album_type": album.albumType
            ]

            if let document = document, document.exists {
                // Only update showOnList if we're explicitly setting it to true
                if showOnList {
                    albumData["showOnList"] = true
                }
            } else {
                // New document, set to the requested value
                albumData["showOnList"] = showOnList
            }

            albumRef.setData(albumData, merge: true, completion: completion)
        }
    }

    func addPodcast(podcast: Podcast, completion: @escaping (Error?) -> Void) {
        let podcastData: [String: Any] = [
            "name": podcast.name,
            "publisher": podcast.publisher,
            "images": podcast.images.map { ["url": $0.url, "height": $0.height ?? 0, "width": $0.width ?? 0] },
            "explicit": podcast.explicit,
            "description": podcast.description,
            "total_episodes": podcast.totalEpisodes
        ]
        db.collection("podcasts").document(podcast.id).setData(podcastData, completion: completion)
    }

    func addAudiobook(audiobook: Audiobook, completion: @escaping (Error?) -> Void) {
        let audiobookData: [String: Any] = [
            "name": audiobook.name,
            "authors": audiobook.authors.map { ["name": $0.name] },
            "images": audiobook.images.map { ["url": $0.url, "height": $0.height ?? 0, "width": $0.width ?? 0] },
            "explicit": audiobook.explicit,
            "description": audiobook.description,
            "edition": audiobook.edition,
            "narrators": audiobook.narrators.map { ["name": $0.name] },
            "publisher": audiobook.publisher,
            "total_chapters": audiobook.totalChapters ?? 0 // Provide default value
        ]
        db.collection("audiobooks").document(audiobook.id).setData(audiobookData, completion: completion)
    }

    func updateArtistShowOnList(withId artistId: String, showOnList: Bool, completion: @escaping (Error?) -> Void) {
        db.collection("artists").document(artistId).updateData([
            "showOnList": showOnList
        ], completion: completion)
    }

    func updateAlbumShowOnList(withId albumId: String, showOnList: Bool, completion: @escaping (Error?) -> Void) {
        db.collection("albums").document(albumId).updateData([
            "showOnList": showOnList
        ], completion: completion)
    }

    func addArtist(artist: Artist, showOnList: Bool, completion: @escaping (Error?) -> Void) {
        let artistRef = db.collection("artists").document(artist.id)
        artistRef.getDocument { (document, _) in
            var artistData: [String: Any] = [
                "name": artist.name,
                "popularity": artist.popularity ?? 0,
                "images": artist.images?.map { ["url": $0.url, "height": $0.height ?? 0, "width": $0.width ?? 0] } ?? []
            ]

            if let document = document, document.exists {
                // Only update showOnList if we're explicitly setting it to true
                if showOnList {
                    artistData["showOnList"] = true
                }
            } else {
                // New document, set to the requested value
                artistData["showOnList"] = showOnList
            }

            artistRef.setData(artistData, merge: true, completion: completion)
        }
    }

    // MARK: - Delete Functions

    func deleteSong(withId songId: String, completion: @escaping (Error?) -> Void) {
        db.collection("songs").document(songId).delete(completion: completion)
    }

    func deleteAlbum(withId albumId: String, completion: @escaping (Error?) -> Void) {
        db.collection("albums").document(albumId).delete(completion: completion)
    }

    func deleteArtist(withId artistId: String, completion: @escaping (Error?) -> Void) {
        db.collection("artists").document(artistId).delete(completion: completion)
    }

    func deletePodcast(withId podcastId: String, completion: @escaping (Error?) -> Void) {
        db.collection("podcasts").document(podcastId).delete(completion: completion)
    }

    func deleteAudiobook(withId audiobookId: String, completion: @escaping (Error?) -> Void) {
        db.collection("audiobooks").document(audiobookId).delete(completion: completion)
    }

    // MARK: - Log as Completed Functions

    func logSongAsCompleted(withId songId: String, rating: Int, comment: String, completion: @escaping (Error?) -> Void) {
        db.collection("songs").document(songId).updateData([
            "isCompleted": true,
            "rating": rating,
            "comment": comment
        ], completion: completion)
    }

    func logAlbumAsCompleted(withId albumId: String, rating: Int, comment: String, completion: @escaping (Error?) -> Void) {
        db.collection("albums").document(albumId).updateData([
            "isCompleted": true,
            "rating": rating,
            "comment": comment
        ], completion: completion)
    }

    func logPodcastAsCompleted(withId podcastId: String, rating: Int, comment: String, completion: @escaping (Error?) -> Void) {
        db.collection("podcasts").document(podcastId).updateData([
            "isCompleted": true,
            "rating": rating,
            "comment": comment
        ], completion: completion)
    }

    func logAudiobookAsCompleted(withId audiobookId: String, rating: Int, comment: String, completion: @escaping (Error?) -> Void) {
        db.collection("audiobooks").document(audiobookId).updateData([
            "isCompleted": true,
            "rating": rating,
            "comment": comment
        ], completion: completion)
    }

    func fetchHighRatedMedia(collection: String, completion: @escaping ([QueryDocumentSnapshot]?, Error?) -> Void) {
        db.collection(collection)
            .whereField("isCompleted", isEqualTo: true)
            .whereField("rating", isGreaterThanOrEqualTo: 4)
            .limit(to: 10)
            .getDocuments { snapshot, error in
                completion(snapshot?.documents, error)
            }
    }
}

// MARK: - DatabaseService conformance

extension DatabaseManager: DatabaseService {

    func fetchSongs(completion: @escaping ([Song]) -> Void) {
        fetchSongIds { documents, error in
            guard let documents = documents, error == nil, !documents.isEmpty else {
                completion([])
                return
            }

            let songIds = documents.map { $0.documentID }

            Task {
                do {
                    let fetchedSongs = try await withThrowingTaskGroup(of: Song?.self) { group -> [Song] in
                        for songId in songIds {
                            group.addTask {
                                // For each song, we use withCheckedThrowingContinuation to bridge fetchSong callback to async
                                let songDTO: SongDTO? = try await withCheckedThrowingContinuation { continuation in
                                    self.fetchSong(withId: songId) { dto, error in
                                        if let error = error {
                                            continuation.resume(throwing: error)
                                        } else {
                                            continuation.resume(returning: dto)
                                        }
                                    }
                                }
                                guard let dto = songDTO else { return nil }
                                return try await SongDTO.toSong(from: dto)
                            }
                        }
                        var results: [Song] = []
                        for try await song in group {
                            if let song = song { results.append(song) }
                        }
                        return results
                    }
                    DispatchQueue.main.async { completion(fetchedSongs) }
                } catch {
                    print("Error fetching songs: \(error)")
                    DispatchQueue.main.async { completion([]) }
                }
            }
        }
    }

    func fetchAlbums(completion: @escaping ([Album]) -> Void) {
        db.collection("albums").whereField("showOnList", isEqualTo: true).getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, error == nil, !documents.isEmpty else {
                completion([])
                return
            }

            Task {
                do {
                    let fetchedAlbums = try await withThrowingTaskGroup(of: Album?.self) { group -> [Album] in
                        for document in documents {
                            group.addTask {
                                let albumId = document.documentID
                                return await withCheckedContinuation { continuation in
                                    self.fetchAlbum(withId: albumId) { album in
                                        continuation.resume(returning: album)
                                    }
                                }
                            }
                        }
                        var results: [Album] = []
                        for try await album in group {
                            if let album = album { results.append(album) }
                        }
                        return results
                    }
                    DispatchQueue.main.async { completion(fetchedAlbums) }
                } catch {
                    print("Error fetching albums: \(error)")
                    DispatchQueue.main.async { completion([]) }
                }
            }
        }
    }

    func fetchArtists(completion: @escaping ([Artist]) -> Void) {
        db.collection("artists").whereField("showOnList", isEqualTo: true).getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, error == nil, !documents.isEmpty else {
                completion([])
                return
            }

            Task {
                do {
                    let fetchedArtists = try await withThrowingTaskGroup(of: Artist?.self) { group -> [Artist] in
                        for document in documents {
                            group.addTask {
                                try await ArtistDTO.toArtist(from: document.reference)
                            }
                        }
                        var results: [Artist] = []
                        for try await artist in group {
                            if let artist = artist { results.append(artist) }
                        }
                        return results
                    }
                    DispatchQueue.main.async { completion(fetchedArtists) }
                } catch {
                    print("Error fetching artists: \(error)")
                    DispatchQueue.main.async { completion([]) }
                }
            }
        }
    }

    func fetchPodcasts(completion: @escaping ([Podcast]) -> Void) {
        db.collection("podcasts").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, error == nil else {
                completion([])
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
                let totalEpisodes = data["total_episodes"] as? Int ?? 0
                let rating = data["rating"] as? Int
                let comment = data["comment"] as? String
                let isCompleted = data["isCompleted"] as? Bool ?? false
                return Podcast(id: id, name: name, publisher: publisher, images: images,
                               explicit: explicit, description: description,
                               totalEpisodes: totalEpisodes, rating: rating,
                               comment: comment, isCompleted: isCompleted)
            }
            completion(podcasts)
        }
    }

    func fetchAudiobooks(completion: @escaping ([Audiobook]) -> Void) {
        db.collection("audiobooks").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, error == nil else {
                completion([])
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
                let totalChapters = data["total_chapters"] as? Int
                let rating = data["rating"] as? Int
                let comment = data["comment"] as? String
                let isCompleted = data["isCompleted"] as? Bool ?? false
                return Audiobook(id: id, name: name, authors: authors, images: images,
                                 explicit: explicit, description: description, edition: edition,
                                 narrators: narrators, publisher: publisher,
                                 totalChapters: totalChapters, rating: rating,
                                 comment: comment, isCompleted: isCompleted)
            }
            completion(audiobooks)
        }
    }

    func removeAlbumFromList(withId id: String, completion: @escaping (Error?) -> Void) {
        updateAlbumShowOnList(withId: id, showOnList: false, completion: completion)
    }

    func removeArtistFromList(withId id: String, completion: @escaping (Error?) -> Void) {
        updateArtistShowOnList(withId: id, showOnList: false, completion: completion)
    }
}
