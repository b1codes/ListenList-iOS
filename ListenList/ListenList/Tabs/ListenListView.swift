// ListenList/ListenList/Tabs/ListenListView.swift

//
//  ListenListView.swift
//  ListenList
//
//  Created by Brandon Lamer-Connolly on 10/11/24.
//

import SwiftUI
import FirebaseFirestore

struct ListenListView: View {
    
    @State private var cards: [Card] = [] // Holds the list of cards
    @State private var songs: [Song] = []   // Use the SwiftUI-compatible Song type
    @State private var isLoading = true     // Track loading state
    
    func createCard(from song: Song) -> Card {
        let media = Media(input: .song(song)) // Wrap the Song in a MediaType
        return Card(input: .song, media: media, id: song.id) // Create the Card
    }
    
    func fetchSongList() {
        var songIds: [String] = []
        isLoading = true // Start loading
        
        // Fetch song IDs
        DatabaseManager.shared.fetchSongIds { documents, error in
            if let error = error {
                print("Error fetching song IDs: \(error.localizedDescription)")
                self.isLoading = false
                return
            }
            
            guard let documents = documents else {
                print("No song documents found.")
                self.isLoading = false
                return
            }
            
            songIds = documents.map { $0.documentID } // Extract IDs
            
            var fetchedSongs: [Song] = []
            let group = DispatchGroup()
            
            // For each song ID, call fetchSong and then convert the DTO to a Song.
            for songId in songIds {
                group.enter() // Enter group for fetchSong
                DatabaseManager.shared.fetchSong(withId: songId) { songDTO, error in
                    defer { group.leave() } // Mark fetchSong complete regardless
                    
                    if let error = error {
                        print("Error fetching song with ID \(songId): \(error.localizedDescription)")
                        return
                    }
                    
                    guard let songDTO = songDTO else {
                        print("No songDTO found for ID \(songId).")
                        return
                    }
                    
                    // Wait for the asynchronous conversion from SongDTO to Song.
                    group.enter() // Enter group for SongDTO.toSong
                    SongDTO.toSong(from: songDTO) { song in
                        if let song = song {
                            fetchedSongs.append(song)
                        } else {
                            print("Failed to convert songDTO to Song for ID \(songId).")
                        }
                        group.leave() // Mark SongDTO.toSong complete
                    }
                }
            }
            
            // Notify when all asynchronous operations are finished.
            group.notify(queue: .main) {
                self.updateUI(with: fetchedSongs)
            }
        }
    }

    private func updateUI(with songs: [Song]) {
        // Convert songs to cards and update the UI.
        self.cards = songs.map { createCard(from: $0) }
        self.isLoading = false
        print("Successfully loaded \(songs.count) songs.")
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    if isLoading {
                        ProgressView("Loading songs...")
                    } else if songs.isEmpty && cards.isEmpty {
                        Text("No songs found.")
                    } else {
                        CardList(results: self.cards)
                    }
//                    UNCOMMENT BELOW FOR DEBUGGING PURPOSES
//                    Text("song count: \(songs.count)")
//                    Text("card count: \(cards.count)")
                }
            }
            .navigationTitle("Your ListenList")
            .onAppear {
                fetchSongList()
            }
        }
    }
}
