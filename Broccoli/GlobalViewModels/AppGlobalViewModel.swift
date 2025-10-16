//
//  AppViewModel.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 13/10/25.
//


import Foundation
import Combine

@MainActor
public final class AppGlobalViewModel: ObservableObject {
    // Published UI state
    @Published public private(set) var htmlContent: String? = nil
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var errorMessage: String? = nil

    private let appService: AppServiceProtocol

    /// Simple in-memory cache for static pages (keeps previously fetched HTML).
    /// Keyed by StaticPageType.rawValue (or the enum itself if you prefer).
    private var cache: [StaticPageType: String] = [:]

    public init(appService: AppServiceProtocol) {
        self.appService = appService
    }

    /// Load content for the requested static page.
    /// - parameter useCache: whether to return cached content immediately (default true)
    public func load(page: StaticPageType, useCache: Bool = true) async {
        // If cached and allowed, return immediately
        if useCache, let cached = cache[page] {
            self.htmlContent = cached
            self.errorMessage = nil
            return
        }

        isLoading = true
        errorMessage = nil
        htmlContent = nil

        do {
            let html = try await appService.fetchStaticPage(page)
            cache[page] = html
            self.htmlContent = html
        } catch {
            // Convert to readable message
            self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isLoading = false
    }

    /// Force refresh from API ignoring cache
    public func refresh(page: StaticPageType) async {
        await load(page: page, useCache: false)
    }

    /// Clear the in-memory cache (useful for logout or language change)
    public func clearCache() {
        cache.removeAll()
    }
}
