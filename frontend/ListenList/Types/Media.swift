//
//  Media.swift
//  ListenList
//
//  Created by Brandon Lamer-Connolly on 10/12/24.
//

import Foundation

struct Media {
    var input: MediaType
}

// Enum to represent different media types
// ListenList/ListenList/Types/Media.swift

enum MediaType {
    case song(Song)
    case artist(Artist)
    case album(Album)
    case podcast(Podcast)
    case audiobook(Audiobook)
}
