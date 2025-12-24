//
//  MetadataModels.swift
//  Broccoli
//
//  Created by AI Assistant on 19/11/25.
//

import Foundation

// MARK: - Metadata Response
public struct MetadataResponse: Codable {
    public let status: Bool
    public let message: String
    public let data: MetadataData
}

public struct MetadataData: Codable {
    public let bloodGroups: [BloodGroup]
    public let allergyCategories: [AllergyCategory]
    public let allergies: [MetadataAllergy]
    public let genders: [Gender]
    
    private enum CodingKeys: String, CodingKey {
        case bloodGroups = "blood_groups"
        case allergyCategories = "allergy_categories"
        case allergies
        case genders
    }
}

// MARK: - Blood Group
public struct BloodGroup: Codable, Identifiable, Hashable {
    public let id: Int
    public let name: String
}

// MARK: - Allergy Category
public struct AllergyCategory: Codable, Identifiable, Hashable {
    public let id: Int
    public let name: String
}

// MARK: - Metadata Allergy (with category)
public struct MetadataAllergy: Codable, Identifiable, Hashable {
    public let id: Int
    public let name: String
    public let categoryId: Int
    public let category: AllergyCategory
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case categoryId = "category_id"
        case category
    }
}

// MARK: - Gender
public struct Gender: Codable, Hashable {
    public let value: String
    public let label: String
}

// MARK: - Slider
public struct Slider: Codable, Identifiable, Hashable {
    public let id: Int
    public let title: String
    public let imageUrl: String
    public let description: String?
    public let order: Int
    public let link: String?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case imageUrl = "image_url"
        case description
        case order
        case link
    }
}

// MARK: - Sliders Response
public struct SlidersResponse: Codable {
    public let success: Bool
    public let data: [Slider]
}
