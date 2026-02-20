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
    case contactUs([String: Any])
    case registerDeviceToken([String: Any])
    case notifications
    
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
        case .contactUs: return "/contact-us"
        case .registerDeviceToken: return "/device-tokens"
        case .notifications: return "/notifications"
        }
    }
    
    public var method: HTTPMethod {
        switch self {
        case .staticPages, .countrys, .specializations, .banners, .metaData, .medicalProcedures, .medicalDestinations, .recoveryDrugs, .recoveryAddictionYears, .allServices, .notifications: return .GET
        case .contactUs, .registerDeviceToken: return .POST
        }
    }
    
    public var body: [String: Any]? {
        switch self {
        case .staticPages, .countrys, .specializations, .banners, .metaData, .medicalProcedures, .medicalDestinations, .recoveryDrugs, .recoveryAddictionYears, .allServices, .notifications:
            return nil
        case .contactUs(let data):
            return data
        case .registerDeviceToken(let data):
            return data
        }
    }
}
