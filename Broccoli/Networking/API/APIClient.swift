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
    func register(request: SignUpRequest) async throws -> SignupResponse
    func getUserProfile() async throws -> User
    func updateUserProfile(_ profile: UserProfile) async throws -> User
}

public enum APIClientError: Error {
    case missingAccessToken
    case missingRefreshToken
    case missingUserID
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
//        try await storeAuthTokens(response)
        return response
    }
    
    public func socialLogin(provider: String, token: String) async throws -> AuthResponse {
        let endpoint = AuthEndpoint.socialLogin(provider: provider, token: token)
        let response: AuthResponse = try await httpClient.request(endpoint)
//        try await storeAuthTokens(response)
        return response
    }
    
    public func register(request: SignUpRequest) async throws -> SignupResponse {
        let endpoint = AuthEndpoint.register(request: request)
        let response: SignupResponse = try await httpClient.request(endpoint)
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
    
    private func storeAuthTokens(_ response: SignupResponse) async throws {
        guard let accessToken = response.token, !accessToken.isEmpty else {
            throw APIClientError.missingAccessToken
        }
        
        guard let userID = response.user?.id else {
            throw APIClientError.missingUserID
        }

        try secureStore.store(accessToken, for: SecureStore.Keys.accessToken)
//        try secureStore.store(refreshToken, for: SecureStore.Keys.refreshToken)
        try secureStore.store("\(userID)", for: SecureStore.Keys.userID)
    }
}

