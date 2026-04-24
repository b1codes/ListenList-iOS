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

    let maxHeight: CGFloat = 270
    let maxWidth: CGFloat = 185

    private var placeholderImage: some View {
        Image(systemName: "music.microphone")
            .resizable()
            .scaledToFill()
            .frame(width: 90, height: 90)
            .cornerRadius(10.0)
    }

    var body: some View {
        guard let artist = artist else {
            return AnyView(EmptyView())
        }

        return AnyView(
            ZStack {
                // MARK: - Layer 1: Foreground Content
                VStack(spacing: 4) {
                    // "ARTIST" text
                    Text("ARTIST")
                        .font(.caption)
                        .fontWeight(.bold)
                        .opacity(0.8)
                        .padding(.top, 8)
                    // Artist Art
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

                    // Artist Info
                    VStack(alignment: .leading, spacing: 5) {
                        Text(artist.name)
                            .bold()
                            .lineLimit(2)
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
                .padding(.bottom, 4)

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
                    if let imageUrl = artist.images?.medium(), let url = URL(string: imageUrl) {
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
                    artistId: "1"
                )
            )
        )
    )
}
