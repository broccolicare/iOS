//
//  RequestResponseModels.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 14/10/25.
//

import Foundation

public enum ServiceError: Error, LocalizedError {
    case server(message: String)
    case unauthorized(message: String)
    case validation(message: String)
    case unknown(message: String)
    
    public var errorDescription: String? {
        switch self {
        case .server(let m): return m
        case .unauthorized(let m): return m
        case .validation(let m): return m
        case .unknown(let m): return m
        }
    }
}

public struct SignUpRequest: Codable {
    var name: String
    var username: String
    var email: String
    var gender: String
    var countryCode: String
    var phoneNumber: String
    var medicalLicenseNumber: String?
    var specializations: [String]?
    var description: String?
    var password: String
    var confirmPassword: String

    var userType: UserType

    func toDictionary() -> [String: Any?] {
        var dict: [String: Any?] = [
            "name": name,
            "username": username,
            "email": email,
            "gender": gender.lowercased(),
            "phone_code": countryCode,
            "phone": phoneNumber,
            "password": password,
            "password_confirmation": confirmPassword,
            "role": userType.rawValue,
            "medical_license_number": medicalLicenseNumber?.isEmpty == false ? medicalLicenseNumber : nil,
            "specializations": specializations?.isEmpty == false ? specializations : nil,
            "description": description?.isEmpty == false ? description : nil
        ]

        // Remove nil values
        dict = dict.filter { $0.value != nil }
        
        return dict
    }
}

public struct SignupResponse: Codable {
    public let token: String?
    public let message: String?
    public let user: User?
}
