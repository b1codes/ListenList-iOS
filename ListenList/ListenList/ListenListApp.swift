//
//  ListenListApp.swift
//  ListenList
//
//  Created by Brandon Lamer-Connolly on 10/11/24.
//

import SwiftUI
import Foundation
import CryptoKit
import WebKit
import FirebaseCore
import FirebaseFirestore


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

func generateRandomString(length: Int) -> String {
    let byteCount = length / 2
    var bytes = [UInt8](repeating: 0, count: byteCount)
    let result = SecRandomCopyBytes(kSecRandomDefault, byteCount, &bytes)
    guard result == errSecSuccess else {
        fatalError("Failed to generate random bytes: \(result)")
    }
    let hexString = bytes.map { String(format: "%02x", $0) }.joined()
    return hexString.padding(toLength: length, withPad: "0", startingAt: 0)
}


@main
struct ListenListApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = AuthManager()
    
    var authURL: String = ""
    
    init() {
        self.authURL = getAuthorizationCodeURL()
    }
    
    func getAuthorizationCodeURL() -> String {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "accounts.spotify.com"
        components.path = "/authorize"
        let SPOTIFY_API_CLIENT_ID = Bundle.main.object(forInfoDictionaryKey: "SPOTIFY_API_CLIENT_ID") as? String
        let REDIRECT_URI_HOST = Bundle.main.object(forInfoDictionaryKey: "REDIRECT_URI_HOST") as? String
        let REDIRECT_URI_SCHEME = Bundle.main.object(forInfoDictionaryKey: "REDIRECT_URI_SCHEME") as? String

        let redirectURI = "\(REDIRECT_URI_SCHEME ?? "")://\(REDIRECT_URI_HOST ?? "")"
        let state = generateRandomString(length: 16)
        let scope = "user-read-private user-read-email user-top-read"
        
        components.queryItems = [
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "client_id", value: SPOTIFY_API_CLIENT_ID)
        ]
        return components.string!
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if authManager.isLoading {
                    ProgressView("Logging in...")
                } else if authManager.isAuthenticated {
                    TabUIView()
                } else {
                    AuthorizationView(urlString: self.authURL)
                }
            }
            .environmentObject(authManager)
        }
    }
}
