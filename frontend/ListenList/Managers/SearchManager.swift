//
//  SearchManager.swift
//  ListenList
//
//  Created by Gemini on 3/1/26.
//

import SwiftUI
import Combine

enum SearchType: Int, CaseIterable, Identifiable {
    case album = 0
    case artist = 1
    case song = 2
    case podcast = 3
    case audiobook = 4
    
    var id: Int { self.rawValue }
    
    var displayName: String {
        switch self {
        case .album: return "Album"
        case .artist: return "Artist"
        case .song: return "Song"
        case .podcast: return "Podcast"
        case .audiobook: return "Audiobook"
        }
    }
}

class SearchManager: ObservableObject {
    @Published var searchText: String = ""
    @Published var searchBy: SearchType = .album

    static let shared = SearchManager()

    private init() {}
}
