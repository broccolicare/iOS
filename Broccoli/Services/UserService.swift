//
//  UserService.swift
//  Broccoli
//
//  Created on 11/11/25.
//

import Foundation

public protocol UserServiceProtocol {
    func fetchUserProfile() async throws -> UserProfileResponse
    func updateProfile(data: [String: Any]) async throws -> UserProfileResponse
    func uploadAvatar(imageData: Data) async throws -> UserProfileResponse
    func submitMedicalTourismEnquiry(request: MedicalTourismEnquiryRequest) async throws -> MedicalTourismEnquiryResponse
    func submitRecoveryJourneyEnquiry(request: RecoveryJourneyEnquiryRequest) async throws -> RecoveryJourneyEnquiryResponse
}

public final class UserService: BaseService, UserServiceProtocol {
    private let httpClient: HTTPClientProtocol
    
    public init(httpClient: HTTPClientProtocol) {
        self.httpClient = httpClient
        super.init()
    }
    
    // MARK: - Public Methods
    
    public func fetchUserProfile() async throws -> UserProfileResponse {
        return try await handleServiceError {
            let endpoint = UserEndpoint.profile
            return try await httpClient.request(endpoint)
        }
    }
    
    public func updateProfile(data: [String: Any]) async throws -> UserProfileResponse {
        return try await handleServiceError {
            let endpoint = UserEndpoint.updateProfile(data)
            return try await httpClient.request(endpoint)
        }
    }
    
    public func uploadAvatar(imageData: Data) async throws -> UserProfileResponse {
        return try await handleServiceError {
            let endpoint = UserEndpoint.uploadAvatar(imageData)
            return try await httpClient.request(endpoint)
        }
    }
    
    public func submitMedicalTourismEnquiry(request: MedicalTourismEnquiryRequest) async throws -> MedicalTourismEnquiryResponse {
        return try await handleServiceError {
            let endpoint = UserEndpoint.medicalTourism(request.toDictionary())
            return try await httpClient.request(endpoint)
        }
    }
    
    public func submitRecoveryJourneyEnquiry(request: RecoveryJourneyEnquiryRequest) async throws -> RecoveryJourneyEnquiryResponse {
        return try await handleServiceError {
            let endpoint = UserEndpoint.recoveryJourney(request.toDictionary())
            return try await httpClient.request(endpoint)
        }
    }
}
