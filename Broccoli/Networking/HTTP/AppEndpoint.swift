//
//  AppEndpoint.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 23/12/25.
//

import Foundation

// MARK: - App Endpoints
public enum AppEndpoint: Endpoint {
    case staticPages(page: StaticPageType)
    case countrys
    case specializations
    case banners
    case metaData
    case medicalProcedures
    case medicalDestinations
    case recoveryDrugs
    case recoveryAddictionYears
    case allServices
    
    public var path: String {
        switch self {
        case .staticPages(let page):
            switch page {
            case .terms: return "/static/terms"
            case .privacy: return "/static/privacy"
            case .about: return "/static/about"
            }
        case .countrys: return "/global/country-calling-codes"
        case .specializations: return "/global/specializations"
        case .banners: return "/global/sliders"
        case .metaData: return "/global/meta-data"
            case .medicalProcedures: return "/global/medical-procedures"
        case .medicalDestinations: return "/global/medical-destinations"
        case .recoveryDrugs: return "/global/recovery-drugs"
        case .recoveryAddictionYears: return "/global/recovery-addiction-years"
        case .allServices: return "/global/services"
        }
    }
    
    public var method: HTTPMethod {
        switch self {
        case .staticPages, .countrys, .specializations, .banners, .metaData, .medicalProcedures, .medicalDestinations, .recoveryDrugs, .recoveryAddictionYears, .allServices: return .GET
        }
    }
    
    public var body: [String: Any]? {
        switch self {
        case .staticPages, .countrys, .specializations, .banners, .metaData, .medicalProcedures, .medicalDestinations, .recoveryDrugs, .recoveryAddictionYears, .allServices:
            return nil
        }
    }
}
