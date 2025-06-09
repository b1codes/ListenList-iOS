//
//  AlbumCard.swift
//  ListenList
//
//  Created by Brandon Lamer-Connolly on 10/12/24.
//

import SwiftUI

struct AlbumCard: View {
    var input: Media
    var album: Album?
    
    let maxHeight: CGFloat = 120
    
    init(input: Media) {
        self.input = input
        if case let .album(album) = input.input {
            self.album = album
        }
    }
    
    private func artistsToStr() -> String {
        guard let artists = album?.artists, !artists.isEmpty else { return "Unknown Artist" }
        return artists.map { $0.name }.joined(separator: ", ")
    }
    
    private var placeholderImage: some View {
        Image(systemName: "photo")
            .resizable()
            .scaledToFit()
            .cornerRadius(15.0)
            .frame(maxWidth: 90, maxHeight: 90)
            .padding(.all)
    }
    
    var body: some View {
        guard let album = album else {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            ZStack {
                HStack(alignment: .center) {
                    if album.images.isEmpty {
                        placeholderImage
                            .blur(radius: 4.2)
                            .frame(maxHeight: maxHeight)
                    } else {
                        AsyncImage(url: URL(string: album.images[0].url)) { phase in
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
                    if album.images.isEmpty {
                        placeholderImage
                    } else {
                        AsyncImage(url: URL(string: album.images[0].url)) { phase in
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
                        Text(album.name)
                            .bold()
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        Text(artistsToStr())
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .padding(.trailing)
                    
                    Spacer()
                }
            }
            .frame(maxWidth: 600, maxHeight: maxHeight)
            .padding([.leading, .trailing], 10)
        )
    }
}


#Preview {
    let mockAlbum = Album(
        id: "123",
        images: [ImageResponse(url: "https://i.scdn.co/image/ab67616d0000b273f76f8deeba5370c98ad38f1c", height: 640, width: 640)],
        name: "Mock Album",
        release_date: "2023-01-01",
        artists: [Artist(id: "012", name: "Mock Artist", artistId: "123")]
    )
    AlbumCard(input: Media(input: .album(mockAlbum)))
}
