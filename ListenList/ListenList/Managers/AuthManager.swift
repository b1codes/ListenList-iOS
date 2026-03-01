//
//  AuthManager.swift
//  ListenList
//
//  Created by Brandon Lamer-Connolly on 8/1/25.
//

import Foundation
import KeychainSwift

class AuthManager: ObservableObject {

    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = true // Start in a loading state

    var accessToken: String?
    var tokenType: String?

    private var keychain = KeychainSwift()

    init() {
        // Immediately attempt to refresh the token on launch
        if keychain.get("refreshToken") != nil {
            refreshToken()
        } else {
            self.isLoading = false
        }
    }

    func logIn(with code: String) {
        self.isLoading = true
        exchangeCodeForTokens(code: code)
    }

    func logout() {
        keychain.delete("refreshToken")
        self.accessToken = nil
        self.tokenType = nil
        self.isAuthenticated = false
    }

    func refreshToken() {
        guard let refreshToken = keychain.get("refreshToken") else {
            // If there's no refresh token, the user needs to log in
            DispatchQueue.main.async {
                self.isAuthenticated = false
                self.isLoading = false
            }
            return
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "accounts.spotify.com"
        components.path = "/api/token"

        var urlRequest = URLRequest(url: components.url!)
        urlRequest.httpMethod = "POST"

        let SPOTIFY_API_CLIENT_ID = Bundle.main.object(forInfoDictionaryKey: "SPOTIFY_API_CLIENT_ID") as? String
        let SPOTIFY_API_CLIENT_SECRET = Bundle.main.object(forInfoDictionaryKey: "SPOTIFY_API_CLIENT_SECRET") as? String

        let combo = "\(SPOTIFY_API_CLIENT_ID ?? ""):\(SPOTIFY_API_CLIENT_SECRET ?? "")"
        let comboEncoded = combo.data(using: .utf8)?.base64EncodedString()

        urlRequest.allHTTPHeaderFields = ["Authorization" : "Basic \(comboEncoded!)", "Content-Type" : "application/x-www-form-urlencoded"]

        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken)
        ]

        urlRequest.httpBody = bodyComponents.query?.data(using: .utf8)

        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            DispatchQueue.main.async {
                 if let error = error {
                    print("Error refreshing token: \(error.localizedDescription)")
                    self.isAuthenticated = false
                    self.isLoading = false
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Invalid response when refreshing token")
                    self.isAuthenticated = false
                    self.isLoading = false
                    return
                }
                
                if (200...299).contains(httpResponse.statusCode) {
                    if let data = data,
                       let accessTokenResponse = try? JSONDecoder().decode(AccessTokenResponse.self, from: data) {

                        self.accessToken = accessTokenResponse.access_token
                        self.tokenType = accessTokenResponse.token_type

                        if let newRefreshToken = accessTokenResponse.refresh_token {
                            self.keychain.set(newRefreshToken, forKey: "refreshToken")
                        }

                        self.isAuthenticated = true
                    } else {
                        self.isAuthenticated = false
                    }
                } else {
                     print("Error refreshing token. Status code: \(httpResponse.statusCode)")
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("Response body: \(responseString)")
                    }
                    self.isAuthenticated = false
                }
                self.isLoading = false
            }
        }.resume()
    }

    private func exchangeCodeForTokens(code: String) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "accounts.spotify.com"
        components.path = "/api/token"

        var urlRequest = URLRequest(url: components.url!)
        urlRequest.httpMethod = "POST"

        let SPOTIFY_API_CLIENT_ID = Bundle.main.object(forInfoDictionaryKey: "SPOTIFY_API_CLIENT_ID") as? String
        let SPOTIFY_API_CLIENT_SECRET = Bundle.main.object(forInfoDictionaryKey: "SPOTIFY_API_CLIENT_SECRET") as? String

        let combo = "\(SPOTIFY_API_CLIENT_ID ?? ""):\(SPOTIFY_API_CLIENT_SECRET ?? "")"
        let comboEncoded = combo.data(using: .utf8)?.base64EncodedString()

        urlRequest.allHTTPHeaderFields = ["Authorization" : "Basic \(comboEncoded!)", "Content-Type" : "application/x-www-form-urlencoded"]

        let REDIRECT_URI_HOST = Bundle.main.object(forInfoDictionaryKey: "REDIRECT_URI_HOST") as? String
        let REDIRECT_URI_SCHEME = Bundle.main.object(forInfoDictionaryKey: "REDIRECT_URI_SCHEME") as? String
        let redirectURI = "\(REDIRECT_URI_SCHEME ?? "")://\(REDIRECT_URI_HOST ?? "")"

        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: redirectURI)
        ]

        urlRequest.httpBody = bodyComponents.query?.data(using: .utf8)

        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let data = data,
                   let accessTokenResponse = try? JSONDecoder().decode(AccessTokenResponse.self, from: data) {

                    self.accessToken = accessTokenResponse.access_token
                    self.tokenType = accessTokenResponse.token_type
                    if let refreshToken = accessTokenResponse.refresh_token {
                        self.keychain.set(refreshToken, forKey: "refreshToken")
                    }
                    self.isAuthenticated = true
                } else {
                    self.isAuthenticated = false
                }
            }
        }.resume()
    }
}
