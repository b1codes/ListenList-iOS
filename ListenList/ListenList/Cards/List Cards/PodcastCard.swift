// ListenList/ListenList/Cards/List Cards/PodcastCard.swift

import SwiftUI

struct PodcastCard: View {
    var input: Media
    var podcast: Podcast?
    var onAdd: (() -> Void)?
    var isInEditMode: Bool = false
    var onDelete: (() -> Void)?
    var isSaved: Bool

    let maxHeight: CGFloat = 120

    init(input: Media, onAdd: (() -> Void)? = nil, isInEditMode: Bool = false, onDelete: (() -> Void)? = nil, isSaved: Bool = false) {
        self.input = input
        if case let .podcast(podcast) = input.input {
            self.podcast = podcast
        }
        self.onAdd = onAdd
        self.isInEditMode = isInEditMode
        self.onDelete = onDelete
        self.isSaved = isSaved
    }

    private var placeholderImage: some View {
        Image(systemName: "mic.fill")
            .resizable()
            .scaledToFill()
            .frame(width: 90, height: 90)
            .cornerRadius(10.0)
    }

    var body: some View {
        guard let podcast = podcast else {
            return AnyView(EmptyView())
        }

        return AnyView(
            ZStack(alignment: .leading) {
                // MARK: - Layer 1: Foreground Content
                HStack(spacing: 15) {
                    // Podcast Art
                    if let imageUrl = podcast.images.medium(), let url = URL(string: imageUrl) {
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

                    // Podcast Info
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(podcast.name)
                                .bold()
                                .lineLimit(2)

                            if podcast.explicit {
                                Image(systemName: "e.square.fill")
                            }
                        }
                        Text(podcast.publisher)
                            .lineLimit(1)
                            .opacity(0.8)

                        HStack(spacing: 2) {
                            if let rating = podcast.rating, podcast.isCompleted ?? false {
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
                // Rotated "PODCAST" text
                Text("PODCAST")
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
                    if let imageUrl = podcast.images.medium(), let url = URL(string: imageUrl) {
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
    PodcastCard(
        input: Media(
            input: .podcast(
                Podcast(
                    id: "1",
                    name: "The Daily",
                    publisher: "The New York Times",
                    images: [
                        ImageResponse(url: "https://i.scdn.co/image/ab6765630000ba8a3f5a34a9b6c81eceaf92c536", height: 640, width: 640)
                    ],
                    explicit: false,
                    description: "This is what the news should sound like. The biggest stories of our time, told by the best journalists in the world. Hosted by Michael Barbaro and Sabrina Tavernise. Twenty minutes a day, five days a week, ready by 6 a.m.",
                    totalEpisodes: 1500
                )
            )
        )
    )
}
