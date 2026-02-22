//
//  PharmacyModels.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 23/12/25.
//

import Foundation

// MARK: - Pharmacy Response Models

public struct PharmacyListResponse: Codable {
    public let success: Bool
    public let pharmacies: [Pharmacy]
    public let message: String?
}

public struct PharmacyResponse: Codable {
    public let success: Bool
    public let pharmacy: Pharmacy?
    public let message: String?
}

public struct PharmacyDetailResponse: Codable {
    public let success: Bool
    public let pharmacy: Pharmacy
    public let message: String?
}

// MARK: - Pharmacy Model

public struct Pharmacy: Codable, Identifiable, Hashable {
    public let id: Int
    public let name: String
    public let address: String?
    public let city: String?
    public let state: String?
    public let postalCode: String?
    public let country: String?
    public let phone: String?
    public let email: String?
    public let licenseNumber: String?
    public let isActive: Bool?
    public let isVerified: Bool?
    public let isAdminManaged: Bool?
    public let operatingHours: [String: String]?
    public let createdAt: String?
    public let updatedAt: String?
    
    private enum CodingKeys: String, CodingKey {
        case id, name, address, city, state, phone, email, country
        case postalCode = "postal_code"
        case licenseNumber = "license_number"
        case isActive = "is_active"
        case isVerified = "is_verified"
        case isAdminManaged = "is_admin_managed"
        case operatingHours = "operating_hours"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - CustomStringConvertible (required for DropdownField)
extension Pharmacy: CustomStringConvertible {
    public var description: String { name }
}
