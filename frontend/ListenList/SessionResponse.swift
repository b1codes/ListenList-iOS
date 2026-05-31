//
//  SessionResponse.swift
//  ListenList
//

struct SessionResponse: Decodable {
    let accessToken: String
    let tokenType: String
    let userId: String
    let email: String?
    let spotifyLinked: Bool
}
