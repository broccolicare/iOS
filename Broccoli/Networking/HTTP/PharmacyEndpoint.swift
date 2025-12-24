//
//  PharmacyEndpoint.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 23/12/25.
//

import Foundation

// MARK: - Pharmacy Endpoints
public enum PharmacyEndpoint: Endpoint {
    case searchPharmacies(query: String?)
    case createPharmacy([String: Any])
    case updatePharmacy(pharmacyId: String, data: [String: Any])
    case deletePharmacy(pharmacyId: String)
    case setDefaultPharmacy(pharmacyId: String)
    case getPharmacyDetails(pharmacyId: String)
    
    public var path: String {
        switch self {
        case .searchPharmacies:
            return "/pharmacies/search"
        case .createPharmacy:
            return "/pharmacies"
        case .updatePharmacy(let pharmacyId, _):
            return "/pharmacies/\(pharmacyId)"
        case .deletePharmacy(let pharmacyId):
            return "/pharmacies/\(pharmacyId)"
        case .setDefaultPharmacy(let pharmacyId):
            return "/pharmacies/\(pharmacyId)/set-default"
        case .getPharmacyDetails(let pharmacyId):
            return "/pharmacies/\(pharmacyId)"
        }
    }
    
    public var method: HTTPMethod {
        switch self {
        case .searchPharmacies, .getPharmacyDetails:
            return .GET
        case .createPharmacy, .setDefaultPharmacy:
            return .POST
        case .updatePharmacy:
            return .PUT
        case .deletePharmacy:
            return .DELETE
        }
    }
    
    public var body: [String: Any]? {
        switch self {
        case .createPharmacy(let data):
            return data
        case .updatePharmacy(_, let data):
            return data
        case .searchPharmacies, .deletePharmacy, .setDefaultPharmacy, .getPharmacyDetails:
            return nil
        }
    }
    
    public var queryItems: [String: String]? {
        switch self {
        case .searchPharmacies(let query):
            if let query = query, !query.isEmpty {
                return ["query": query]
            }
            return nil
        default:
            return nil
        }
    }
}
