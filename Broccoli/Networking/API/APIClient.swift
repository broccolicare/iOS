//
//  APIClient.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 07/10/25.
//

import Foundation

public protocol APIClientProtocol {
    func login(email: String, password: String) async throws -> AuthResponse
    func socialLogin(provider: String, token: String) async throws -> AuthResponse
    func register(email: String, password: String, userType: UserType) async throws -> AuthResponse
    func getUserProfile() async throws -> User
    func updateUserProfile(_ profile: UserProfile) async throws -> User
}

public class APIClient: APIClientProtocol {
    private let httpClient: HTTPClientProtocol
    private let secureStore: SecureStoreProtocol
    
    public init(httpClient: HTTPClientProtocol, secureStore: SecureStoreProtocol) {
        self.httpClient = httpClient
        self.secureStore = secureStore
    }
    
    public func login(email: String, password: String) async throws -> AuthResponse {
        let endpoint = AuthEndpoint.login(email: email, password: password)
        let response: AuthResponse = try await httpClient.request(endpoint)
        try await storeAuthTokens(response)
        return response
    }
    
    public func socialLogin(provider: String, token: String) async throws -> AuthResponse {
        let endpoint = AuthEndpoint.socialLogin(provider: provider, token: token)
        let response: AuthResponse = try await httpClient.request(endpoint)
        try await storeAuthTokens(response)
        return response
    }
    
    public func register(email: String, password: String, userType: UserType) async throws -> AuthResponse {
        let endpoint = AuthEndpoint.register(email: email, password: password, userType: userType.rawValue)
        let response: AuthResponse = try await httpClient.request(endpoint)
        try await storeAuthTokens(response)
        return response
    }
    
    public func getUserProfile() async throws -> User {
        let endpoint = UserEndpoint.profile
        return try await httpClient.request(endpoint)
    }
    
    public func updateUserProfile(_ profile: UserProfile) async throws -> User {
        let profileData: [String: Any] = [
            "firstName": profile.firstName ?? "",
            "lastName": profile.lastName ?? "",
            "phoneNumber": profile.phoneNumber ?? ""
        ]
        let endpoint = UserEndpoint.updateProfile(profileData)
        return try await httpClient.request(endpoint)
    }
    
    private func storeAuthTokens(_ response: AuthResponse) async throws {
        try secureStore.store(response.accessToken, for: SecureStore.Keys.accessToken)
        try secureStore.store(response.refreshToken, for: SecureStore.Keys.refreshToken)
        try secureStore.store(response.user.id, for: SecureStore.Keys.userID)
    }
}