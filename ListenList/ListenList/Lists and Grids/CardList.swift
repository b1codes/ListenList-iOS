// ListenList/ListenList/Lists and Grids/CardList.swift

import SwiftUI

struct CardList: View {
    var results: [Card]
    private let columns = [GridItem(.flexible())]
    var onAdd: ((Card) -> Void)?

    var body: some View {
        LazyVGrid(columns: columns, alignment: .center, spacing: 10) {
            ForEach(results, id: \.id) { item in
                // Use an if-let to check if onAdd exists.
                if let onAdd = onAdd {
                    // If onAdd exists, create the card with the add action.
                    switch item.type {
                    case .song:
                        SongCard(input: item.input, onAdd: { onAdd(item) })
                    case .album:
                        AlbumCard(input: item.input, onAdd: { onAdd(item) })
                    case .artist:
                        ArtistCard(input: item.input, onAdd: { onAdd(item) })
                    }
                } else {
                    // If onAdd is nil, create the card without the add action.
                    switch item.type {
                    case .song:
                        SongCard(input: item.input)
                    case .album:
                        AlbumCard(input: item.input)
                    case .artist:
                        ArtistCard(input: item.input)
                    }
                }
            }
        }
        .id(results.count)
    }
}
//#Preview {
//    CardList(results: [Card(input: .song, media: Media(input: .song(Song( album: Album(images: [ImageResponse(url: "https://i.scdn.co/image/ab67616d0000b273f76f8deeba5370c98ad38f1c", height: 640, width: 640)], name: "Chemical", release_date: "2023-04-14", artists: [Artist(name: "Post Malone", artistId: "246dkjvS1zLTtiykXe5h60")]), artists: [Artist(name: "Post Malone", artistId: "246dkjvS1zLTtiykXe5h60")], duration_ms: 184013, name: "Chemical", popularity: 88, explicit: true))), id: "5"), Card(input: .song, media: Media(input: .song(Song( album: Album(images: [ImageResponse(url: "https://i.scdn.co/image/ab67616d0000b273f76f8deeba5370c98ad38f1c", height: 640, width: 640)], name: "Chemical", release_date: "2023-04-14", artists: [Artist(name: "Post Malone", artistId: "246dkjvS1zLTtiykXe5h60")]), artists: [Artist(name: "Post Malone", artistId: "246dkjvS1zLTtiykXe5h60")], duration_ms: 184013, name: "Chemical", popularity: 88, explicit: true))), id: "3"), Card(input: .song, media: Media(input: .song(Song( album: Album(images: [ImageResponse(url: "https://i.scdn.co/image/ab67616d0000b273f76f8deeba5370c98ad38f1c", height: 640, width: 640)], name: "Chemical", release_date: "2023-04-14", artists: [Artist(name: "Post Malone", artistId: "246dkjvS1zLTtiykXe5h60")]), artists: [Artist(name: "Post Malone", artistId: "246dkjvS1zLTtiykXe5h60")], duration_ms: 184013, name: "Chemical", popularity: 88, explicit: true))), id: "4"), Card(input: .song, media: Media(input: .song(Song( album: Album(images: [ImageResponse(url: "https://i.scdn.co/image/ab67616d0000b273f76f8deeba5370c98ad38f1c", height: 640, width: 640)], name: "Chemical", release_date: "2023-04-14", artists: [Artist(name: "Post Malone", artistId: "246dkjvS1zLTtiykXe5h60")]), artists: [Artist(name: "Post Malone", artistId: "246dkjvS1zLTtiykXe5h60")], duration_ms: 184013, name: "Chemical", popularity: 88, explicit: true))), id: "1"), Card(input: .song, media: Media(input: .song(Song(album: Album(images: [ImageResponse(url: "https://i.scdn.co/image/ab67616d0000b273f76f8deeba5370c98ad38f1c", height: 640, width: 640)], name: "Chemical", release_date: "2023-04-14", artists: [Artist(name: "Post Malone", artistId: "246dkjvS1zLTtiykXe5h60")]), artists: [Artist(name: "Post Malone", artistId: "246dkjvS1zLTtiykXe5h60")], duration_ms: 184013, name: "Chemical", popularity: 88, explicit: true))), id: "2")])
//}
