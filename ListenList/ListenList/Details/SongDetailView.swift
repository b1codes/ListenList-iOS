// ListenList/ListenList/Details/SongDetailView.swift

import SwiftUI

struct SongDetailView: View {
    var song: Song
    
    private func artistsToStr() -> String {
        return song.artists.map { $0.name }.joined(separator: ", ")
    }
    
    private func durationToStr() -> String {
        let seconds = song.duration_ms / 1000
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 30) {
                // Large Album Art
                if let imageUrl = song.album.images.first?.url, let url = URL(string: imageUrl) {
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
                    .cornerRadius(20)
                    .shadow(radius: 15)
                }
                
                VStack(spacing: 10) {
                    Text(song.name)
                        .font(.title)
                        .bold()
                        .multilineTextAlignment(.center)
                    
                    Text(artistsToStr())
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Text(song.album.name)
                        .font(.headline)
                        .foregroundColor(.accentColor)
                }
                .padding(.horizontal)
                
                Divider()
                
                // Detailed Stats
                HStack(spacing: 40) {
                    VStack {
                        Text("Duration")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(durationToStr())
                            .font(.headline)
                    }
                    
                    VStack {
                        Text("Popularity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(song.popularity)%")
                            .font(.headline)
                    }
                    
                    if song.explicit {
                        VStack {
                            Text("Content")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Image(systemName: "e.square.fill")
                                .font(.headline)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.top, 20)
        }
        .navigationTitle("Song Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
