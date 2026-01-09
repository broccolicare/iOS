//
//  PackageModels.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 27/12/25.
//

import Foundation

// MARK: - Package Response Models

public struct PackagesResponse: Codable {
    public let success: Bool
    public let packages: [Package]
    public let message: String?
}

public struct PackageEligibilityResponse: Codable {
    public let success: Bool
    public let eligible: Bool
    public let message: String?
    public let packageDetails: PackageDetails?
    
    private enum CodingKeys: String, CodingKey {
        case success, eligible, message
        case packageDetails = "package_details"
    }
}

// MARK: - Package Model

public struct Package: Codable, Identifiable, Hashable {
    public let id: Int
    public let name: String
    public let description: String?
    public let price: String
    public let currency: String?
    public let billingPeriod: String?
    public let features: [String]
    public let isActive: Bool?
    public let createdAt: String?
    public let updatedAt: String?
    
    private enum CodingKeys: String, CodingKey {
        case id, name, description, price, currency, features
        case billingPeriod = "billing_period"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

public struct PackageDetails: Codable {
    public let id: Int
    public let name: String
    public let description: String?
    public let remainingServices: Int?
    
    private enum CodingKeys: String, CodingKey {
        case id, name, description
        case remainingServices = "remaining_services"
    }
}
