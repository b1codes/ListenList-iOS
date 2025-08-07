//
//  SongCard.swift
//  ListenList
//
//  Created by Brandon Lamer-Connolly on 10/12/24.
//

import SwiftUI

struct SongCard: View {
    var input: Media
    var song: Song?
    var onAdd: (() -> Void)?
    var isInEditMode: Bool = false
    var onDelete: (() -> Void)?

    init(input: Media, onAdd: (() -> Void)? = nil, isInEditMode: Bool = false, onDelete: (() -> Void)? = nil) {
        self.input = input
        if case let .song(song) = input.input {
            self.song = song
        }
        self.onAdd = onAdd
        self.isInEditMode = isInEditMode
        self.onDelete = onDelete
    }

    let maxHeight: CGFloat = 120

    private func artistsToStr() -> String {
        guard let artists = song?.artists, !artists.isEmpty else { return "Unknown Artist" }
        return artists.map { $0.name }.joined(separator: ", ")
    }

    private var placeholderImage: some View {
        Image(systemName: "photo")
            .resizable()
            .scaledToFill()
            .cornerRadius(15.0)
            .frame(maxWidth: 90, maxHeight: 90)
            .padding(.all)
    }

    var body: some View {
        guard let song = song else {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            ZStack(alignment: .leading) { // Set alignment for the whole ZStack
                // Layer 1: Background
                ZStack {
                    if !song.album.images.isEmpty {
                        AsyncImage(url: URL(string: song.album.images[0].url)) { phase in
                            if let image = phase.image {
                                image.resizable()
                                    //.aspectRatio(contentMode: .fill)
                                    .blur(radius: 4.2)
                            } else { Color.clear }
                        }
                    }
                    RoundedRectangle(cornerRadius: 15.0)
                        .foregroundColor(.gray.opacity(0.7))
                }
                .frame(maxHeight: maxHeight)
                .cornerRadius(15.0)
                .clipped()

                // Layer 2: Main Content
                HStack(spacing: 15) {
                    if song.album.images.isEmpty {
                        placeholderImage
                    } else {
                        AsyncImage(url: URL(string: song.album.images[0].url)) { phase in
                            if let image = phase.image {
                                image.resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(10.0)
                            } else { ProgressView() }
                        }
                        .frame(width: 90, height: 90)
                    }
                    
                    VStack(alignment: .leading) {
                        HStack{
                            Text(song.name).bold()
                                .lineLimit(2)
                            if song.explicit {
                                Image(systemName: "e.square.fill")
                            }
                        }
                        Text(artistsToStr()).lineLimit(1)
                    }
                    
                    Spacer()
                    
                    if let onAdd = onAdd {
                        Button(action: onAdd) {
                            Image(systemName: "plus.circle.fill").font(.title)
                        }
                    }
                }
                .padding(.leading, 35)
                .padding(.trailing, 15)

                // Layer 3: Rotated Text - THE FIX
                Text("SONG")
                    .font(.caption)
                    .fontWeight(.bold)
                    .fixedSize() // Allow the text to have its natural size
                    .rotationEffect(.degrees(-90))
                    .frame(width: 20, height: maxHeight) // Give it a minimal frame and center it
                    .padding(.leading, 8)
                
                // Layer 4: Edit Mode Overlay
                if isInEditMode {
                    Color.black.opacity(0.5).cornerRadius(15.0)
                    if let onDelete = onDelete {
                        Button(action: onDelete) {
                            Image(systemName: "trash.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .frame(maxWidth: 600, maxHeight: maxHeight)
            .padding([.leading, .trailing], 10)
        )
    }
}
