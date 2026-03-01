// ListenList/ListenList/Cards/Grid Cards/PodcastGridCard.swift

import SwiftUI

struct PodcastGridCard: View {
    var input: Media
    var podcast: Podcast?
    var onAdd: (() -> Void)?
    var isInEditMode: Bool = false
    var onDelete: (() -> Void)?

    let maxHeight: CGFloat = 270
    let maxWidth: CGFloat = 185

    init(input: Media, onAdd: (() -> Void)? = nil, isInEditMode: Bool = false, onDelete: (() -> Void)? = nil) {
        self.input = input
        if case let .podcast(podcast) = input.input {
            self.podcast = podcast
        }
        self.onAdd = onAdd
        self.isInEditMode = isInEditMode
        self.onDelete = onDelete
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
            ZStack {
                VStack(spacing: 4) {
                    Text("PODCAST")
                        .font(.caption)
                        .fontWeight(.bold)
                        .opacity(0.8)
                        .padding(.top, 4)

                    if podcast.images.isEmpty {
                        placeholderImage
                    } else {
                        AsyncImage(url: URL(string: podcast.images[0].url)) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } else {
                                ProgressView().tint(.white)
                            }
                        }
                        .frame(width: 165, height: 165)
                        .cornerRadius(10.0)
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
                            .opacity(0.8)
                        
                        if let rating = podcast.rating, podcast.isCompleted ?? false {
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { index in
                                    Image(systemName: index <= rating ? "star.fill" : "star")
                                        .font(.caption2)
                                        .foregroundColor(index <= rating ? .yellow : .gray)
                                }
                            }
                        }
                    }
                    Spacer()

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
                    if let imageUrl = podcast.images.first?.url, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                Color.gray
                            }
                        }
                    } else {
                        Color.gray
                    }
                    
                    RoundedRectangle(cornerRadius: 15.0)
                        .foregroundColor(.gray.opacity(0.7))
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
                    total_episodes: 1500
                )
            )
        )
    )
}
