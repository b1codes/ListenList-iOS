//
//  AudiobookGridCard.swift
//  ListenList
//
//  Created by Brandon Lamer-Connolly on 10/12/24.
//

import SwiftUI

struct AudiobookGridCard: View {
    var input: Media
    var audiobook: Audiobook?
    var onAdd: (() -> Void)?
    var isInEditMode: Bool = false
    var onDelete: (() -> Void)?

    init(input: Media, onAdd: (() -> Void)? = nil, isInEditMode: Bool = false, onDelete: (() -> Void)? = nil) {
        self.input = input
        if case let .audiobook(audiobook) = input.input {
            self.audiobook = audiobook
        }
        self.onAdd = onAdd
        self.isInEditMode = isInEditMode
        self.onDelete = onDelete
    }

    private var currentMaxHeight: CGFloat {
        (audiobook?.isCompleted ?? false) ? 290 : 270
    }
    
    private var topPadding: CGFloat {
        (audiobook?.isCompleted ?? false) ? 6 : 18
    }

    private func authorsToStr() -> String {
        guard let authors = audiobook?.authors, !authors.isEmpty else { return "Unknown Author" }
        return authors.map { $0.name }.joined(separator: ", ")
    }

    private func narratorsToStr() -> String {
        guard let narrators = audiobook?.narrators, !narrators.isEmpty else { return "Unknown Narrator" }
        return narrators.map { $0.name }.joined(separator: ", ")
    }

    private var placeholderImage: some View {
        Image(systemName: "book.fill")
            .resizable()
            .scaledToFill()
            .frame(width: 90, height: 90)
            .cornerRadius(10.0)
    }

    var body: some View {
        guard let audiobook = audiobook else {
            return AnyView(EmptyView())
        }

        return AnyView(
            ZStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Spacer()
                        Text("AUDIOBOOK")
                            .font(.caption)
                            .fontWeight(.bold)
                            .opacity(0.8)
                        Spacer()
                    }
                    .padding(.top, topPadding)

                    // Audiobook Art
                    HStack {
                        Spacer()
                        if let imageUrl = audiobook.images.medium(), let url = URL(string: imageUrl) {
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
                            Text(audiobook.name)
                                .bold()
                                .lineLimit(2)

                            if audiobook.explicit {
                                Image(systemName: "e.square.fill")
                            }
                        }
                        Text(authorsToStr())
                            .lineLimit(1)
                            .opacity(0.8)

                        HStack(spacing: 2) {
                            if let rating = audiobook.rating, audiobook.isCompleted ?? false {
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
                    }.padding(.horizontal, 6)
                    Spacer()

                    if let onAdd = onAdd {
                        HStack {
                            Spacer()
                            Button(action: onAdd) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                            }
                            Spacer()
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
            .frame(maxWidth: 185, maxHeight: currentMaxHeight)
            .background(
                ZStack {
                    if let imageUrl = audiobook.images.medium(), let url = URL(string: imageUrl) {
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
    AudiobookGridCard(
        input: Media(
            input: .audiobook(
                Audiobook(
                    id: "1",
                    name: "Dune",
                    authors: [Author(name: "Frank Herbert")],
                    images: [
                        ImageResponse(url: "https://i.scdn.co/image/ab6766330000ec915d312896a29731633d671520", height: 640, width: 640)
                    ],
                    explicit: false,
                    description: "The story of Paul Atreides, a young nobleman who is thrust into a galactic power struggle on the desert planet of Arrakis.",
                    edition: "Unabridged",
                    narrators: [Narrator(name: "Scott Brick")],
                    publisher: "Macmillan Audio",
                    totalChapters: 50
                )
            )
        )
    )
}
