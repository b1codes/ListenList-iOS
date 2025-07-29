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
            ZStack {
                // Main Card Content
                ZStack {
                    HStack(alignment: .center) {
                        if song.album.images.isEmpty {
                            placeholderImage
                                .blur(radius: 4.2)
                                .frame(maxHeight: maxHeight)
                        } else {
                            GeometryReader { geo in
                                AsyncImage(url: URL(string: song.album.images[0].url)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: geo.size.width, height: geo.size.height)
                                    case .success(let image): image.resizable()
                                            .frame(width: geo.size.width, height: geo.size.height)
                                            .clipped()
                                            .cornerRadius(15)
                                    case .failure: placeholderImage
                                            .frame(width: geo.size.width, height: geo.size.height)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }
                            .frame(height: maxHeight)
                            .blur(radius: 4.2)
                        }
                    }
                    .cornerRadius(15.0)
                    
                    RoundedRectangle(cornerRadius: 15.0)
                        .foregroundColor(Color.gray.opacity(0.7))
                        .frame(maxHeight: maxHeight)
                    
                    HStack(alignment: .center) {
                        if song.album.images.isEmpty {
                            placeholderImage
                        } else {
                            GeometryReader { proxy in
                                AsyncImage(url: URL(string: song.album.images[0].url)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: proxy.size.width, height: proxy.size.height)
                                    case .success(let image):
                                        image.resizable()
                                            .frame(width: proxy.size.width, height: proxy.size.height)
                                            .clipped()
                                            .cornerRadius(15)
                                    case .failure:
                                        placeholderImage
                                            .frame(width: proxy.size.width, height: proxy.size.height)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }
                            .frame(width: 90, height: 90)
                            .padding()
                        }
                        
                        VStack(alignment: .leading) {
                            HStack {
                                Text(song.name)
                                    .bold()
                                    .lineLimit(1)
                                    .frame(maxWidth: 220, alignment: .leading)
                                    .truncationMode(.tail)
                                if song.explicit {
                                    Image(systemName: "e.square.fill")
                                }
                            }
                            Text(artistsToStr())
                                .lineLimit(1)
                                .frame(maxWidth: 220, alignment: .leading)
                                .truncationMode(.tail)
                        }
                        .padding(.trailing)
                        
                        Spacer()
                        
                        if let onAdd = onAdd {
                            Button(action: onAdd) {
                                Image(systemName: "plus.circle.fill")
                            }
                            .padding(.trailing)
                        }
                    }
                }
                
                // Overlay for Edit Mode
                if isInEditMode {
                    Color.black.opacity(0.5)
                        .cornerRadius(15.0)
                    
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
