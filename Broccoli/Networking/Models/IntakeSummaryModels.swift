//
//  IntakeSummaryModels.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 01/09/26.
//

import Foundation

public struct IntakeSummaryResponse: Codable {
    let success: Bool
    let data: IntakeSummaryData?
    let message: String?
}

public struct IntakeSummaryData: Codable {
    let status: String
    let summary: IntakeSummaryDetails?
    let conversation: IntakeSummaryConversation?
    let transcript: String?
}

public struct IntakeSummaryDetails: Codable {
    let chiefComplaint: String?
    let historyOfPresentIllness: String?
    let pain: IntakeSummaryPain?
    let medications: [String]?
    let allergies: IntakeSummaryAllergies?
    let relevantHistory: [String]?
    let familyHistory: [String]?
    let lifestyle: IntakeSummaryLifestyle?
    let pregnancy: String?
    let flags: [String]?

    enum CodingKeys: String, CodingKey {
        case chiefComplaint = "chief_complaint"
        case historyOfPresentIllness = "history_of_present_illness"
        case pain
        case medications
        case allergies
        case relevantHistory = "relevant_history"
        case familyHistory = "family_history"
        case lifestyle
        case pregnancy
        case flags
    }
}

public struct IntakeSummaryPain: Codable {
    let present: Bool?
    let severity: String?
    let location: String?
    let character: String?
    let onset: String?

    enum CodingKeys: String, CodingKey {
        case present
        case severity
        case location
        case character
        case onset
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        present = try container.decodeIfPresent(Bool.self, forKey: .present)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        character = try container.decodeIfPresent(String.self, forKey: .character)
        onset = try container.decodeIfPresent(String.self, forKey: .onset)

        // The API sometimes returns severity as a number (e.g. 6) and sometimes as a string.
        if let severityInt = try? container.decodeIfPresent(Int.self, forKey: .severity) {
            severity = String(severityInt)
        } else if let severityDouble = try? container.decodeIfPresent(Double.self, forKey: .severity) {
            severity = String(severityDouble)
        } else {
            severity = try container.decodeIfPresent(String.self, forKey: .severity)
        }
    }
}

public struct IntakeSummaryAllergies: Codable {
    let status: String?
    let items: [String]?
}

public struct IntakeSummaryLifestyle: Codable {
    let smoking: String?
    let alcohol: String?
    let notes: String?
}

public struct IntakeSummaryConversation: Codable {
    let id: Int
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
    }
}
