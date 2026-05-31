//
//  ListenListApp.swift
//  ListenList
//
//  Created by Brandon Lamer-Connolly on 10/11/24.
//

import SwiftUI
import Foundation
import FirebaseCore
import FirebaseFirestore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct ListenListApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = AuthManager()
    @StateObject private var settingsManager = SettingsManager()

    var body: some Scene {
        WindowGroup {
            ZStack {
                if authManager.isLoading {
                    ProgressView("Logging in...")
                } else if authManager.isAuthenticated {
                    TabUIView()
                } else {
                    AuthorizationView()
                }
            }
            .environmentObject(authManager)
            .environmentObject(SearchManager.shared)
            .environmentObject(settingsManager)
        }
    }
}
