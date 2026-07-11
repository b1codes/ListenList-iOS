//
//  TabUIView.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 10/24/23.
//

import SwiftUI
import Foundation

struct TabUIView: View {

    @EnvironmentObject var authManager: AuthManager
    @StateObject private var listManager = ListManager.shared
    @StateObject private var tabSelection = TabSelectionManager()
    @State private var searchText = ""

    var body: some View {
        if #available(iOS 18.0, *) {
            TabView(selection: $tabSelection.selected) {
                Tab("Home", systemImage: "play.house.fill", value: .home) {
                    ListenListView()
                }

                Tab("Completed", systemImage: "checkmark.seal.fill", value: .completed) {
                    CompletedMediaView()
                }

                Tab("Settings", systemImage: "gearshape.fill", value: .settings) {
                    SettingsView()
                }

                if let accessToken = authManager.accessToken, let tokenType = authManager.tokenType {
                    Tab("Search", systemImage: "magnifyingglass", value: .search, role: .search) {
                        NavigationStack {
                            SearchView(access: accessToken, type: tokenType, searchText: $searchText)
                        }
                        .searchable(text: $searchText, placement: .automatic)
                    }
                }
            }
            .environmentObject(listManager)
            .environmentObject(tabSelection)
            .navigationBarBackButtonHidden(true)
            .alert(
                "Something Went Wrong",
                isPresented: Binding(
                    get: { listManager.errorMessage != nil },
                    set: { isPresented in if !isPresented { listManager.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(listManager.errorMessage ?? "")
            }
        } else {
            // Fallback for older iOS versions
            TabView(selection: $tabSelection.selected) {
                ListenListView()
                    .tabItem {
                        Image(systemName: "play.house.fill")
                        Text("Home")
                    }
                    .tag(AppTab.home)

                CompletedMediaView()
                    .tabItem {
                        Image(systemName: "checkmark.seal.fill")
                        Text("Completed")
                    }
                    .tag(AppTab.completed)

                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }
                    .tag(AppTab.settings)

                if let accessToken = authManager.accessToken, let tokenType = authManager.tokenType {
                    SearchView(access: accessToken, type: tokenType, searchText: .constant(""))
                        .tabItem {
                            Image(systemName: "magnifyingglass")
                            Text("Search")
                        }
                        .tag(AppTab.search)
                }
            }
            .environmentObject(listManager)
            .environmentObject(tabSelection)
            .navigationBarBackButtonHidden(true)
            .alert(
                "Something Went Wrong",
                isPresented: Binding(
                    get: { listManager.errorMessage != nil },
                    set: { isPresented in if !isPresented { listManager.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(listManager.errorMessage ?? "")
            }
        }
    }
}
