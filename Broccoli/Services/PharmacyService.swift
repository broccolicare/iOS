//
//  PharmacyService.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 23/12/25.
//

import Foundation

public protocol PharmacyServiceProtocol {
    func searchPharmacies(query: String?) async throws -> PharmacyListResponse
    func createPharmacy(data: [String: Any]) async throws -> PharmacyResponse
    func updatePharmacy(pharmacyId: String, data: [String: Any]) async throws -> PharmacyResponse
    func deletePharmacy(pharmacyId: String) async throws -> PharmacyResponse
    func setDefaultPharmacy(pharmacyId: String) async throws -> PharmacyResponse
    func getPharmacyDetails(pharmacyId: String) async throws -> PharmacyDetailResponse
}

public final class PharmacyService: BaseService, PharmacyServiceProtocol {
    private let httpClient: HTTPClientProtocol
    
    public init(httpClient: HTTPClientProtocol) {
        self.httpClient = httpClient
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Search pharmacies with optional query
    public func searchPharmacies(query: String?) async throws -> PharmacyListResponse {
        return try await handleServiceError {
            let endpoint = PharmacyEndpoint.searchPharmacies(query: query)
            return try await httpClient.request(endpoint)
        }
    }
    
    /// Create a new pharmacy
    public func createPharmacy(data: [String: Any]) async throws -> PharmacyResponse {
        return try await handleServiceError {
            let endpoint = PharmacyEndpoint.createPharmacy(data)
            return try await httpClient.request(endpoint)
        }
    }
    
    /// Update an existing pharmacy
    public func updatePharmacy(pharmacyId: String, data: [String: Any]) async throws -> PharmacyResponse {
        return try await handleServiceError {
            let endpoint = PharmacyEndpoint.updatePharmacy(pharmacyId: pharmacyId, data: data)
            return try await httpClient.request(endpoint)
        }
    }
    
    /// Delete a pharmacy
    public func deletePharmacy(pharmacyId: String) async throws -> PharmacyResponse {
        return try await handleServiceError {
            let endpoint = PharmacyEndpoint.deletePharmacy(pharmacyId: pharmacyId)
            return try await httpClient.request(endpoint)
        }
    }
    
    /// Set a pharmacy as default
    public func setDefaultPharmacy(pharmacyId: String) async throws -> PharmacyResponse {
        return try await handleServiceError {
            let endpoint = PharmacyEndpoint.setDefaultPharmacy(pharmacyId: pharmacyId)
            return try await httpClient.request(endpoint)
        }
    }
    
    /// Get pharmacy details by ID
    public func getPharmacyDetails(pharmacyId: String) async throws -> PharmacyDetailResponse {
        return try await handleServiceError {
            let endpoint = PharmacyEndpoint.getPharmacyDetails(pharmacyId: pharmacyId)
            return try await httpClient.request(endpoint)
        }
    }
}
