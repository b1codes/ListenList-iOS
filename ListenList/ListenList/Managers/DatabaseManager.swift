// ListenList/ListenList/Managers/DatabaseManager.swift

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
                    self.fetchAlbum(from: albumRef) { albumDTO, albumError in
                        if let albumDTO = albumDTO {
                            print("Fetched album: \(albumDTO)")
                        }
                        
                        if let artistRefs = data["artists"] as? [DocumentReference] {
                            self.fetchArtists(from: artistRefs) { artists, artistError in
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
                        self.fetchArtists(from: artistRefs) { artists, artistError in
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
        AlbumDTO.toAlbum(from: ref) { albumDTO in
            if let albumDTO = albumDTO {
                completion(albumDTO, nil)
            } else {
                // Create a simple error if necessary.
                let error = NSError(domain: "Album decode", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to decode album data"])
                completion(nil, error)
            }
        }
    }
    
    func fetchAlbum(withId albumId: String, completion: @escaping (Album?) -> Void) {
        let albumRef = db.collection("albums").document(albumId)

        AlbumDTO.toAlbum(from: albumRef) { albumDTO in
            guard let albumDTO = albumDTO else {
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
        }
    }


    
    // Update fetchArtists to use the custom mapping from ArtistDTO.toArtist
    func fetchArtists(from refs: [DocumentReference], completion: @escaping ([Artist]?, Error?) -> Void) {
        var artists: [Artist] = []
        let group = DispatchGroup()
        
        for ref in refs {
            group.enter()
            ArtistDTO.toArtist(from: ref) { artist in
                if let artist = artist {
                    artists.append(artist)
                } else {
                    print("Error decoding artist data from \(ref.path)")
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(artists, nil)
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
            "durationMs": song.duration_ms,
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
        
        let albumData: [String: Any] = [
            "name": album.name,
            "release_date": album.release_date,
            "images": album.images.map { ["url": $0.url, "height": $0.height ?? 0, "width": $0.width ?? 0] },
            "artists": album.artists.map { db.collection("artists").document($0.id) },
            "showOnList": showOnList,
            "album_type": album.album_type
        ]
        db.collection("albums").document(album.id).setData(albumData, merge: true, completion: completion)
    }
    
    func addPodcast(podcast: Podcast, completion: @escaping (Error?) -> Void) {
        let podcastData: [String: Any] = [
            "name": podcast.name,
            "publisher": podcast.publisher,
            "images": podcast.images.map { ["url": $0.url, "height": $0.height ?? 0, "width": $0.width ?? 0] },
            "explicit": podcast.explicit,
            "description": podcast.description,
            "total_episodes": podcast.total_episodes
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
            "total_chapters": audiobook.total_chapters
        ]
        db.collection("audiobooks").document(audiobook.id).setData(audiobookData, completion: completion)
    }

    
    func updateArtistShowOnList(withId artistId: String, showOnList: Bool, completion: @escaping (Error?) -> Void) {
        db.collection("artists").document(artistId).updateData([
            "showOnList": showOnList
        ], completion: completion)
    }


    func addArtist(artist: Artist, showOnList: Bool, completion: @escaping (Error?) -> Void) {
        let artistData: [String: Any] = [
            "name": artist.name,
            "popularity": artist.popularity ?? 0,
            "images": artist.images?.map { ["url": $0.url, "height": $0.height ?? 0, "width": $0.width ?? 0] } ?? [],
            "showOnList": showOnList
        ]
        db.collection("artists").document(artist.id).setData(artistData, merge: true, completion: completion)
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

}
