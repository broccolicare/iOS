//
//  StaticPageView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 13/10/25.
//

import SwiftUI
import WebKit

struct StaticPageView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var router: Router
    
    let pageType: StaticPageType
    @State private var isLoading: Bool = true
    @State private var showError: Bool = false
    @State private var reloadTrigger: Int = 0
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        router.pop()
                    }) {
                        Image("BackButton")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(theme.colors.primary)
                    }
                    
                    Spacer()
                    
                    Text(pageType.title)
                        .font(theme.typography.medium20)
                        .foregroundStyle(theme.colors.textPrimary)
                    
                    Spacer()
                    
                    // Invisible spacer for centering
                    Circle()
                        .fill(.clear)
                        .frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white)
                
                // WebView Content
                ZStack {
                    if let url = pageType.url {
                        WebView(url: url, isLoading: $isLoading, showError: $showError)
                            .id(reloadTrigger)
                            .opacity(showError ? 0 : 1)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ErrorContentView(message: "Invalid URL", onRetry: nil)
                    }
                    
                    // Loading Indicator
                    if isLoading && !showError {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading...")
                                .font(theme.typography.regular14)
                                .foregroundStyle(theme.colors.textSecondary)
                                .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white)
                        .zIndex(1)
                    }
                    
                    // Error View
                    if showError && !isLoading {
                        ErrorContentView(
                            message: "Failed to load page. Please check your internet connection and try again.",
                            onRetry: {
                                showError = false
                                isLoading = true
                                reloadTrigger += 1
                            }
                        )
                        .zIndex(2)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - WebView Wrapper
struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var showError: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = false
        webView.backgroundColor = .white
        webView.scrollView.backgroundColor = .white
        webView.allowsBackForwardNavigationGestures = false
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url != url {
            var request = URLRequest(url: url)
            request.cachePolicy = .returnCacheDataElseLoad
            request.timeoutInterval = 30
            webView.load(request)
        }
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("📱 [WebView] Started loading: \(webView.url?.absoluteString ?? "unknown")")
            DispatchQueue.main.async {
                self.parent.isLoading = true
                self.parent.showError = false
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ [WebView] Finished loading: \(webView.url?.absoluteString ?? "unknown")")
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.showError = false
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ [WebView] Navigation failed: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.showError = true
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("❌ [WebView] Provisional navigation failed: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.showError = true
            }
        }
        
        func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

// MARK: - Error View
struct ErrorContentView: View {
    @Environment(\.appTheme) private var theme
    let message: String
    let onRetry: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundStyle(theme.colors.error.opacity(0.5))
            
            Text(message)
                .font(theme.typography.regular16)
                .foregroundStyle(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
            
            if let onRetry = onRetry {
                Button(action: onRetry) {
                    Text("Retry")
                        .font(theme.typography.medium16)
                        .foregroundStyle(.white)
                        .frame(width: 120, height: 44)
                        .background(theme.colors.primary)
                        .cornerRadius(8)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .padding(.horizontal, 40)
    }
}

// MARK: - Preview
#Preview {
    StaticPageView(pageType: .about)
        .environmentObject(Router.shared)
        .environment(\.appTheme, AppTheme.default)
}
