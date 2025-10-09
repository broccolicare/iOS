//
//  AuthService.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 07/10/25.
//

import Foundation
import Combine
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
    public let firstName: String
    public let lastName: String
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

public class AuthService: ObservableObject, AuthServiceProtocol {
    @Published public private(set) var isAuthenticated: Bool = false
    @Published public private(set) var currentUser: User? = nil

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
        await MainActor.run {
            self.isAuthenticated = false
            self.currentUser = nil
        }
    }

    @MainActor
    public func checkAuthenticationStatus() async {
        // Attempt to load existing credentials and set state accordingly
        do {
            if let token: String = try secureStore.retrieve(for: SecureStore.Keys.accessToken) {
                // In a real app, you might validate/refresh the token and fetch user profile here
                // For now, mark as authenticated if a token exists
                self.isAuthenticated = !token.isEmpty
                // Optionally, you may decode a cached user or fetch it. Leaving as nil until fetched.
            } else {
                self.isAuthenticated = false
                self.currentUser = nil
            }
        } catch {
            self.isAuthenticated = false
            self.currentUser = nil
        }
    }
}

public enum AuthError: Error {
    case noViewController
    case invalidToken
    case noRefreshToken
    case notImplemented
}

