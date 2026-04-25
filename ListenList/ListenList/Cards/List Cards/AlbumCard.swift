// ListenList/ListenList/Cards/List Cards/AlbumCard.swift

import SwiftUI

struct AlbumCard: View {
    @EnvironmentObject var settingsManager: SettingsManager
    var input: Media
    var album: Album?
    var onAdd: (() -> Void)?
    var isInEditMode: Bool = false
    var onDelete: (() -> Void)?
    var isSaved: Bool

    let maxHeight: CGFloat = 120

    init(input: Media, onAdd: (() -> Void)? = nil, isInEditMode: Bool = false, onDelete: (() -> Void)? = nil, isSaved: Bool = false) {
        self.input = input
        if case let .album(album) = input.input {
            self.album = album
        }
        self.onAdd = onAdd
        self.isInEditMode = isInEditMode
        self.onDelete = onDelete
        self.isSaved = isSaved
    }

    private func artistsToStr() -> String {
        guard let artists = album?.artists, !artists.isEmpty else { return "Unknown Artist" }
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
        guard let album = album else {
            return AnyView(EmptyView())
        }

        return AnyView(
            ZStack(alignment: .leading) {
                // MARK: - Layer 1: Foreground Content
                HStack(spacing: 15) {
                    // Album Art
                    if let imageUrl = album.images.medium(), let url = URL(string: imageUrl) {
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

                    // Album Info
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(album.name)
                                .bold()
                                .lineLimit(2)

                            if album.isExplicit ?? false {
                                Image(systemName: "e.square.fill")
                            }
                        }
                        Text(artistsToStr())
                            .lineLimit(1)
                            .opacity(0.8)

                        if album.isCompleted ?? false {
                            HStack(spacing: 2) {
                                if let rating = album.rating {
                                    ForEach(1...5, id: \.self) { index in
                                        Image(systemName: index <= rating ? "star.fill" : "star")
                                            .font(.caption2)
                                            .foregroundColor(index <= rating ? .yellow : .gray)
                                    }
                                }
                            }
                        }
                    }

                    Spacer()

                    // Add Button
                    if let onAdd = onAdd {
                        if isSaved {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.black)
                        } else {
                            Button(action: onAdd) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundColor(Color.black)

                            }
                        }
                    }
                }
                .padding(.leading, 35)
                .padding(.trailing, 15)

                // MARK: - Layer 2: Overlays
                // Rotated Text
                Text(album.albumType.uppercased().isEmpty ? "ALBUM" : album.albumType.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .fixedSize()
                    .rotationEffect(.degrees(-90))
                    .frame(width: 20, height: maxHeight)
                    .padding(.leading, 8)

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
            .frame(maxWidth: 600, maxHeight: maxHeight)
            .background(
                ZStack {
                    if let imageUrl = album.images.medium(), let url = URL(string: imageUrl) {
                        CachedAsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray
                        }
                    } else {
                        Color.gray
                    }

                    RoundedRectangle(cornerRadius: 15.0)
                        .fill(.ultraThinMaterial)
                        .opacity(settingsManager.glassOpacity.opacityValue)
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
    AlbumCard(
        input: Media(
            input: .album(
                Album(
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
                )
            )
        )
    )
}
