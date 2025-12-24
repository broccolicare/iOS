//
//  UserEndpoint.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 23/12/25.
//

import Foundation

// MARK: - User Endpoints
public enum UserEndpoint: Endpoint {
    case profile
    case updateProfile([String: Any])
    case uploadAvatar(Data)
    
    public var path: String {
        switch self {
        case .profile: return "/account/me"
        case .updateProfile: return "/account/me"
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
