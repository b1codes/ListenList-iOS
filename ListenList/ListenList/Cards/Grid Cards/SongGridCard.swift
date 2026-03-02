//
//  SongCard.swift
//  ListenList
//
//  Created by Brandon Lamer-Connolly on 10/12/24.
//

import SwiftUI

struct SongGridCard: View {
    var input: Media
    var song: Song?
    var onAdd: (() -> Void)?
    var isInEditMode: Bool = false
    var onDelete: (() -> Void)?

    init(input: Media, onAdd: (() -> Void)? = nil, isInEditMode: Bool = false, onDelete: (() -> Void)? = nil) {
        self.input = input
        if case let .song(song) = input.input {
            self.song = song
        }
        self.onAdd = onAdd
        self.isInEditMode = isInEditMode
        self.onDelete = onDelete
    }

    let maxHeight: CGFloat = 270
    let maxWidth: CGFloat = 185

    private func artistsToStr() -> String {
        guard let artists = song?.artists, !artists.isEmpty else { return "Unknown Artist" }
        return artists.map { $0.name }.joined(separator: ", ")
    }

    private var placeholderImage: some View {
        Image(systemName: "photo")
            .resizable()
            .scaledToFill()
            .frame(width: 180, height: 180)
            .cornerRadius(10.0)
    }

    var body: some View {
        guard let song = song else {
            return AnyView(EmptyView())
        }

        return AnyView(
            ZStack {
                // MARK: - Layer 1: Foreground Content
                VStack(spacing: 4) {
                    // "SONG" text
                    Text("SONG")
                        .font(.caption)
                        .fontWeight(.bold)
                        .opacity(0.8)
                        .padding(.top, 4) // Added small top padding to prevent touching the edge

                    // Album Art
                    if song.album.images.isEmpty {
                        placeholderImage
                    } else {
                        AsyncImage(url: URL(string: song.album.images[0].url)) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } else {
                                ProgressView().tint(.white)
                            }
                        }
                        .frame(width: 165, height: 165)
                        .cornerRadius(10.0)
                    }

                    Spacer()

                    // Song Info
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(song.name)
                                .bold()
                                .lineLimit(2)

                            if song.explicit {
                                Image(systemName: "e.square.fill")
                            }
                        }
                        Text(artistsToStr())
                            .lineLimit(1)
                            .opacity(0.8)

                        if let rating = song.rating, song.isCompleted ?? false {
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { index in
                                    Image(systemName: index <= rating ? "star.fill" : "star")
                                        .font(.caption2)
                                        .foregroundColor(index <= rating ? .yellow : .gray)
                                }
                            }
                        }
                    }

                    Spacer()
                    // Add Button
                    if let onAdd = onAdd {
                        Spacer()
                        Button(action: onAdd) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                        }
                    }
                }
                .padding(.horizontal, 15)
                .padding(.bottom, 4) // Removed top padding from the VStack

                // MARK: - Layer 2: Overlays
                // Edit mode overlay
                if isInEditMode {
                    ZStack {
                        Color.gray.opacity(0.6)
                        if let onDelete = onDelete {
                            Button(action: onDelete) {
                                Image(systemName: "trash.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: maxWidth, maxHeight: maxHeight)
            .background(
                ZStack {
                    if let imageUrl = song.album.images.first?.url, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                Color.gray
                            }
                        }
                    } else {
                        Color.gray
                    }

                    RoundedRectangle(cornerRadius: 15.0)
                        .foregroundColor(.gray.opacity(0.7))
                }
                .blur(radius: 4.2)
                .allowsHitTesting(false)
            )
            .cornerRadius(15.0)
            .clipped()
            .padding([.leading, .trailing], 10)
        )
    }
}

#Preview {
    SongGridCard(
        input: Media(
            input: .song(
                Song(
                    id: "1",
                    album: Album(
                        id: "1",
                        images: [
                            ImageResponse(url: "https://i.scdn.co/image/ab67616d0000b273916737a69b98e6eff6b43eaa", height: 640, width: 640)
                        ],
                        name: "Ordinary (Wedding Version)",
                        releaseDate: "2021-01-01",
                        artists: [
                            Artist(id: "1", name: "Alex Warren", artistId: "1")
                        ],
                        albumType: "single"
                    ),
                    artists: [
                        Artist(id: "1", name: "Alex Warren", artistId: "1")
                    ],
                    durationMs: 200000,
                    name: "Ordinary (Wedding Version)",
                    popularity: 100,
                    explicit: false
                )
            )
        )
    )
}
