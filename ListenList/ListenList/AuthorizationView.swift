//
//  AuthorizationView.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 11/2/23.
//

import SwiftUI
@preconcurrency import WebKit

struct WebView: UIViewRepresentable {
    
    @EnvironmentObject var authManager: AuthManager
    
    var url: URL
    @Binding var showWebView: Bool

    func makeUIView(context: Context) -> WKWebView {
        let wKWebView = WKWebView()
        wKWebView.navigationDelegate = context.coordinator
        context.coordinator.setupObserver(for: wKWebView)
        return wKWebView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(self)
    }
    
    class WebViewCoordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        private var urlObserver: NSKeyValueObservation?
        private var didFindCode = false
        private var isAwaitingFinalLoad = false

        init(_ parent: WebView) {
            self.parent = parent
        }

        func setupObserver(for webView: WKWebView) {
            if urlObserver == nil {
                urlObserver = webView.observe(\.url, options: .new) { [weak self] webView, change in
                    guard let self = self, let url = webView.url, !self.didFindCode else { return }

                    let REDIRECT_URI_HOST = Bundle.main.object(forInfoDictionaryKey: "REDIRECT_URI_HOST") as? String
                    let REDIRECT_URI_SCHEME = Bundle.main.object(forInfoDictionaryKey: "REDIRECT_URI_SCHEME") as? String
                    let baseRedirectURI = "\(REDIRECT_URI_SCHEME ?? "")://\(REDIRECT_URI_HOST ?? "")"

                    if url.absoluteString.starts(with: baseRedirectURI) {
                        if getCodeFromURL(urlString: url.absoluteString) != nil {
                            self.didFindCode = true
                            self.isAwaitingFinalLoad = true
                        }
                    }
                }
            }
        }
        
        func getCodeFromURL(urlString: String) -> String? {
            return URLComponents(string: urlString)?.queryItems?.first(where: { $0.name == "code" })?.value
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if self.isAwaitingFinalLoad {
                self.isAwaitingFinalLoad = false
                guard let url = webView.url, let code = getCodeFromURL(urlString: url.absoluteString) else { return }
                
                DispatchQueue.main.async {
                    self.parent.authManager.logIn(with: code)
                    self.parent.showWebView = false
                    self.urlObserver?.invalidate()
                }
            }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }

        deinit {
            urlObserver?.invalidate()
        }
    }
}


struct AuthorizationView: View {
    
    @State var showWebView: Bool = false
    var urlString: String
    
    var body: some View {
        NavigationView {
            VStack {
                Image("AppIcon")
                    .resizable()
                    .cornerRadius(30.0)
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                Button("Authorize") {
                    showWebView = true
                }
                .padding(10)
                .sheet(isPresented: $showWebView) {
                    WebView(url: URL(string: urlString)!, showWebView: $showWebView)
                }
            }
        }
    }
}
