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
    @State private var searchText = ""

    var body: some View {
        if #available(iOS 18.0, *) {
            TabView {
                Tab("Home", systemImage: "play.house.fill") {
                    ListenListView()
                }

                Tab("Completed", systemImage: "checkmark.seal.fill") {
                    CompletedMediaView()
                }

                Tab("Settings", systemImage: "gearshape.fill") {
                    SettingsView()
                }

                if let accessToken = authManager.accessToken, let tokenType = authManager.tokenType {
                    Tab("Search", systemImage: "magnifyingglass", role: .search) {
                        NavigationStack {
                            SearchView(access: accessToken, type: tokenType, searchText: $searchText)
                        }
                        .searchable(text: $searchText, placement: .automatic)
                        .tabBarMinimizeBehavior(.onScrollDown)
                    }
                }
            }
            .environmentObject(listManager)
            .navigationBarBackButtonHidden(true)
        } else {
            // Fallback for older iOS versions
            TabView {
                ListenListView()
                    .tabItem {
                        Image(systemName: "play.house.fill")
                        Text("Home")
                    }

                CompletedMediaView()
                    .tabItem {
                        Image(systemName: "checkmark.seal.fill")
                        Text("Completed")
                    }

                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }

                if let accessToken = authManager.accessToken, let tokenType = authManager.tokenType {
                    SearchView(access: accessToken, type: tokenType, searchText: .constant(""))
                        .tabItem {
                            Image(systemName: "magnifyingglass")
                            Text("Search")
                        }
                }
            }
            .environmentObject(listManager)
            .navigationBarBackButtonHidden(true)
        }
    }
}
