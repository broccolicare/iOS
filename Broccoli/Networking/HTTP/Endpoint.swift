//
//  Endpoint.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 07/10/25.
//

import Foundation

public protocol Endpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var queryItems: [String: String]? { get }
    var body: [String: Any]? { get }
}

public extension Endpoint {
    var headers: [String: String]? { nil }
    var queryItems: [String: String]? { nil }
    var body: [String: Any]? { nil }
}

// MARK: - Auth Endpoints
public enum AuthEndpoint: Endpoint {
    case login(email: String, password: String)
    case socialLogin(provider: String, token: String)
    case register(request: SignUpRequest)
    case refreshToken(refreshToken: String)
    case terms
    case privacy
    case about
    case logout
    case verifyEmail(userId: String, otp: String)
    case verifyOtp(email: String, otp: String)
    case resendOtp(userId: String)
    case forgotPassword(email: String)
    case resetPassword(email: String, otp: String, newPassword: String, confirmPassword: String)
    
    public var path: String {
        switch self {
        case .login: return "/login"
        case .socialLogin: return "/auth/social-login"
        case .register: return "/register"
        case .refreshToken: return "/auth/refresh"
        case .logout: return "/logout"
        case .terms: return "/static/terms"
        case .privacy: return "/static/privacy"
        case .about: return "/static/about"
        case .verifyEmail: return "/verify-email"
        case .verifyOtp: return "/verify-otp"
        case .resendOtp: return "/resend-otp"
        case .forgotPassword: return "/forgot-password"
        case .resetPassword: return "/reset-password"
            
        }
    }
    
    public var method: HTTPMethod {
        switch self {
        case .login, .socialLogin, .register, .refreshToken, .logout, .verifyEmail, .resendOtp, .forgotPassword, .resetPassword, .verifyOtp:
            return .POST
        case .terms, .privacy, .about:
            return .GET
        }
    }
    
    public var body: [String: Any]? {
        switch self {
        case .login(let email, let password):
            return ["email": email, "password": password]
        case .socialLogin(let provider, let token):
            return ["provider": provider, "token": token]
        case .register(let request):
            return request.toDictionary() as [String : Any]
        case .refreshToken(let refreshToken):
            return ["refreshToken": refreshToken]
        case .logout, .terms, .privacy, .about:
            return nil
        case .verifyEmail(userId: let userId, otp: let otp):
            return ["user_id": userId, "otp": otp]
        case .resendOtp(userId: let userId):
            return ["user_id": userId]
        case .forgotPassword(email: let email):
            return ["email": email]
        case .resetPassword(email: let email, otp: let otp, newPassword: let newPassword, confirmPassword: let confirmPassword):
            return ["email": email, "otp": otp, "password": newPassword, "password_confirmation": confirmPassword]
        case .verifyOtp(email: let email, otp: let otp):
            return ["email": email, "otp": otp]
        }
    }
}

// MARK: - User Endpoints
public enum UserEndpoint: Endpoint {
    case profile
    case updateProfile([String: Any])
    case uploadAvatar(Data)
    
    public var path: String {
        switch self {
        case .profile, .updateProfile: return "/user/profile"
        case .uploadAvatar: return "/user/avatar"
        }
    }
    
    public var method: HTTPMethod {
        switch self {
        case .profile: return .GET
        case .updateProfile: return .PUT
        case .uploadAvatar: return .POST
        }
    }
    
    public var body: [String: Any]? {
        switch self {
        case .profile: return nil
        case .updateProfile(let data): return data
        case .uploadAvatar: return nil // Handle multipart/form-data separately
        }
    }
}

// MARK: - App Endpoints

public enum AppEndpoint: Endpoint {
    case staticPages(page: StaticPageType)
    case countrys
    case specializations
    case banners
    
    public var path: String {
        switch self {
        case .staticPages(let page):
            switch page {
            case .terms: return "/static/terms"
            case .privacy: return "/static/privacy"
            case .about: return "/static/about"
            }
        case .countrys: return "/countries"
        case .specializations: return "/specializations"
        case .banners: return "/sliders"
        }
    }
    
    public var method: HTTPMethod {
        switch self {
        case .staticPages, .countrys, .specializations, .banners: return .GET
        }
    }
    
    public var body: [String: Any]? {
        switch self {
        case .staticPages, .countrys, .specializations, .banners:
            return nil
        }
    }
}
