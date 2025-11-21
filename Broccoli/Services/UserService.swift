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
}
