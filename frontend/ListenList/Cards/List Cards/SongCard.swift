// ListenList/ListenList/Cards/List Cards/SongCard.swift

import SwiftUI

struct SongCard: View {
    @EnvironmentObject var settingsManager: SettingsManager
    var input: Media
    var song: Song?
    var onAdd: (() -> Void)?
    var isInEditMode: Bool = false
    var onDelete: (() -> Void)?
    var isSaved: Bool

    init(input: Media, onAdd: (() -> Void)? = nil, isInEditMode: Bool = false, onDelete: (() -> Void)? = nil, isSaved: Bool = false) {
        self.input = input
        if case let .song(song) = input.input {
            self.song = song
        }
        self.onAdd = onAdd
        self.isInEditMode = isInEditMode
        self.onDelete = onDelete
        self.isSaved = isSaved
    }

    // Floor, not a cap: rows must be able to grow past this at larger
    // Dynamic Type sizes rather than clip title/artist text.
    let minHeight: CGFloat = 120

    private func artistsToStr() -> String {
        guard let artists = song?.artists, !artists.isEmpty else { return "Unknown Artist" }
        return artists.map { $0.name }.joined(separator: ", ")
    }

    private var placeholderImage: some View {
        Image(systemName: "photo")
            .resizable()
            .scaledToFill()
            .frame(width: 90, height: 90)
            .cornerRadius(10.0)
    }

    var body: some View {
        if let song = song {
            ZStack(alignment: .leading) {
                // MARK: - Layer 1: Foreground Content
                HStack(spacing: 15) {
                    // Album Art
                    if let imageUrl = song.album.images.medium(), let url = URL(string: imageUrl) {
                        CachedAsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            ProgressView().tint(.white)
                        }
                        .frame(width: 90, height: 90)
                        .cornerRadius(10.0)
                    } else {
                        placeholderImage
                    }

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

                        if song.isCompleted ?? false {
                            HStack(spacing: 2) {
                                if let rating = song.rating {
                                    ForEach(1...5, id: \.self) { index in
                                        Image(systemName: index <= rating ? "star.fill" : "star")
                                            .font(.caption2)
                                            .foregroundColor(index <= rating ? .yellow : .gray)
                                    }
                                }
                            }
                        }
                    }
                    .foregroundColor(.white)
                    .cardTextShadow()

                    Spacer()

                    // Add Button
                    if let onAdd = onAdd {
                        if isSaved {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.accentColor)
                                .frame(minWidth: 44, minHeight: 44)
                                .accessibilityLabel("Added to ListenList")
                        } else {
                            Button(action: onAdd) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.accentColor)
                                    .frame(minWidth: 44, minHeight: 44)
                                    .contentShape(Rectangle())
                            }
                            .accessibilityLabel("Add to ListenList")
                        }
                    }
                }
                .padding(.leading, 35)
                .padding(.trailing, 15)

                // MARK: - Layer 2: Overlays
                // Rotated "SONG" text
                Text("SONG")
                    .font(.caption)
                    .fontWeight(.bold)
                    .fixedSize()
                    .rotationEffect(.degrees(-90))
                    .frame(width: 20)
                    .padding(.leading, 8)
                    .foregroundColor(.white)
                    .cardTextShadow()
                // Edit mode overlay
                if isInEditMode {
                    EditModeOverlay(onDelete: onDelete)
                }
            }
            .frame(maxWidth: 600, minHeight: minHeight)
            .cardGlassBackground(imageUrl: song.album.images.medium(), glassOpacity: settingsManager.glassOpacity.opacityValue)
            .padding([.leading, .trailing], 10)
        } else {
            EmptyView()
        }
    }
}

#Preview {
    SongCard(
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
