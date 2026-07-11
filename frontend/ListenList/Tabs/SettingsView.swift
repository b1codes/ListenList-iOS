//
//  SettingsView.swift
//  ListenList
//
//  Created by Gemini on 3/1/26.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var userProfile: UserProfileResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Spotify Account")) {
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else if let profile = userProfile {
                        HStack(spacing: 15) {
                            if let imageUrl = profile.images?.medium(), let url = URL(string: imageUrl) {
                                CachedAsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.gray)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(profile.displayName ?? "No Display Name")
                                    .font(.headline)
                                if let email = profile.email {
                                    Text(email)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Text("ID: \(profile.id)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    } else if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.destructiveRed)
                    }
                }

                Section(header: Text("Appearance")) {
                    VStack(alignment: .leading) {
                        Text("Card Glass Opacity")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Picker("Glass Opacity", selection: $settingsManager.glassOpacity) {
                            ForEach(GlassOpacity.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Button(action: {
                        authManager.logout()
                    }) {
                        HStack {
                            Spacer()
                            Text("Log Out")
                                .foregroundColor(.destructiveRed)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                fetchUserProfile()
            }
        }
    }

    private func fetchUserProfile() {
        // TODO: Auth migration — accessToken/tokenType are always nil after Auth0 migration.
        // Spotify profile display needs to be reworked to fetch via the backend
        // /auth/spotify/status endpoint using the session JWT once Spotify linking is implemented.
        guard let accessToken = authManager.accessToken, let tokenType = authManager.tokenType else {
            self.isLoading = false
            self.errorMessage = "Not authenticated"
            return
        }

        let apiManager = SpotifyAPIManager(access: accessToken, token: tokenType)

        Task {
            do {
                let profile = try await apiManager.getCurrentUserProfile()
                DispatchQueue.main.async {
                    self.userProfile = profile
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load profile"
                    self.isLoading = false
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthManager())
        .environmentObject(SettingsManager())
}
