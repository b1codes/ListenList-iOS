// ListenList/ListenList/Cards/List Cards/AudiobookCard.swift

import SwiftUI

struct AudiobookCard: View {
    var input: Media
    var audiobook: Audiobook?
    var onAdd: (() -> Void)?
    var isInEditMode: Bool = false
    var onDelete: (() -> Void)?
    var isSaved: Bool

    let maxHeight: CGFloat = 120

    init(input: Media, onAdd: (() -> Void)? = nil, isInEditMode: Bool = false, onDelete: (() -> Void)? = nil, isSaved: Bool = false) {
        self.input = input
        if case let .audiobook(audiobook) = input.input {
            self.audiobook = audiobook
        }
        self.onAdd = onAdd
        self.isInEditMode = isInEditMode
        self.onDelete = onDelete
        self.isSaved = isSaved
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
            ZStack(alignment: .leading) {
                HStack(spacing: 15) {
                    // Audiobook Art
                    if let imageUrl = audiobook.images.medium(), let url = URL(string: imageUrl) {
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
                    }

                    Spacer()

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

                Text("AUDIOBOOK")
                    .font(.caption)
                    .fontWeight(.bold)
                    .fixedSize()
                    .rotationEffect(.degrees(-90))
                    .frame(width: 20, height: maxHeight)
                    .padding(.leading, 8)

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
    AudiobookCard(
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
