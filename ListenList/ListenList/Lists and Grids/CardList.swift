// ListenList/ListenList/Lists and Grids/CardList.swift

import SwiftUI

struct CardList: View {
    var results: [Card]
    private let columns = [GridItem(.flexible())]
    var onAdd: ((Card) -> Void)?
    var isInEditMode: Bool = false
    var onDelete: ((Card) -> Void)?

    var body: some View {
        LazyVGrid(columns: columns, alignment: .center, spacing: 10) {
            ForEach(results, id: \.id) { item in
                let addAction = onAdd.map { addFunc in
                    { addFunc(item) }
                }
                
                let deleteAction = onDelete.map { deleteFunc in
                    { deleteFunc(item) }
                }

                switch item.type {
                case .song:
                    SongCard(input: item.input, onAdd: addAction, isInEditMode: isInEditMode, onDelete: deleteAction)
                case .album:
                    AlbumCard(input: item.input, onAdd: addAction, isInEditMode: isInEditMode, onDelete: deleteAction)
                case .artist:
                    ArtistCard(input: item.input, onAdd: addAction, isInEditMode: isInEditMode, onDelete: deleteAction)
                case .podcast:
                    PodcastCard(input: item.input, onAdd: addAction, isInEditMode: isInEditMode, onDelete: deleteAction)
                case .audiobook:
                    AudiobookCard(input: item.input, onAdd: addAction, isInEditMode: isInEditMode, onDelete: deleteAction)
                }
            }
        }
        .id(results.count)
    }
}
