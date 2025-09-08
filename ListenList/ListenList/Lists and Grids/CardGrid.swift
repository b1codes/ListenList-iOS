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
        }
        .id(results.count)
    }
}
