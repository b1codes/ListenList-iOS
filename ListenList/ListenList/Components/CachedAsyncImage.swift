//
//  CachedAsyncImage.swift
//  ListenList
//
//  Created by Gemini CLI on 4/23/26.
//

import SwiftUI

@MainActor
class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    @Published var error: Error?

    private static let cache: URLCache = {
        let memoryCapacity = 50 * 1024 * 1024 // 50 MB
        let diskCapacity = 100 * 1024 * 1024 // 100 MB
        return URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, directory: nil)
    }()

    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = cache
        return URLSession(configuration: config)
    }()

    func load(from url: URL) async {
        guard image == nil && !isLoading else { return }

        isLoading = true
        error = nil

        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 10.0)

        // Check cache first manually if needed, but URLSession with policy should handle it.
        if let cachedResponse = ImageLoader.cache.cachedResponse(for: request),
           let cachedImage = UIImage(data: cachedResponse.data) {
            self.image = cachedImage
            self.isLoading = false
            return
        }

        do {
            let (data, response) = try await ImageLoader.session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }

            if let downloadedImage = UIImage(data: data) {
                self.image = downloadedImage
            } else {
                throw URLError(.cannotDecodeContentData)
            }
        } catch {
            self.error = error
        }

        isLoading = false
    }
}

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let scale: CGFloat
    private let transaction: Transaction
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder

    @StateObject private var loader = ImageLoader()

    init(
        url: URL?,
        scale: CGFloat = 1.0,
        transaction: Transaction = Transaction(),
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.scale = scale
        self.transaction = transaction
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image = loader.image {
                content(Image(uiImage: image))
            } else if loader.isLoading {
                placeholder()
            } else if loader.error != nil {
                // Fallback to placeholder or a specific error view
                placeholder()
            } else {
                placeholder()
            }
        }
        .task {
            if let url = url {
                await loader.load(from: url)
            }
        }
    }
}

// Convenience initializers similar to AsyncImage
extension CachedAsyncImage {
    init(url: URL?, @ViewBuilder content: @escaping (Image) -> Content, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.init(url: url, scale: 1.0, transaction: Transaction(), content: content, placeholder: placeholder)
    }
}
