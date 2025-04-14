//
//  SongCard.swift
//  ListenList
//
//  Created by Brandon Lamer-Connolly on 10/12/24.
//

import SwiftUI

struct SongCard: View {
    var input: Media
    var song: Song?
    
    init(input: Media) {
        self.input = input
        if case let .song(song) = input.input {
            self.song = song
        }
    }

    let maxHeight: CGFloat = 120

    private func artistsToStr() -> String {
        guard let artists = song?.artists, !artists.isEmpty else { return "Unknown Artist" }
        return artists.map { $0.name }.joined(separator: ", ")
    }

    private var placeholderImage: some View {
        Image(systemName: "photo")
            .resizable()
            .scaledToFill()
            .cornerRadius(15.0)
            .frame(maxWidth: 90, maxHeight: 90)
            .padding(.all)
    }

    var body: some View {
        // If there's no song, return an empty view.
        guard let song = song else {
            return AnyView(EmptyView())
        }
        
        // Use if/else to return different views based on URL creation.
        if URL(string: song.album.images[0].url) != nil {
            return AnyView(
                ZStack {
                    HStack(alignment: .center) {
                        if song.album.images.isEmpty {
                            placeholderImage
                                .blur(radius: 4.2)
                                .frame(maxHeight: maxHeight)
                        } else {
                            GeometryReader { geo in
                                AsyncImage(url: URL(string: song.album.images[0].url)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: geo.size.width, height: geo.size.height)
                                    case .success(let image): image.resizable()
                                            //.scaledToFill()
                                            .frame(width: geo.size.width, height: geo.size.height)
                                            .clipped()
                                            .cornerRadius(15)
                                    case .failure: placeholderImage
                                            .frame(width: geo.size.width, height: geo.size.height)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }
                            .frame(height: maxHeight)
                            .blur(radius: 4.2)
                        }
                    }
                    .cornerRadius(15.0)
                    
                    HStack {
                        RoundedRectangle(cornerRadius: 15.0)
                            .foregroundColor(Color.gray.opacity(0.7))
                            .frame(maxHeight: maxHeight)
                    }
                    .cornerRadius(15.0)
                    
                    HStack(alignment: .center) {
                        if song.album.images.isEmpty {
                            placeholderImage
                        } else {
                            GeometryReader { proxy in
                                AsyncImage(url: URL(string: song.album.images[0].url)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: proxy.size.width, height: proxy.size.height)
                                    case .success(let image):
                                        image.resizable()
                                            //.scaledToFill()
                                            .frame(width: proxy.size.width, height: proxy.size.height)
                                            .clipped()
                                            .cornerRadius(15)
                                            .overlay(EmptyView().id(UUID()))
                                    case .failure:
                                        placeholderImage
                                            .frame(width: proxy.size.width, height: proxy.size.height)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }
                            .frame(width: 90, height: 90)
                            .padding()
                        }
                        
                        VStack(alignment: .leading) {
                            HStack {
                                Text(song.name)
                                    .bold()
                                    .lineLimit(1)
                                    .frame(maxWidth: 220, alignment: .leading)
                                    .truncationMode(.tail)
                                if song.explicit {
                                    Image(systemName: "e.square.fill")
                                }
                            }
                            Text(artistsToStr())
                                .lineLimit(1)
                                .frame(maxWidth: 220, alignment: .leading)
                                .truncationMode(.tail)
                        }
                        .padding(.trailing)
                        
                        Spacer()
                    }
                }
                .frame(maxWidth: 600, maxHeight: maxHeight)
                .padding([.leading, .trailing], 10)
            )
        } else {
            // If URL init fails, return an alternative view.
            return AnyView(
                ZStack {
                    placeholderImage
                        .blur(radius: 4.2)
                        .frame(maxHeight: maxHeight)
                    RoundedRectangle(cornerRadius: 15.0)
                        .foregroundColor(Color.gray.opacity(0.7))
                    HStack {
                        placeholderImage
                        VStack(alignment: .leading) {
                            HStack {
                                Text(song.name)
                                    .bold()
                                    .lineLimit(1)
                                    .frame(maxWidth: 220, alignment: .leading)
                                    .truncationMode(.tail)
                                if song.explicit {
                                    Image(systemName: "e.square.fill")
                                }
                            }
                            Text(artistsToStr())
                                .lineLimit(1)
                                .frame(maxWidth: 220, alignment: .leading)
                                .truncationMode(.tail)
                        }
                        .padding(.trailing)
                        Spacer()
                    }
                }
                .frame(maxWidth: 600, maxHeight: maxHeight)
                .padding([.leading, .trailing], 10)
            )
        }
    }
}

#Preview {
    let mockSong = Song(
        id: "001",
        album: Album(
            id: "012", images: [ImageResponse(url: "https://i.scdn.co/image/ab67616d0000b273f76f8deeba5370c98ad38f1c", height: 640, width: 640)],
            name: "Chemical",
            release_date: "2023-04-14",
            artists: [Artist(id: "011", name: "Post Malone", artistId: "246dkjvS1zLTtiykXe5h60")]
        ),
        artists: [Artist(id: "0112", name: "Post Malone", artistId: "246dkjvS1zLTtiykXe5h60")],
        duration_ms: 184013,
        name: "Chemical",
        popularity: 88,
        explicit: true
    )
    SongCard(input: Media(input: .song(mockSong)))
}
