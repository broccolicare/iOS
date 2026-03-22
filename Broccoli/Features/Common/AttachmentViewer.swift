//
//  AttachmentViewer.swift
//  Broccoli
//

import SwiftUI
import WebKit

// MARK: - URL + Identifiable (used for .sheet(item:))
extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

// MARK: - In-app attachment viewer sheet
struct AttachmentViewer: View {
    let url: URL
    let fileName: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                AttachmentWebViewRepresentable(url: url, isLoading: $isLoading)
                    .ignoresSafeArea(edges: .bottom)

                if isLoading {
                    ProgressView()
                        .scaleEffect(1.4)
                }
            }
            .navigationTitle(fileName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(theme.colors.textPrimary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        UIApplication.shared.open(url)
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(theme.colors.primary)
                    }
                }
            }
        }
    }
}

// MARK: - WKWebView wrapper
struct AttachmentWebViewRepresentable: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: AttachmentWebViewRepresentable
        init(_ parent: AttachmentWebViewRepresentable) { self.parent = parent }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
    }
}
