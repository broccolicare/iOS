//
//  Models.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 07/10/25.
//

import Foundation


// MARK - Enums
public enum SignUpOrigin {
    case welcome
    case login
}

public enum OTPSource {
    case signup
    case forgotPassword
}

public enum UserType: String, CaseIterable, Codable {
    case patient = "patient"
    case doctor = "doctor"
}

public enum StaticPageType: String {
    case terms        = "terms"
    case privacy      = "privacy"
    case about        = "about"
    // add other pages as needed

    var title: String {
        switch self {
        case .terms: return "Terms & Conditions"
        case .privacy: return "Privacy Policy"
        case .about: return "About"
        }
    }
}

public enum AuthError: Error {
    case noViewController
    case invalidToken
    case noRefreshToken
    case notImplemented
}

// MARK: - API Models
public struct AuthResponse: Codable {
    public let token: String?
    public let refreshToken: String?
    public let user: User?
}

public struct EmptyResponse: Codable {}

// MARK: - Country Code Models
public struct CountryCode: Codable, Identifiable, Hashable {
    public let id: Int
    public let nicename: String
    public let phoneCode: String
    
    // Computed property for display name
    public var displayName: String {
        return nicename
    }
    
    // Computed property for phone code with + prefix
    public var formattedPhoneCode: String {
        return "+\(phoneCode)"
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, nicename
        case phoneCode = "phone_code"
    }
}

public struct CountryCodesResponse: Codable {
    public let data: [CountryCode]
    public let message: String?
}

// MARK: - Specialization Models
public struct Specialization: Codable, Identifiable, Hashable, CustomStringConvertible {
    public let id: Int
    public let name: String
    
    private enum CodingKeys: String, CodingKey {
        case id, name
    }
    
    // CustomStringConvertible conformance - this is what will be displayed in the dropdown
    public var description: String {
        return name
    }
}

public struct SpecializationsResponse: Codable {
    public let data: [Specialization]
    public let message: String?
}

// MARK: - Core Models
//public struct Appointment: Codable, Identifiable {
//    public let id: String
//    public let patientId: String
//    public let doctorId: String
//    public let scheduledDate: Date
//    public let duration: TimeInterval
//    public let status: AppointmentStatus
//    public let type: AppointmentType
//    public let notes: String?
//
//    public enum AppointmentStatus: String, Codable, CaseIterable {
//        case scheduled = "scheduled"
//        case inProgress = "in_progress"
//        case completed = "completed"
//        case cancelled = "cancelled"
//    }
//
//    public enum AppointmentType: String, Codable, CaseIterable {
//        case video = "video"
//        case audio = "audio"
//        case chat = "chat"
//    }
//}

public struct Doctor: Codable, Identifiable {
    public let id: String
    public let firstName: String
    public let lastName: String
    public let email: String
    public let specialization: String
    public let licenseNumber: String
    public let avatar: String?
    public let rating: Double
    public let yearsOfExperience: Int
    public let isAvailable: Bool
}

public struct Patient: Codable, Identifiable {
    public let id: String
    public let firstName: String
    public let lastName: String
    public let email: String
    public let dateOfBirth: Date
    public let gender: Gender
    public let avatar: String?
    public let emergencyContact: EmergencyContact?
    
    public enum Gender: String, Codable, CaseIterable {
        case male = "male"
        case female = "female"
        case other = "other"
    }
}


public struct MedicalRecord: Codable, Identifiable {
    public let id: String
    public let patientId: String
    public let doctorId: String
    public let diagnosis: String
    public let prescription: String?
    public let notes: String?
    public let createdDate: Date
    public let attachments: [String]
}

public struct Message: Codable, Identifiable {
    public let id: String
    public let senderId: String
    public let receiverId: String
    public let content: String
    public let timestamp: Date
    public let messageType: MessageType
    public let isRead: Bool
    
    public enum MessageType: String, Codable {
        case text = "text"
        case image = "image"
        case file = "file"
    }
}

public struct User: Codable {
    public let id: Int
    public let email: String
    public let name: String
    public let roles: [String]
    public let profile: UserProfile?
    
    // Computed property to get the primary role as UserType
    public var primaryRole: UserType? {
        guard let firstRole = roles.first else { return nil }
        return UserType(rawValue: firstRole)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, email, name, role, roles, profile
    }
    
    // Custom decoder to handle both "role" (string) and "roles" (array)
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        name = try container.decode(String.self, forKey: .name)
        profile = try container.decodeIfPresent(UserProfile.self, forKey: .profile)
        
        // Try to decode "roles" as array first (login API)
        if let rolesArray = try? container.decode([String].self, forKey: .roles) {
            roles = rolesArray
        }
        // If that fails, try to decode "role" as string (signup API)
        else if let roleString = try? container.decode(String.self, forKey: .role) {
            roles = [roleString]
        }
        // Fallback to empty array if neither exists
        else {
            roles = []
        }
    }
    
    // Custom encoder to always encode as "roles" array
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(name, forKey: .name)
        try container.encode(roles, forKey: .roles)
        try container.encodeIfPresent(profile, forKey: .profile)
    }
}

public struct UserProfile: Codable {
    public let phone: String?
    public let phoneCode: String?
    public let gender: String?
    public let dateOfBirth: String?
    public let address: String?
    public let city: String?
    public let state: String?
    public let country: String?
    public let postalCode: String?
    public let profileImage: String?
    public let description: String?
    public let medicalLicenseNumber: String?
    public let createdAt: String?
    public let updatedAt: String?
    public let bloodGroupId: Int?
    public let bloodGroup: String?
    
    private enum CodingKeys: String, CodingKey {
        case phone
        case phoneCode = "phone_code"
        case gender
        case dateOfBirth = "date_of_birth"
        case address
        case city
        case state
        case country
        case postalCode = "postal_code"
        case profileImage = "profile_image"
        case description
        case medicalLicenseNumber = "medical_license_number"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case bloodGroupId = "blood_group_id"
        case bloodGroup = "blood_group"
    }
}
