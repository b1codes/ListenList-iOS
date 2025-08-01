//
//  TabUIView.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 10/24/23.
//

import SwiftUI
import Foundation

struct AccessTokenResponse: Codable {
    let access_token: String
    let token_type: String
    let scope: String
    let expires_in: Int
    let refresh_token: String
}

struct TabUIView: View {
    var access: [String]?
//    @State var accessToken: String
//    @State var tokenType: String
//    @State var refreshToken: String? = UserDefaults.standard.object(forKey: "refreshToken") as? String
    
    init() {}
    
    init(code: String) {
//        self.accessToken = ""
//        self.tokenType = ""
        var accessResults: [String] = []
        getTokens(code: code, userCompletionHandler: { user in
            if let user = user {
                accessResults = user
            }
            
        })
        while (accessResults.isEmpty) {}
        self.access = accessResults
//        self.accessToken = accessResults[0]
//        self.tokenType = accessResults[1]
//        self.refreshToken = accessResults[2]
        
    }
    
    func getTokensURL() -> String {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "accounts.spotify.com"
        components.path = "/api/token"
        return components.string!
    }
    
    func getTokens(code: String, userCompletionHandler: @escaping ([String]?) -> Void) {
        var urlRequest = URLRequest(url: URL(string: getTokensURL())!)
        let SPOTIFY_API_CLIENT_ID = Bundle.main.object(forInfoDictionaryKey: "SPOTIFY_API_CLIENT_ID") as? String

        let SPOTIFY_API_CLIENT_SECRET = Bundle.main.object(forInfoDictionaryKey: "SPOTIFY_API_CLIENT_SECRET") as? String

        let combo = "\(SPOTIFY_API_CLIENT_ID ?? ""):\(SPOTIFY_API_CLIENT_SECRET ?? "")"
        print(combo)
        let comboEncoded = combo.data(using: .utf8)?.base64EncodedString()
        print(comboEncoded!)
        urlRequest.httpMethod = "POST"
        urlRequest.allHTTPHeaderFields = ["Authorization" : "Basic \(comboEncoded!)", "Content-Type" : "application/x-www-form-urlencoded"]
        let REDIRECT_URI_HOST = Bundle.main.object(forInfoDictionaryKey: "REDIRECT_URI_HOST") as? String
        let REDIRECT_URI_SCHEME = Bundle.main.object(forInfoDictionaryKey: "REDIRECT_URI_SCHEME") as? String

        let redirectURI = "\(REDIRECT_URI_SCHEME ?? "")://\(REDIRECT_URI_HOST ?? "")"
        let grantType = "authorization_code"
        var components = URLComponents()
        //print("code is \(code)")
        components.queryItems = [
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "grant_type", value: grantType),
        ]
        urlRequest.httpBody = components.query?.data(using: .utf8)
        
        URLSession.shared.dataTask(with: urlRequest, completionHandler: { data, response, error in
            //print("this got called")
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 404 {
                    print("Invalid login!")
                    return
                } else if httpResponse.statusCode == 500 {
                    print("Database failure!")
                    return
                } else if httpResponse.statusCode == 401 {
                    print("invalid access token")
                    return
                }
            }
            
            
            if let error = error {
                print("Error: \(error.localizedDescription)")
            } else if let data = data {
                //print("made it inn here")
                //print(data)
//                let string = String(data: data, encoding: .utf8)
                //print("string is \(string ?? "empty")")
                let ret: AccessTokenResponse = try! JSONDecoder().decode(AccessTokenResponse.self, from: data)
//                print("ret")
//                print(ret)
//                print(ret.access_token)
//                self.accessToken = ret.access_token
//                self.tokenType = ret.token_type
//                self.refreshToken = ret.refresh_token
                userCompletionHandler([ret.access_token , ret.token_type , ret.refresh_token])
            } else {
                print("Unexpected error!")
            }

        }).resume()
//        print("tempAccessToken is \(tempAccessToken)")
//        self.accessToken = tempAccessToken
//        self.tokenType = tempTokenType
//        self.refreshToken = tempRefreshToken
    }
    
    var body: some View {
        TabView {
            ListenListView()
                .tabItem {
                    Image(systemName: "play.house.fill")
                    Text("Home")
                }
                .navigationTitle("Home")
            SearchView(access: access![0], type: access![1])
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
            
        }
        .accentColor(.black)
        .navigationBarBackButtonHidden(true)
        
    }
}

//#Preview {
//    TabUIView(code: UserDefaults.standard.object(forKey: "code") as! String)
//}
