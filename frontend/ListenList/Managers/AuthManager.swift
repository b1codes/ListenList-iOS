//
//  AuthManager.swift
//  ListenList
//

import Foundation
import Auth0
import KeychainSwift

class AuthManager: ObservableObject {

    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false

    // Kept for SettingsView Spotify compatibility — nil until Spotify is linked
    var accessToken: String? = nil
    var tokenType: String? = nil

    private var keychain = KeychainSwift()

    init() {
        if let token = keychain.get("sessionToken"), !AuthManager.isTokenExpired(token) {
            isAuthenticated = true
        } else {
            keychain.delete("sessionToken")
        }
    }

    @MainActor
    func login() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let clientId = Bundle.main.object(forInfoDictionaryKey: "AUTH0_CLIENT_ID") as? String ?? ""
            let domain = Bundle.main.object(forInfoDictionaryKey: "AUTH0_DOMAIN") as? String ?? ""

            let credentials = try await Auth0
                .webAuth(clientId: clientId, domain: domain)
                .start()

            let session = try await exchangeTokenWithBackend(idToken: credentials.idToken)
            keychain.set(session.accessToken, forKey: "sessionToken")
            isAuthenticated = true
        } catch {
            print("Auth0 login failed: \(error.localizedDescription)")
        }
    }

    func logout() {
        keychain.delete("sessionToken")
        isAuthenticated = false
        let clientId = Bundle.main.object(forInfoDictionaryKey: "AUTH0_CLIENT_ID") as? String ?? ""
        let domain = Bundle.main.object(forInfoDictionaryKey: "AUTH0_DOMAIN") as? String ?? ""
        Task {
            try? await Auth0.webAuth(clientId: clientId, domain: domain).clearSession()
        }
    }

    // Internal static for unit testing
    static func isTokenExpired(_ token: String) -> Bool {
        let parts = token.components(separatedBy: ".")
        guard parts.count == 3 else { return true }

        var base64 = parts[1]
        let remainder = base64.count % 4
        if remainder != 0 { base64 += String(repeating: "=", count: 4 - remainder) }

        guard let data = Data(base64Encoded: base64) else { return true }

        struct Payload: Decodable { let exp: TimeInterval }
        guard let payload = try? JSONDecoder().decode(Payload.self, from: data) else { return true }

        return Date().timeIntervalSince1970 > payload.exp
    }

    private func exchangeTokenWithBackend(idToken: String) async throws -> SessionResponse {
        let backendBaseURL = Bundle.main.object(forInfoDictionaryKey: "BACKEND_BASE_URL") as? String ?? ""
        guard let url = URL(string: "\(backendBaseURL)/auth/auth0") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["identity_token": idToken])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(SessionResponse.self, from: data)
    }
}
