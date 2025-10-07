//
//  AuthService.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 07/10/25.
//

import Foundation
import GoogleSignIn
import FacebookLogin
import AuthenticationServices

public protocol AuthServiceProtocol {
    func signInWithGoogle() async throws -> String
    func signInWithFacebook() async throws -> String
    func signInWithApple() async throws -> String
    func signIn(email: String, password: String) async throws -> AuthResponse
    func signUp(email: String, password: String, userType: UserType) async throws -> AuthResponse
    func refreshToken() async throws -> AuthResponse
    func signOut() async throws
}

public enum UserType: String, CaseIterable, Codable {
    case patient = "patient"
    case doctor = "doctor"
}

public struct AuthResponse: Codable {
    public let accessToken: String
    public let refreshToken: String
    public let user: User
}

public struct User: Codable {
    public let id: String
    public let email: String
    public let userType: UserType
    public let profile: UserProfile?
}

public struct UserProfile: Codable {
    public let firstName: String?
    public let lastName: String?
    public let avatar: String?
    public let phoneNumber: String?
}

public struct EmptyResponse: Codable {}

public class AuthService: AuthServiceProtocol {
    private let httpClient: HTTPClientProtocol
    private let secureStore: SecureStoreProtocol
    
    public init(httpClient: HTTPClientProtocol, secureStore: SecureStoreProtocol) {
        self.httpClient = httpClient
        self.secureStore = secureStore
    }
    
    public func signInWithGoogle() async throws -> String {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let presentingViewController = windowScene.windows.first?.rootViewController else {
            throw AuthError.noViewController
        }
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.invalidToken
        }
        
        return idToken
    }
    
    public func signInWithFacebook() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let loginManager = LoginManager()
            loginManager.logIn(permissions: ["email"], from: nil) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let result = result, !result.isCancelled,
                      let token = AccessToken.current?.tokenString else {
                    continuation.resume(throwing: AuthError.invalidToken)
                    return
                }
                
                continuation.resume(returning: token)
            }
        }
    }
    
    public func signInWithApple() async throws -> String {
        // Implementation for Apple Sign In
        throw AuthError.notImplemented
    }
    
    public func signIn(email: String, password: String) async throws -> AuthResponse {
        let endpoint = AuthEndpoint.login(email: email, password: password)
        return try await httpClient.request(endpoint)
    }
    
    public func signUp(email: String, password: String, userType: UserType) async throws -> AuthResponse {
        let endpoint = AuthEndpoint.register(email: email, password: password, userType: userType.rawValue)
        return try await httpClient.request(endpoint)
    }
    
    public func refreshToken() async throws -> AuthResponse {
        guard let refreshToken = try secureStore.retrieve(for: SecureStore.Keys.refreshToken) else {
            throw AuthError.noRefreshToken
        }
        
        let endpoint = AuthEndpoint.refreshToken(refreshToken: refreshToken)
        return try await httpClient.request(endpoint)
    }
    
    public func signOut() async throws {
        let endpoint = AuthEndpoint.logout
        let _: EmptyResponse = try await httpClient.request(endpoint)
        try secureStore.clear()
    }
}

public enum AuthError: Error {
    case noViewController
    case invalidToken
    case noRefreshToken
    case notImplemented
}
