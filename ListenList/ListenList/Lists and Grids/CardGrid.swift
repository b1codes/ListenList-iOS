// ListenList/ListenList/Lists and Grids/CardGrid.swift

import SwiftUI

struct CardGrid: View {
    var results: [Card]
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    var onAdd: ((Card) -> Void)?
    var isInEditMode: Bool = false
    var onDelete: ((Card) -> Void)?

    var body: some View {
        LazyVGrid(columns: columns, alignment: .center, spacing: 20) {
            ForEach(results, id: \.id) { item in
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
                            SongGridCard(input: item.input, onAdd: addAction, isInEditMode: isInEditMode, onDelete: deleteAction)
                        case .album:
                            AlbumGridCard(input: item.input, onAdd: addAction, isInEditMode: isInEditMode, onDelete: deleteAction)
                        case .artist:
                            ArtistGridCard(input: item.input, onAdd: addAction, isInEditMode: isInEditMode, onDelete: deleteAction)
                        case .podcast:
                            PodcastGridCard(input: item.input, onAdd: addAction, isInEditMode: isInEditMode, onDelete: deleteAction)
                        case .audiobook:
                            AudiobookGridCard(input: item.input, onAdd: addAction, isInEditMode: isInEditMode, onDelete: deleteAction)
                        }
                    }
                    .disabled(isInEditMode)
                    .buttonStyle(PlainButtonStyle())
                    
                    if isInEditMode {
                        switch item.type {
                        case .song:
                            SongGridCard(input: item.input, onAdd: addAction, isInEditMode: true, onDelete: deleteAction)
                        case .album:
                            AlbumGridCard(input: item.input, onAdd: addAction, isInEditMode: true, onDelete: deleteAction)
                        case .artist:
                            ArtistGridCard(input: item.input, onAdd: addAction, isInEditMode: true, onDelete: deleteAction)
                        case .podcast:
                            PodcastGridCard(input: item.input, onAdd: addAction, isInEditMode: true, onDelete: deleteAction)
                        case .audiobook:
                            AudiobookGridCard(input: item.input, onAdd: addAction, isInEditMode: true, onDelete: deleteAction)
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
