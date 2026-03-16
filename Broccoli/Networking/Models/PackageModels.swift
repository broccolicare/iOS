//
//  PackageModels.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 27/12/25.
//

import Foundation

// MARK: - Package Response Models

public struct PackagesResponse: Codable {
    public let data: [Package]
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
    public let slug: String
    public let price: String
    public let stripeProductId: String
    public let stripePriceId: String
    public let billingPeriod: String
    public let status: String
    public let isFeatured: Bool
    public let features: [PackageFeature]
    public let createdAt: String
    public let updatedAt: String
    
    private enum CodingKeys: String, CodingKey {
        case id, name, description, slug, price, status, features
        case stripeProductId = "stripe_product_id"
        case stripePriceId = "stripe_price_id"
        case billingPeriod = "billing_period"
        case isFeatured = "is_featured"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

public struct PackageFeature: Codable, Identifiable, Hashable {
    public let id: Int
    public let name: String
    public let description: String?
    public let featureType: String
    public let featureTypeLabel: String
    public let quantity: Int
    public let isUnlimited: Bool
    
    private enum CodingKeys: String, CodingKey {
        case id, name, description, quantity
        case featureType = "feature_type"
        case featureTypeLabel = "feature_type_label"
        case isUnlimited = "is_unlimited"
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

// MARK: - User Active Package (GET /user-packages)

public struct UserPackageResponse: Codable {
    public let success: Bool?
    public let package: UserPackage?
}

public struct UserPackage: Codable {
    public let id: Int
    public let name: String
    public let slug: String
    public let description: String?
    public let price: String
    public let billingPeriod: String
    public let isFeatured: Bool
    public let bgColor: String?
    public let stripePriceId: String
    public let stripeProductId: String
    public let subscriptionStatus: String
    public let subscriptionEndsAt: String?
    public let features: [UserPackageFeature]

    private enum CodingKeys: String, CodingKey {
        case id, name, slug, description, price, features
        case billingPeriod = "billing_period"
        case isFeatured = "is_featured"
        case bgColor = "bg_color"
        case stripePriceId = "stripe_price_id"
        case stripeProductId = "stripe_product_id"
        case subscriptionStatus = "subscription_status"
        case subscriptionEndsAt = "subscription_ends_at"
    }
}

public struct UserPackageFeature: Codable, Identifiable {
    public let id: Int
    public let name: String
    public let description: String?
    public let featureType: String
    public let isUnlimited: Bool
    public let quota: PackageQuota?

    private enum CodingKeys: String, CodingKey {
        case id, name, description, quota
        case featureType = "feature_type"
        case isUnlimited = "is_unlimited"
    }
}

public struct PackageQuota: Codable {
    public let monthlyLimit: Int
    public let used: Int
    public let remaining: Int

    private enum CodingKeys: String, CodingKey {
        case used, remaining
        case monthlyLimit = "monthly_limit"
    }
}
