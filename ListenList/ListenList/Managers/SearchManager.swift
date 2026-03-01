//
//  SearchManager.swift
//  ListenList
//
//  Created by Gemini on 3/1/26.
//

import SwiftUI
import Combine

class SearchManager: ObservableObject {
    @Published var searchText: String = ""
    @Published var isSearchActive: Bool = false
    @Published var searchBy: Int = 0 // 0: Album, 1: Artist, 2: Song, 3: Podcast, 4: Audiobook
    
    static let shared = SearchManager()
    
    private init() {}
}
