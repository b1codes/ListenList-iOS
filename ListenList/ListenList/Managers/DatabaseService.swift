// ListenList/ListenList/Managers/DatabaseService.swift
//
//  DatabaseService.swift
//  ListenList
//

import Foundation

/// Abstracts all Firestore interactions needed by ListManager.
/// All method signatures use only domain types — no Firestore types cross this boundary,
/// which makes it straightforward to substitute a mock in tests.
protocol DatabaseService {

    // MARK: - Fetch lists

    func fetchSongs(completion: @escaping ([Song]) -> Void)
    func fetchAlbums(completion: @escaping ([Album]) -> Void)
    func fetchArtists(completion: @escaping ([Artist]) -> Void)
    func fetchPodcasts(completion: @escaping ([Podcast]) -> Void)
    func fetchAudiobooks(completion: @escaping ([Audiobook]) -> Void)

    // MARK: - Remove from list

    /// Permanently deletes a song document.
    func deleteSong(withId id: String, completion: @escaping (Error?) -> Void)

    /// Sets showOnList = false on an album (keeps the document for reference data).
    func removeAlbumFromList(withId id: String, completion: @escaping (Error?) -> Void)

    /// Sets showOnList = false on an artist.
    func removeArtistFromList(withId id: String, completion: @escaping (Error?) -> Void)

    /// Permanently deletes a podcast document.
    func deletePodcast(withId id: String, completion: @escaping (Error?) -> Void)

    /// Permanently deletes an audiobook document.
    func deleteAudiobook(withId id: String, completion: @escaping (Error?) -> Void)
}
