// ListenList/ListenList/Details/AudiobookDetailView.swift

import SwiftUI

struct AudiobookDetailView: View {
    var audiobook: Audiobook
    
    @State private var rating = 0
    @State private var comment = ""
    @State private var isAlreadyCompleted = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header section
                HStack(alignment: .top, spacing: 15) {
                    if let imageUrl = audiobook.images.first?.url, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } else {
                                Color.gray
                            }
                        }
                        .frame(width: 120, height: 180)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(audiobook.name)
                            .font(.headline)
                            .bold()
                        
                        Text("By: " + audiobook.authors.map { $0.name }.joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Narrated by: " + audiobook.narrators.map { $0.name }.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(audiobook.publisher)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let chapters = audiobook.total_chapters {
                            Text("\(chapters) Chapters")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if !audiobook.edition.isEmpty {
                            Text(audiobook.edition)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        if audiobook.explicit {
                            Image(systemName: "e.square.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // Log as Completed Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Log as Completed")
                        .font(.headline)
                    
                    HStack {
                        Text("Rating:")
                        RatingView(rating: $rating)
                    }
                    
                    TextField("Optional Comment", text: $comment)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: logAsCompleted) {
                        Text(isAlreadyCompleted ? "Update Completion" : "Log as Completed")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 10)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(15)
                .padding(.horizontal)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Description")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    
                    Text(audiobook.description)
                        .font(.body)
                        .padding(.horizontal)
                }
            }
            .padding(.top, 20)
        }
        .navigationTitle("Audiobook Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let audiobookRating = audiobook.rating {
                self.rating = audiobookRating
                self.isAlreadyCompleted = true
            }
            if let audiobookComment = audiobook.comment {
                self.comment = audiobookComment
            }
        }
    }
    
    private func logAsCompleted() {
        DatabaseManager.shared.logAudiobookAsCompleted(withId: audiobook.id, rating: rating, comment: comment) { error in
            if let error = error {
                print("Error logging audiobook as completed: \(error.localizedDescription)")
            } else {
                Task { @MainActor in
                    await ListManager.shared.fetchListenList(forceReload: true)
                }
            }
        }
    }
}
