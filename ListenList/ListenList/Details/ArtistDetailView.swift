// ListenList/ListenList/Details/ArtistDetailView.swift

import SwiftUI

struct ArtistDetailView: View {
    var artist: Artist
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 30) {
                // Large Artist Image
                if let imageUrl = artist.images?.first?.url, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } else {
                            Color.gray
                        }
                    }
                    .frame(maxWidth: 300)
                    .clipShape(Circle())
                    .shadow(radius: 15)
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 10) {
                    Text(artist.name)
                        .font(.largeTitle)
                        .bold()
                        .multilineTextAlignment(.center)
                    
                    if let popularity = artist.popularity {
                        HStack {
                            Text("Popularity:")
                                .foregroundColor(.secondary)
                            Text("\(popularity)%")
                                .bold()
                        }
                        .font(.headline)
                    }
                    if let genres = artist.genres, !genres.isEmpty {
                        Text(genres.joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // Placeholder for Top Tracks or Albums could go here
                VStack(alignment: .leading, spacing: 10) {
                    Text("About")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    
                    Text("\(artist.name) is a Spotify artist. This view could be expanded to show top tracks, albums, or related artists from the Spotify API.")
                        .font(.body)
                        .padding(.horizontal)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.top, 20)
        }
        .navigationTitle("Artist Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
