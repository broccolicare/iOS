//
//  AuthEndpoint.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 23/12/25.
//

import Foundation

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
        case .login: return "/auth/login"
        case .socialLogin: return "/auth/social-login"
        case .register: return "/auth/register"
        case .refreshToken: return "/auth/refresh"
        case .logout: return "/account/logout"
        case .terms: return "/static/terms"
        case .privacy: return "/static/privacy"
        case .about: return "/static/about"
        case .verifyEmail: return "/auth/verify-email"
        case .verifyOtp: return "/auth/verify-otp"
        case .resendOtp: return "/auth/resend-otp"
        case .forgotPassword: return "/auth/forgot-password"
        case .resetPassword: return "/auth/reset-password"
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
