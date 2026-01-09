//
//  UserProfileModels.swift
//  Broccoli
//
//  Created on 11/11/25.
//

import Foundation

// MARK: - User Profile API Response Models

public struct UserProfileResponse: Codable {
    public let status: Bool
    public let message: String
    public let data: UserProfileData
}

public struct UserProfileData: Codable {
    public let id: Int
    public let name: String
    public let email: String
    public let username: String
    public let roles: [String]
    public let profile: DetailedUserProfile?
    
    // Patient-specific fields
    public let medicalInfo: MedicalInfo?
    public let emergencyContact: EmergencyContact?
    public let allergies: [Allergy]?
    public let pendingAllergies: [Allergy]?
    public let insurances: [Insurance]?
    
    // Doctor-specific fields
    public let specialization: Specialization?
    public let licenseNumber: String?
    public let consultationFee: String?
    public let availableTimeSlots: String?
    
    private enum CodingKeys: String, CodingKey {
        case id, name, email, username, roles, profile, insurances, specialization
        case medicalInfo = "medical_info"
        case emergencyContact = "emergency_contact"
        case allergies
        case pendingAllergies = "pending_allergies"
        case licenseNumber = "license_number"
        case consultationFee = "consultation_fee"
        case availableTimeSlots = "available_time_slots"
    }
}

public struct DetailedUserProfile: Codable {
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
    public let bloodGroupId: Int?
    public let bloodGroup: String?
    
    private enum CodingKeys: String, CodingKey {
        case phone
        case phoneCode = "phone_code"
        case gender
        case dateOfBirth = "date_of_birth"
        case address, city, state, country
        case postalCode = "postal_code"
        case profileImage = "profile_image"
        case description
        case bloodGroupId = "blood_group_id"
        case bloodGroup = "blood_group"
    }
}

public struct MedicalInfo: Codable {
    public let bloodPressure: String?
    public let heartRate: String?
    public let bloodSugarLevel: String?
    public let heightCm: String?
    public let weightKg: String?
    public let knownConditions: String?
    public let medications: String?
    public let surgeries: String?
    public let familyHistory: String?
    public let allergies: String?
    
    private enum CodingKeys: String, CodingKey {
        case bloodPressure = "blood_pressure"
        case heartRate = "heart_rate"
        case bloodSugarLevel = "blood_sugar_level"
        case heightCm = "height_cm"
        case weightKg = "weight_kg"
        case knownConditions = "known_conditions"
        case medications, surgeries, allergies
        case familyHistory = "family_history"
    }
}

public struct Allergy: Codable, Identifiable {
    public let id: Int
    public let name: String
    public let severity: String?
    public let notes: String?
}

public struct Insurance: Codable, Identifiable {
    public let id: Int?
    public let providerName: String
    public let policyNumber: String
    public let planName: String?
    public let coverageAmount: String?
    public let coverageStartDate: String?
    public let coverageEndDate: String?
    public let relationship: String?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case providerName = "provider_name"
        case policyNumber = "policy_number"
        case planName = "plan_name"
        case coverageAmount = "coverage_amount"
        case coverageStartDate = "coverage_start_date"
        case coverageEndDate = "coverage_end_date"
        case relationship
    }
}

public struct EmergencyContact: Codable {
    public let name: String?
    public let phone: String?
    public let relationship: String?
}
