//
//  PackageService.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 27/12/25.
//

import Foundation

public protocol PackageServiceProtocol {
    func getPackages() async throws -> PackagesResponse
    func getServiceEligibility(serviceId: String) async throws -> PackageEligibilityResponse
    func initializeSubscriptionPayment(priceId: String, name: String) async throws -> PaymentInitializeResponse
    func confirmSubscriptionPayment(priceId: String, paymentMethodId: String, name: String) async throws -> PaymentConfirmResponse
}

public final class PackageService: BaseService, PackageServiceProtocol {
    private let httpClient: HTTPClientProtocol
    
    public init(httpClient: HTTPClientProtocol) {
        self.httpClient = httpClient
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Get list of available packages
    public func getPackages() async throws -> PackagesResponse {
        return try await handleServiceError {
            let endpoint = PackageEndpoint.getPackages
            return try await httpClient.request(endpoint)
        }
    }
    
    /// Get package eligibility for a specific service
    public func getServiceEligibility(serviceId: String) async throws -> PackageEligibilityResponse {
        return try await handleServiceError {
            let endpoint = PackageEndpoint.getServiceEligibility(serviceId: serviceId)
            return try await httpClient.request(endpoint)
        }
    }
    
    /// Initialize subscription payment for a package
    public func initializeSubscriptionPayment(priceId: String, name: String) async throws -> PaymentInitializeResponse {
        return try await handleServiceError {
            let endpoint = PackageEndpoint.initializeSubscriptionPayment(priceId: priceId, name: name)
            return try await httpClient.request(endpoint)
        }
    }
    
    /// Confirm subscription payment after successful payment
    public func confirmSubscriptionPayment(priceId: String, paymentMethodId: String, name: String) async throws -> PaymentConfirmResponse {
        return try await handleServiceError {
            let endpoint = PackageEndpoint.confirmSubscriptionPayment(priceId: priceId, paymentMethodId: paymentMethodId, name: name)
            return try await httpClient.request(endpoint)
        }
    }
}
