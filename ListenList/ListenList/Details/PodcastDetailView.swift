// ListenList/ListenList/Details/PodcastDetailView.swift

import SwiftUI

struct PodcastDetailView: View {
    var podcast: Podcast
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header section
                HStack(alignment: .top, spacing: 15) {
                    if let imageUrl = podcast.images.first?.url, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } else {
                                Color.gray
                            }
                        }
                        .frame(width: 120, height: 120)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(podcast.name)
                            .font(.title3)
                            .bold()
                        
                        Text(podcast.publisher)
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("\(podcast.total_episodes) Episodes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if podcast.explicit {
                                Image(systemName: "e.square.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Description")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    
                    Text(podcast.description)
                        .font(.body)
                        .padding(.horizontal)
                }
            }
            .padding(.top, 20)
        }
        .navigationTitle("Podcast Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
