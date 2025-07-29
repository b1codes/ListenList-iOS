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
    var onAdd: (() -> Void)? // Action to perform when add is tapped

    
    let maxHeight: CGFloat = 120
    
    init(input: Media, onAdd: (() -> Void)? = nil) {
        self.input = input
        if case let .artist(artist) = input.input {
            self.artist = artist
        }
        self.onAdd = onAdd

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
                                    //.scaledToFill()
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
                
                HStack {
                    RoundedRectangle(cornerRadius: 15.0)
                        .foregroundColor(.gray.opacity(0.7))
                        .frame(maxHeight: maxHeight)
                }
                .cornerRadius(15.0)
                
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
                    // Show the add button only if the onAdd action is provided
                    if let onAdd = onAdd {
                        Button(action: onAdd) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                                .foregroundColor(.green)
                        }
                        .padding(.trailing)
                    }
                }
            }
            .frame(maxWidth: 600, maxHeight: maxHeight)
            .padding([.leading, .trailing], 10)
        )
    }
}

#Preview {
    let mockArtist = Artist(
        id: "012", images: [ImageResponse(url: "https://i.scdn.co/image/ab6761610000e5eb19c2790744c792d05570bb71", height: 640, width: 640)],
        name: "Travis Scott",
        artistId: "246dkjvS1zLTtiykXe5h60"
    )
    ArtistCard(input: Media(input: .artist(mockArtist)))
}

