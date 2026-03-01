// ListenList/ListenList/Tabs/ListenListView.swift

import SwiftUI
import FirebaseFirestore

struct ListenListView: View {
    
    @EnvironmentObject var listManager: ListManager
    @State private var isInEditMode = false
    @State private var isGridView = false
    
    @Namespace private var namespace
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    if listManager.isLoading {
                        ProgressView("Loading...")
                    } else if listManager.cards.isEmpty {
                        Text("No items found.")
                    } else {
                        if isGridView {
                            CardGrid(results: listManager.cards, isInEditMode: isInEditMode, onDelete: listManager.delete)
                        } else {
                            CardList(results: listManager.cards, isInEditMode: isInEditMode, onDelete: listManager.delete)
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
                    // This HStack has NO background of its own.
                    HStack(spacing: 10) {
                        Image(systemName: "list.bullet")
                            .font(.body.weight(.semibold))
                            // Use the app's Accent Color for the selected item for high contrast.
                            .foregroundColor(isGridView ? .secondary : .accentColor)
                            .frame(width: 36, height: 36)
                            .background {
                                if !isGridView {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        // Use a more prominent material for the "bubble".
                                        .fill(.regularMaterial)
                                        .matchedGeometryEffect(id: "selection-bubble", in: namespace)
                                }
                            }
                            .onTapGesture {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                                    isGridView = false
                                }
                            }

                        Image(systemName: "square.grid.2x2")
                            .font(.body.weight(.semibold))
                            .foregroundColor(isGridView ? .accentColor : .secondary)
                            .frame(width: 36, height: 36)
                            .background {
                                if isGridView {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(.regularMaterial)
                                        .matchedGeometryEffect(id: "selection-bubble", in: namespace)
                                }
                            }
                            .onTapGesture {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                                    isGridView = true
                                }
                            }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isInEditMode ? "Done" : "Edit") {
                        withAnimation {
                            isInEditMode.toggle()
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

