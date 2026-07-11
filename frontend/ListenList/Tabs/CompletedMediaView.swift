// ListenList/ListenList/Tabs/CompletedMediaView.swift

import SwiftUI

struct CompletedMediaView: View {
    @EnvironmentObject var listManager: ListManager
    @EnvironmentObject var tabSelection: TabSelectionManager
    @State private var isGridView = false
    @State private var filterType: CardType?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var filteredCards: [Card] {
        guard let filterType = filterType else { return listManager.completedCards }
        return listManager.completedCards.filter { $0.type == filterType }
    }

    private func pluralLabel(for cardType: CardType) -> String {
        switch cardType {
        case .song: return "Songs"
        case .album: return "Albums"
        case .artist: return "Artists"
        case .podcast: return "Podcasts"
        case .audiobook: return "Audiobooks"
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    if listManager.isLoading {
                        SkeletonCardListView()
                    } else if filteredCards.isEmpty {
                        if let filterType {
                            VStack(spacing: 12) {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                Text("No \(pluralLabel(for: filterType).lowercased()) completed yet.")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Button("Clear Filter") {
                                    self.filterType = nil
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.top, 100)
                        } else if listManager.cards.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                Text("Nothing completed yet")
                                    .font(.headline)
                                Text("Search for a song, album, podcast, or audiobook, add it to your ListenList, then log it here when you finish it.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                                Button {
                                    tabSelection.selected = .search
                                } label: {
                                    Label("Search to Get Started", systemImage: "magnifyingglass")
                                }
                                .buttonStyle(.borderedProminent)
                                .padding(.top, 4)
                            }
                            .padding(.top, 80)
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                Text("Nothing completed yet")
                                    .font(.headline)
                                Text("Rate and log something from your ListenList when you finish it, and it'll show up here.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                                Button {
                                    tabSelection.selected = .home
                                } label: {
                                    Label("Go to Your ListenList", systemImage: "play.house.fill")
                                }
                                .buttonStyle(.borderedProminent)
                                .padding(.top, 4)
                            }
                            .padding(.top, 80)
                        }
                    } else {
                        if isGridView {
                            CardGrid(results: filteredCards)
                        } else {
                            CardList(results: filteredCards)
                        }
                    }
                }
            }
            .refreshable {
                await listManager.fetchListenList(forceReload: true)
            }
            .navigationTitle("Completed")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.65)) {
                            isGridView.toggle()
                        }
                    } label: {
                        Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                            .font(.body.weight(.semibold))
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
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
                }
            }
        }
    }
}
