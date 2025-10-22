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
    public let name: String
    public let code: String
    public let phoneCode: String
    
    private enum CodingKeys: String, CodingKey {
        case id, name, code
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

public struct EmergencyContact: Codable {
    public let name: String
    public let phoneNumber: String
    public let relationship: String
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
    public let username: String
    public let role: UserType?
}

public struct UserProfile: Codable {
    public let firstName: String?
    public let lastName: String?
    public let avatar: String?
    public let phoneNumber: String?
}
