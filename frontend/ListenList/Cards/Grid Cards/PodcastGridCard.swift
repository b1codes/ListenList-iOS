//
//  PodcastGridCard.swift
//  ListenList
//
//  Created by Brandon Lamer-Connolly on 10/12/24.
//

import SwiftUI

struct PodcastGridCard: View {
    @EnvironmentObject var settingsManager: SettingsManager
    var input: Media
    var podcast: Podcast?
    var onAdd: (() -> Void)?
    var isInEditMode: Bool = false
    var onDelete: (() -> Void)?

    init(input: Media, onAdd: (() -> Void)? = nil, isInEditMode: Bool = false, onDelete: (() -> Void)? = nil) {
        self.input = input
        if case let .podcast(podcast) = input.input {
            self.podcast = podcast
        }
        self.onAdd = onAdd
        self.isInEditMode = isInEditMode
        self.onDelete = onDelete
    }

    // Floor, not a cap: cards must be able to grow past this at larger
    // Dynamic Type sizes rather than clip title/artist text.
    private var minCardHeight: CGFloat {
        (podcast?.isCompleted ?? false) ? 290 : 270
    }
    
    private var topPadding: CGFloat {
        (podcast?.isCompleted ?? false) ? 6 : 18
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
            ZStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Spacer()
                        Text("PODCAST")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.8))
                            .cardTextShadow()
                        Spacer()
                    }
                    .padding(.top, topPadding)

                    HStack {
                        Spacer()
                        if let imageUrl = podcast.images.medium(), let url = URL(string: imageUrl) {
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
                    .padding(.horizontal, 6)
                    .foregroundColor(.white)
                    .cardTextShadow()
                    Spacer()

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

                if isInEditMode {
                    EditModeOverlay(onDelete: onDelete)
                }
            }
            .frame(maxWidth: 185, minHeight: minCardHeight)
            .cardGlassBackground(imageUrl: podcast.images.medium(), glassOpacity: settingsManager.glassOpacity.opacityValue)
            .padding([.leading, .trailing], 10)
        } else {
            EmptyView()
        }
    }
}

#Preview {
    PodcastGridCard(
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
