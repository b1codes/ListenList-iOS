//
//  ArtistGridCard.swift
//  ListenList
//
//  Created by Brandon Lamer-Connolly on 9/7/25.
//

//
//  ArtistGridCard.swift
//  ListenList
//
//  Created by Brandon Lamer-Connolly on 10/12/24.
//

import SwiftUI

struct ArtistGridCard: View {
    @EnvironmentObject var settingsManager: SettingsManager
    var input: Media
    var artist: Artist?
    var onAdd: (() -> Void)?
    var isInEditMode: Bool = false
    var onDelete: (() -> Void)?

    init(input: Media, onAdd: (() -> Void)? = nil, isInEditMode: Bool = false, onDelete: (() -> Void)? = nil) {
        self.input = input
        if case let .artist(artist) = input.input {
            self.artist = artist
        }
        self.onAdd = onAdd
        self.isInEditMode = isInEditMode
        self.onDelete = onDelete
    }

    // Floor, not a cap: cards must be able to grow past this at larger
    // Dynamic Type sizes rather than clip title/artist text.
    private var minCardHeight: CGFloat {
        (artist?.isCompleted ?? false) ? 290 : 270
    }
    
    private var topPadding: CGFloat {
        (artist?.isCompleted ?? false) ? 6 : 18
    }

    private var placeholderImage: some View {
        Image(systemName: "music.microphone")
            .resizable()
            .scaledToFill()
            .frame(width: 90, height: 90)
            .cornerRadius(10.0)
    }

    var body: some View {
        if let artist = artist {
            ZStack {
                // MARK: - Layer 1: Foreground Content
                VStack(alignment: .leading, spacing: 4) {
                    // \"ARTIST\" text
                    HStack {
                        Spacer()
                        Text("ARTIST")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.8))
                            .cardTextShadow()
                        Spacer()
                    }
                    .padding(.top, topPadding)
                    // Artist Art
                    HStack {
                        Spacer()
                        if let imageUrl = artist.images?.medium(), let url = URL(string: imageUrl) {
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

                    // Artist Info
                    VStack(alignment: .leading, spacing: 5) {
                        Text(artist.name)
                            .bold()
                            .lineLimit(1)
                            .padding(.vertical, artist.isCompleted ?? false ? 0 : 12)
                        HStack(spacing: 2) {
                            if let rating = artist.rating, artist.isCompleted ?? false {
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
            .cardGlassBackground(imageUrl: artist.images?.medium(), glassOpacity: settingsManager.glassOpacity.opacityValue)
            .padding([.leading, .trailing], 10)
        } else {
            EmptyView()
        }
    }
}

#Preview {
    ArtistGridCard(
        input: Media(
            input: .artist(
                Artist(
                    id: "1",
                    images: [
                        ImageResponse(url: "https://i.scdn.co/image/ab6761610000e5eb5f00bb6dd7a7008d14156630", height: 640, width: 640)
                    ],
                    name: "Kid Cudi",
                    artistId: "1"
                )
            )
        )
    )
}

#Preview {
    ArtistGridCard(
        input: Media(
            input: .artist(
                Artist(
                    id: "1",
                    images: [
                        ImageResponse(url: "https://i.scdn.co/image/ab6761610000e5eb5f00bb6dd7a7008d14156630", height: 640, width: 640)
                    ],
                    name: "Kid Cudi",
                    artistId: "1",
                    rating: 3,
                    isCompleted: true
                )
            )
        )
    )
}
