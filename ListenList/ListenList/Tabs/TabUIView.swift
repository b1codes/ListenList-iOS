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
    @StateObject private var searchManager = SearchManager.shared
    @State private var selectedTab: Int = 0
    @Namespace private var animation
    
    var body: some View {
        if #available(iOS 26.0, *) {
            ZStack(alignment: .bottom) {
                // Main Content
                ZStack {
                    switch selectedTab {
                    case 0:
                        ListenListView()
                    case 1:
                        if let accessToken = authManager.accessToken, let tokenType = authManager.tokenType {
                            SearchView(access: accessToken, type: tokenType)
                        }
                    case 2:
                        CompletedMediaView()
                    case 3:
                        SettingsView()
                    default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 80) // Standard spacing
                
                // Custom Shrinking Tab Bar (iOS 26 style)
                HStack(spacing: 0) {
                    if selectedTab == 1 {
                        // Shrink to Search Bar
                        GlassEffectContainer(spacing: 12) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 12)
                                
                                TextField("Search...", text: $searchManager.searchText)
                                    .textFieldStyle(.plain)
                                
                                if !searchManager.searchText.isEmpty {
                                    Button {
                                        searchManager.searchText = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.trailing, 8)
                                }
                                
                                Button("Cancel") {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        selectedTab = 0
                                        searchManager.searchText = ""
                                    }
                                }
                                .padding(.trailing, 12)
                            }
                            .frame(height: 50)
                            .glassEffect(.regular.tint(Color(.systemGray6)).interactive(), in: .capsule)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        // Standard Tab Bar
                        HStack(spacing: 0) {
                            TabButton(title: "Home", icon: "play.house.fill", index: 0, selectedTab: $selectedTab, animation: animation)
                            TabButton(title: "Search", icon: "magnifyingglass", index: 1, selectedTab: $selectedTab, animation: animation)
                            TabButton(title: "Done", icon: "checkmark.seal.fill", index: 2, selectedTab: $selectedTab, animation: animation)
                            TabButton(title: "Settings", icon: "gearshape.fill", index: 3, selectedTab: $selectedTab, animation: animation)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 25)
                        .glassEffect(.regular.tint(Color(.systemGray6)).interactive(), in: .capsule)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)
            }
            .environmentObject(listManager)
            .environmentObject(searchManager)
            .navigationBarBackButtonHidden(true)
            .ignoresSafeArea(.keyboard, edges: .bottom)
        } else {
            // Fallback for older iOS
            TabView(selection: $selectedTab) {
                ListenListView()
                    .tabItem {
                        Image(systemName: "play.house.fill")
                        Text("Home")
                    }
                    .tag(0)
                
                if let accessToken = authManager.accessToken, let tokenType = authManager.tokenType {
                    SearchView(access: accessToken, type: tokenType)
                        .tabItem {
                            Image(systemName: "magnifyingglass")
                            Text("Search")
                        }
                        .tag(1)
                }
                
                CompletedMediaView()
                    .tabItem {
                        Image(systemName: "checkmark.seal.fill")
                        Text("Completed")
                    }
                    .tag(2)

                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }
                    .tag(3)
            }
            .environmentObject(listManager)
            .navigationBarBackButtonHidden(true)
        }
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let index: Int
    @Binding var selectedTab: Int
    var animation: Namespace.ID
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                selectedTab = index
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.caption2)
            }
            .foregroundColor(selectedTab == index ? .accentColor : .secondary)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
    }
}
