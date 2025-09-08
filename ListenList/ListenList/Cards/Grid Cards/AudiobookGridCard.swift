// ListenList/ListenList/Cards/Grid Cards/AudiobookGridCard.swift

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

    let maxHeight: CGFloat = 270
    let maxWidth: CGFloat = 185

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
                VStack(spacing: 4) {
                    Text("AUDIOBOOK")
                        .font(.caption)
                        .fontWeight(.bold)
                        .opacity(0.8)
                        .padding(.top, 4)

                    if audiobook.images.isEmpty {
                        placeholderImage
                    } else {
                        AsyncImage(url: URL(string: audiobook.images[0].url)) { phase in
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
                        Text("Narrated by: \(narratorsToStr())")
                            .lineLimit(1)
                            .opacity(0.8)
                        Text(audiobook.publisher)
                            .lineLimit(1)
                            .opacity(0.8)
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
                    if let imageUrl = audiobook.images.first?.url, let url = URL(string: imageUrl) {
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
