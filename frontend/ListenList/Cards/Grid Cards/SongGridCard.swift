//
//  SongCard.swift
//  ListenList
//
//  Created by Brandon Lamer-Connolly on 10/12/24.
//

import SwiftUI

struct SongGridCard: View {
    @EnvironmentObject var settingsManager: SettingsManager
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

    // Floor, not a cap: cards must be able to grow past this at larger
    // Dynamic Type sizes rather than clip title/artist text.
    private var minCardHeight: CGFloat {
        (song?.isCompleted ?? false) ? 290 : 270
    }
    
    private var topPadding: CGFloat {
        (song?.isCompleted ?? false) ? 6 : 18
    }

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
        if let song = song {
            ZStack {
                // MARK: - Layer 1: Foreground Content
                VStack(alignment: .leading, spacing: 4) {
                    // \"SONG\" text
                    HStack {
                        Spacer()
                        Text("SONG")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.8))
                            .cardTextShadow()
                        Spacer()
                    }
                    .padding(.top, topPadding)

                    // Album Art
                    HStack {
                        Spacer()
                        if let imageUrl = song.album.images.medium(), let url = URL(string: imageUrl) {
                            CachedAsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } placeholder: {
                                ProgressView().tint(.white)
                            }
                            .frame(width: 165, height: 165)
                            .cornerRadius(10.0)
                        } else {
                            placeholderImage
                        }
                        Spacer()
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
                            .foregroundColor(.white.opacity(0.8))

                        HStack(spacing: 2) {
                            if let rating = song.rating, song.isCompleted ?? false {
                                ForEach(1...5, id: \.self) { index in
                                    Image(systemName: index <= rating ? "star.fill" : "star")
                                        .font(.caption2)
                                        .foregroundColor(index <= rating ? .yellow : .gray)
                                }
                            } else {
                                Image(systemName: "star")
                                    .font(.caption2)
                                    .foregroundColor(.clear)
                            }
                        }
                    }
                    .padding(.horizontal, 6)
                    .foregroundColor(.white)
                    .cardTextShadow()

                    Spacer()
                    // Add Button
                    if let onAdd = onAdd {
                        HStack {
                            Spacer()
                            Button(action: onAdd) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.accentColor)
                                    .frame(minWidth: 44, minHeight: 44)
                                    .contentShape(Rectangle())
                            }
                            .accessibilityLabel("Add to ListenList")
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 15)
                .padding(.bottom, 4)

                // MARK: - Layer 2: Overlays
                // Edit mode overlay
                if isInEditMode {
                    EditModeOverlay(onDelete: onDelete)
                }
            }
            .frame(maxWidth: 185, minHeight: minCardHeight)
            .cardGlassBackground(imageUrl: song.album.images.medium(), glassOpacity: settingsManager.glassOpacity.opacityValue)
            .padding([.leading, .trailing], 10)
        } else {
            EmptyView()
        }
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
