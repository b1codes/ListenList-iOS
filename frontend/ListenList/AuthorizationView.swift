//
//  AuthorizationView.swift
//  ListenList
//

import SwiftUI

struct AuthorizationView: View {

    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationView {
            VStack {
                Image("AppIcon")
                    .resizable()
                    .cornerRadius(30.0)
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                Button("Sign In") {
                    Task {
                        await authManager.login()
                    }
                }
                .padding(10)
                .disabled(authManager.isLoading)

                if authManager.isLoading {
                    ProgressView()
                }
            }
        }
    }
}
