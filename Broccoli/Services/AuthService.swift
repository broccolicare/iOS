//
//  AuthService.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 07/10/25.
//

// Services/AuthService.swift
import Foundation
import GoogleSignIn
import FacebookLogin
import AuthenticationServices

public protocol AuthServiceProtocol {
    func signInWithGoogle() async throws -> String
    func signInWithFacebook() async throws -> String
    func signInWithApple() async throws -> String
    func signIn(email: String, password: String) async throws -> AuthResponse
    func signUp(request: SignUpRequest) async throws -> SignupResponse
    func refreshToken(refreshToken:String) async throws -> AuthResponse
    func verifyEmail(userId: String, otp: String) async throws -> AuthResponse
    func resendOtp(userId: String) async throws -> AuthResponse
    func signOut() async throws
}

public final class AuthService: BaseService, AuthServiceProtocol {
    private let httpClient: HTTPClientProtocol
    
    public init(httpClient: HTTPClientProtocol, secureStore: SecureStoreProtocol) {
        self.httpClient = httpClient
        super.init()
    }
    
    // MARK: - Public Methods
    
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
        // keep same behaviour as before (throw if not implemented)
        throw AuthError.notImplemented
    }
    
    public func signIn(email: String, password: String) async throws -> AuthResponse {
        return try await handleServiceError {
            let endpoint = AuthEndpoint.login(email: email, password: password)
            return try await httpClient.request(endpoint)
        }
    }
    
    public func signUp(request: SignUpRequest) async throws -> SignupResponse {
        return try await handleServiceError {
            let endpoint = AuthEndpoint.register(request: request)
            return try await httpClient.request(endpoint)
        }
    }
    
    public func refreshToken(refreshToken: String) async throws -> AuthResponse {
        return try await handleServiceError {
            let endpoint = AuthEndpoint.refreshToken(refreshToken: refreshToken)
            return try await httpClient.request(endpoint)
        }
    }
    
    public func verifyEmail(userId: String, otp: String) async throws -> AuthResponse {
        return try await handleServiceError {
            let endpoint = AuthEndpoint.verifyEmail(userId: userId, otp: otp)
            return try await httpClient.request(endpoint)
        }
    }
    
    public func resendOtp(userId: String) async throws -> AuthResponse {
        return try await handleServiceError {
            let endpoint = AuthEndpoint.resendOtp(userId: userId)
            return try await httpClient.request(endpoint)
        }
    }
    
    public func signOut() async throws {
        try await handleServiceErrorVoid {
            let endpoint = AuthEndpoint.logout
            let _: EmptyResponse = try await httpClient.request(endpoint)
        }
    }
}
