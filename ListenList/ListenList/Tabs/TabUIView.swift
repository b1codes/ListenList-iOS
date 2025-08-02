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
    
    var body: some View {
        TabView {
            ListenListView()
                .tabItem {
                    Image(systemName: "play.house.fill")
                    Text("Home")
                }
            
            if let accessToken = authManager.accessToken, let tokenType = authManager.tokenType {
                SearchView(access: accessToken, type: tokenType)
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text("Search")
                    }
            }
        }
        .accentColor(.black)
        .navigationBarBackButtonHidden(true)
    }
}
