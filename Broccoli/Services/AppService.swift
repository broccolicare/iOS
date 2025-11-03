//
//  AppService.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 13/10/25.
//

import Foundation

public protocol AppServiceProtocol {
    func fetchStaticPage(_ page: StaticPageType) async throws -> String
    func fetchCountryCodes() async throws -> [CountryCode]
    func fetchSpecializations() async throws -> [Specialization]
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
    
    public func fetchCountryCodes() async throws -> [CountryCode] {
        return try await handleServiceError {
            let endpoint = AppEndpoint.countrys
            return try await httpClient.request(endpoint)
        }
    }
    
    public func fetchSpecializations() async throws -> [Specialization] {
        return try await handleServiceError {
            let endpoint = AppEndpoint.specializations
            return try await httpClient.request(endpoint)
        }
    }
    
    public func fetchBanners() async throws -> [Specialization] {
        return try await handleServiceError {
            let endpoint = AppEndpoint.specializations
            return try await httpClient.request(endpoint)
        }
    }
}
