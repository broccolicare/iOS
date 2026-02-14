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
    func fetchMetaData() async throws -> MetadataResponse
    func fetchSlidersData() async throws -> SlidersResponse
    func fetchMedicalProcedures() async throws -> [MedicalProcedure]
    func fetchMedicalDestinations() async throws -> [MedicalDestination]
    func fetchRecoveryDrugs() async throws -> [RecoveryDrug]
    func fetchRecoveryAddictionYears() async throws -> [RecoveryAddictionYear]
    func fetchAllServices() async throws -> [Service]
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
    
    public func fetchMetaData() async throws -> MetadataResponse {
        return try await handleServiceError {
            let endpoint = AppEndpoint.metaData
            return try await httpClient.request(endpoint)
        }
    }
    
    public func fetchSlidersData() async throws -> SlidersResponse {
        return try await handleServiceError {
            let endpoint = AppEndpoint.banners
            return try await httpClient.request(endpoint)
        }
    }
    
    public func fetchMedicalProcedures() async throws -> [MedicalProcedure] {
        return try await handleServiceError {
            let endpoint = AppEndpoint.medicalProcedures
            let response: MedicalProceduresResponse = try await httpClient.request(endpoint)
            return response.data
        }
    }
    
    public func fetchMedicalDestinations() async throws -> [MedicalDestination] {
        return try await handleServiceError {
            let endpoint = AppEndpoint.medicalDestinations
            let response: MedicalDestinationsResponse = try await httpClient.request(endpoint)
            return response.data
        }
    }
    
    public func fetchRecoveryDrugs() async throws -> [RecoveryDrug] {
        return try await handleServiceError {
            let endpoint = AppEndpoint.recoveryDrugs
            let response: RecoveryDrugsResponse = try await httpClient.request(endpoint)
            return response.data
        }
    }
    
    public func fetchRecoveryAddictionYears() async throws -> [RecoveryAddictionYear] {
        return try await handleServiceError {
            let endpoint = AppEndpoint.recoveryAddictionYears
            let response: RecoveryAddictionYearsResponse = try await httpClient.request(endpoint)
            return response.data
        }
    }
    
    public func fetchAllServices() async throws -> [Service] {
        return try await handleServiceError {
            let endpoint = AppEndpoint.allServices
            let response: AllServicesResponse = try await httpClient.request(endpoint)
            return response.data
        }
    }
}
