//
//  ArtistCard.swift
//  ListenList
//
//  Created by Brandon Lamer-Connolly on 10/12/24.
//

import SwiftUI

struct ArtistCard: View {
    var input: Media
    var artist: Artist?
    var onAdd: (() -> Void)?
    var isInEditMode: Bool = false
    var onDelete: (() -> Void)?

    let maxHeight: CGFloat = 120
    
    init(input: Media, onAdd: (() -> Void)? = nil, isInEditMode: Bool = false, onDelete: (() -> Void)? = nil) {
        self.input = input
        if case let .artist(artist) = input.input {
            self.artist = artist
        }
        self.onAdd = onAdd
        self.isInEditMode = isInEditMode
        self.onDelete = onDelete
    }
    
    private var placeholderImage: some View {
        Image(systemName: "music.microphone")
            .resizable()
            .scaledToFit()
            .cornerRadius(15.0)
            .frame(maxWidth: 90, maxHeight: 90)
            .padding(.all)
    }
    
    var body: some View {
        guard let artist = artist else {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            ZStack {
                // Main Card Content
                ZStack {
                    HStack(alignment: .center) {
                        if artist.images == nil || artist.images!.isEmpty {
                            placeholderImage
                                .blur(radius: 4.2)
                                .frame(maxHeight: maxHeight)
                        } else {
                            AsyncImage(url: URL(string: artist.images![0].url)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image.resizable()
                                        .cornerRadius(15.0)
                                case .failure:
                                    placeholderImage
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .blur(radius: 4.2)
                            .frame(maxHeight: maxHeight)
                        }
                    }
                    .cornerRadius(15.0)
                    
                    RoundedRectangle(cornerRadius: 15.0)
                        .foregroundColor(.gray.opacity(0.7))
                        .frame(maxHeight: maxHeight)
                    
                    HStack(alignment: .center) {
                        if artist.images == nil || artist.images!.isEmpty {
                            placeholderImage
                        } else {
                            AsyncImage(url: URL(string: artist.images![0].url)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image.resizable()
                                        .cornerRadius(15.0)
                                case .failure:
                                    placeholderImage
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .cornerRadius(15.0)
                            .frame(maxWidth: 90, maxHeight: 90)
                            .padding(.all)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(artist.name)
                                .bold()
                                .lineLimit(2)
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
