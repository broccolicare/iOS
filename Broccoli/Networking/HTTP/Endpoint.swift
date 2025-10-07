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
    case register(email: String, password: String, userType: String)
    case refreshToken(refreshToken: String)
    case logout
    
    public var path: String {
        switch self {
        case .login: return "/auth/login"
        case .socialLogin: return "/auth/social-login"
        case .register: return "/auth/register"
        case .refreshToken: return "/auth/refresh"
        case .logout: return "/auth/logout"
        }
    }
    
    public var method: HTTPMethod {
        switch self {
        case .login, .socialLogin, .register, .refreshToken, .logout:
            return .POST
        }
    }
    
    public var body: [String: Any]? {
        switch self {
        case .login(let email, let password):
            return ["email": email, "password": password]
        case .socialLogin(let provider, let token):
            return ["provider": provider, "token": token]
        case .register(let email, let password, let userType):
            return ["email": email, "password": password, "userType": userType]
        case .refreshToken(let refreshToken):
            return ["refreshToken": refreshToken]
        case .logout:
            return nil
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