// ListenList/ListenList/Tabs/ListenListView.swift

import SwiftUI
import FirebaseFirestore

struct ListenListView: View {
    
    @EnvironmentObject var listManager: ListManager
    @State private var isInEditMode = false
    @State private var isGridView = false
    @State private var filterType: CardType? = nil
    
    @Namespace private var namespace
    
    var filteredCards: [Card] {
        guard let filterType = filterType else { return listManager.cards }
        return listManager.cards.filter { $0.type == filterType }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    if listManager.isLoading {
                        ProgressView("Loading...")
                    } else if filteredCards.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tray.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("No items found.")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            if filterType != nil {
                                Button("Clear Filter") {
                                    filterType = nil
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.top, 100)
                    } else {
                        if isGridView {
                            CardGrid(results: filteredCards, isInEditMode: isInEditMode, onDelete: listManager.delete)
                        } else {
                            CardList(results: filteredCards, isInEditMode: isInEditMode, onDelete: listManager.delete)
                        }
                    }
                }
            }
            .refreshable {
                await listManager.fetchListenList(forceReload: true)
            }
            .navigationTitle("Your ListenList")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                            isGridView.toggle()
                        }
                    } label: {
                        Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                            .font(.body.weight(.semibold))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 20) {
                        Menu {
                            Button(action: { filterType = nil }) {
                                Label("All", systemImage: filterType == nil ? "checkmark" : "")
                            }
                            Divider()
                            Button(action: { filterType = .song }) {
                                Label("Songs", systemImage: filterType == .song ? "checkmark" : "music.note")
                            }
                            Button(action: { filterType = .album }) {
                                Label("Albums", systemImage: filterType == .album ? "checkmark" : "rectangle.stack")
                            }
                            Button(action: { filterType = .artist }) {
                                Label("Artists", systemImage: filterType == .artist ? "checkmark" : "person.crop.circle")
                            }
                            Button(action: { filterType = .podcast }) {
                                Label("Podcasts", systemImage: filterType == .podcast ? "checkmark" : "dot.radiowaves.left.and.right")
                            }
                            Button(action: { filterType = .audiobook }) {
                                Label("Audiobooks", systemImage: filterType == .audiobook ? "checkmark" : "book.closed")
                            }
                        } label: {
                            Image(systemName: filterType == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                                .font(.body.weight(.semibold))
                                .foregroundColor(filterType == nil ? .primary : .accentColor)
                        }
                        
                        Button {
                            withAnimation {
                                isInEditMode.toggle()
                            }
                        } label: {
                            Image(systemName: isInEditMode ? "checkmark.circle.fill" : "pencil.circle")
                                .font(.body.weight(.semibold))
                                .foregroundColor(isInEditMode ? .accentColor : .primary)
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    await listManager.fetchListenList()
                }
            }
        }
    }
}

