// ListenList/ListenList/Cards/List Cards/PodcastCard.swift

import SwiftUI

struct PodcastCard: View {
    @EnvironmentObject var settingsManager: SettingsManager
    var input: Media
    var podcast: Podcast?
    var onAdd: (() -> Void)?
    var isInEditMode: Bool = false
    var onDelete: (() -> Void)?
    var isSaved: Bool

    // Floor, not a cap: rows must be able to grow past this at larger
    // Dynamic Type sizes rather than clip title/artist text.
    let minHeight: CGFloat = 120

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
        if let podcast = podcast {
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
                            .foregroundColor(.white.opacity(0.8))

                        if podcast.isCompleted ?? false {
                            HStack(spacing: 2) {
                                if let rating = podcast.rating {
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
                // Rotated "PODCAST" text
                Text("PODCAST")
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
            .cardGlassBackground(imageUrl: podcast.images.medium(), glassOpacity: settingsManager.glassOpacity.opacityValue)
            .padding([.leading, .trailing], 10)
        } else {
            EmptyView()
        }
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
