//
//  AlbumGridCard.swift
//  ListenList
//
//  Created by Brandon Lamer-Connolly on 9/7/25.
//

//
//  AlbumGridCard.swift
//  ListenList
//
//  Created by Brandon Lamer-Connolly on 10/12/24.
//

import SwiftUI

struct AlbumGridCard: View {
    @EnvironmentObject var settingsManager: SettingsManager
    var input: Media
    var album: Album?
    var onAdd: (() -> Void)?
    var isInEditMode: Bool = false
    var onDelete: (() -> Void)?

    init(input: Media, onAdd: (() -> Void)? = nil, isInEditMode: Bool = false, onDelete: (() -> Void)? = nil) {
        self.input = input
        if case let .album(album) = input.input {
            self.album = album
        }
        self.onAdd = onAdd
        self.isInEditMode = isInEditMode
        self.onDelete = onDelete
    }

    // Floor, not a cap: cards must be able to grow past this at larger
    // Dynamic Type sizes rather than clip title/artist text.
    private var minCardHeight: CGFloat {
        (album?.isCompleted ?? false) ? 290 : 270
    }
    
    private var topPadding: CGFloat {
        (album?.isCompleted ?? false) ? 6 : 18
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
        if let album = album {
            ZStack {
                // MARK: - Layer 1: Foreground Content
                VStack(alignment: .leading, spacing: 4) {
                    // "ALBUM" text
                    HStack {
                        Spacer()
                        Text(album.albumType.uppercased())
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
                        if let imageUrl = album.images.medium(), let url = URL(string: imageUrl) {
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
                            .foregroundColor(.white.opacity(0.8))

                        HStack(spacing: 2) {
                            if let rating = album.rating, album.isCompleted ?? false {
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
            .cardGlassBackground(imageUrl: album.images.medium(), glassOpacity: settingsManager.glassOpacity.opacityValue)
            .padding([.leading, .trailing], 10)
        } else {
            EmptyView()
        }
    }
}

#Preview {
    AlbumGridCard(
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
                    albumType: "single",
                    rating: 4,
                    comment: "Loved the production and vocals!",
                    isCompleted: true
                )
            )
        )
    )
}

#Preview {
    AlbumGridCard(
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
