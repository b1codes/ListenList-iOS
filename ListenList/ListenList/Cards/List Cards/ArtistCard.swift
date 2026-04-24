// ListenList/ListenList/Cards/List Cards/ArtistCard.swift

import SwiftUI

struct ArtistCard: View {
    var input: Media
    var artist: Artist?
    var onAdd: (() -> Void)?
    var isInEditMode: Bool = false
    var onDelete: (() -> Void)?
    var isSaved: Bool

    let maxHeight: CGFloat = 120

    init(input: Media, onAdd: (() -> Void)? = nil, isInEditMode: Bool = false, onDelete: (() -> Void)? = nil, isSaved: Bool = false) {
        self.input = input
        if case let .artist(artist) = input.input {
            self.artist = artist
        }
        self.onAdd = onAdd
        self.isInEditMode = isInEditMode
        self.onDelete = onDelete
        self.isSaved = isSaved
    }

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
            ZStack(alignment: .leading) {
                // MARK: - Layer 1: Foreground Content
                HStack(spacing: 15) {
                    // Artist Art
                    if let imageUrl = artist.images?.medium(), let url = URL(string: imageUrl) {
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

                    // Artist Info
                    VStack(alignment: .leading, spacing: 5) {
                        Text(artist.name)
                            .bold()
                            .lineLimit(2)
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
                // Rotated "ARTIST" text
                Text("ARTIST")
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
    ArtistCard(
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
