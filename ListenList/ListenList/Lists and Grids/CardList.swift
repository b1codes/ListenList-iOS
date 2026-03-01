// ListenList/ListenList/Lists and Grids/CardList.swift

import SwiftUI

struct CardList: View {
    var results: [Card]
    private let columns = [GridItem(.flexible())]
    var onAdd: ((Card) -> Void)?
    var isInEditMode: Bool = false
    var onDelete: ((Card) -> Void)?
    var listenListIDs: Set<String> = []

    var body: some View {
        LazyVGrid(columns: columns, alignment: .center, spacing: 10) {
            ForEach(results, id: \.id) { item in
                let isSaved = listenListIDs.contains(item.id)
                let addAction = onAdd.map { addFunc in
                    { addFunc(item) }
                }
                
                let deleteAction = onDelete.map { deleteFunc in
                    { deleteFunc(item) }
                }

                ZStack {
                    NavigationLink {
                        destinationView(for: item)
                    } label: {
                        switch item.type {
                        case .song:
                            SongCard(input: item.input, onAdd: addAction, isInEditMode: isInEditMode, onDelete: deleteAction, isSaved: isSaved)
                        case .album:
                            AlbumCard(input: item.input, onAdd: addAction, isInEditMode: isInEditMode, onDelete: deleteAction, isSaved: isSaved)
                        case .artist:
                            ArtistCard(input: item.input, onAdd: addAction, isInEditMode: isInEditMode, onDelete: deleteAction, isSaved: isSaved)
                        case .podcast:
                            PodcastCard(input: item.input, onAdd: addAction, isInEditMode: isInEditMode, onDelete: deleteAction, isSaved: isSaved)
                        case .audiobook:
                            AudiobookCard(input: item.input, onAdd: addAction, isInEditMode: isInEditMode, onDelete: deleteAction, isSaved: isSaved)
                        }
                    }
                    .disabled(isInEditMode)
                    .buttonStyle(PlainButtonStyle())
                    
                    if isInEditMode {
                        switch item.type {
                        case .song:
                            SongCard(input: item.input, onAdd: addAction, isInEditMode: true, onDelete: deleteAction, isSaved: isSaved)
                        case .album:
                            AlbumCard(input: item.input, onAdd: addAction, isInEditMode: true, onDelete: deleteAction, isSaved: isSaved)
                        case .artist:
                            ArtistCard(input: item.input, onAdd: addAction, isInEditMode: true, onDelete: deleteAction, isSaved: isSaved)
                        case .podcast:
                            PodcastCard(input: item.input, onAdd: addAction, isInEditMode: true, onDelete: deleteAction, isSaved: isSaved)
                        case .audiobook:
                            AudiobookCard(input: item.input, onAdd: addAction, isInEditMode: true, onDelete: deleteAction, isSaved: isSaved)
                        }
                    }
                }
            }
        }
        .id(results.count)
    }

    @ViewBuilder
    private func destinationView(for item: Card) -> some View {
        switch item.input.input {
        case .song(let song):
            SongDetailView(song: song)
        case .album(let album):
            AlbumDetailView(album: album)
        case .artist(let artist):
            ArtistDetailView(artist: artist)
        case .podcast(let podcast):
            PodcastDetailView(podcast: podcast)
        case .audiobook(let audiobook):
            AudiobookDetailView(audiobook: audiobook)
        }
    }
}
