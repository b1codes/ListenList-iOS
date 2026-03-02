//
//  Card.swift
//  ListenList
//
//  Created by Brandon Lamer-Connolly on 10/12/24.
//

import SwiftUI

import Foundation

struct Card: Identifiable {
    var type: CardType
    var input: Media
    var id: String

    init(input: CardType, media: Media, id: String) {
        self.type = input
        self.input = media
        self.id = id
    }
}

// Enum to represent different media types
enum CardType {
    case song
    case artist
    case album
    case podcast
    case audiobook
}
