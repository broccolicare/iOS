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
    case medicalTourism([String: Any])
    case recoveryJourney([String: Any])
    
    public var path: String {
        switch self {
        case .profile: return "/account/me"
        case .updateProfile: return "/account/me"
        case .uploadAvatar: return "/account/avatar"
        case .medicalTourism: return "/medical-tourism"
        case .recoveryJourney: return "/recovery-journey"
        }
    }
    
    public var method: HTTPMethod {
        switch self {
        case .profile: return .GET
        case .updateProfile: return .PUT
        case .uploadAvatar, .medicalTourism, .recoveryJourney: return .POST
        
        }
    }
    
    public var body: [String: Any]? {
        switch self {
        case .profile: return nil
        case .updateProfile(let data): return data
        case .medicalTourism(let data): return data
        case .recoveryJourney(let data): return data
        case .uploadAvatar: return nil // Handle multipart/form-data separately
        }
    }
}
