//
//  AppService.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 13/10/25.
//

import Foundation

public protocol AppServiceProtocol {
    /// Fetch HTML content for static pages (terms/privacy/about).
    /// Returns raw HTML string (may contain <style> tags).
    func fetchStaticPage(_ page: StaticPageType) async throws -> String

    // Add other app-wide API functions here later.
}

public final class AppService: BaseService, AppServiceProtocol {
    private let httpClient: HTTPClientProtocol
    
    public init(httpClient: HTTPClientProtocol) {
        self.httpClient = httpClient
    }
    
    public func fetchStaticPage(_ page: StaticPageType) async throws -> String {
        return try await handleServiceError {
            let endpoint = AppEndpoint.staticPages(page: page)
            return try await httpClient.request(endpoint)
        }
    }
}
