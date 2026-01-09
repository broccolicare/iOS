//
//  PackageEndpoint.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 27/12/25.
//

import Foundation

// MARK: - Package Endpoints
public enum PackageEndpoint: Endpoint {
    case getPackages
    case getServiceEligibility(serviceId: String)
    case initializeSubscriptionPayment(priceId: String, name: String)
    case confirmSubscriptionPayment(priceId: String, paymentMethodId: String, name: String)
    case paymentInitialize([String: Any])
    case paymentConfirm([String: Any])
    
    public var path: String {
        switch self {
        case .getPackages:
            return "/packages"
        case .getServiceEligibility(let serviceId):
            return "/packages/services/\(serviceId)/eligibility"
        case .initializeSubscriptionPayment:
            return "/payments/subscriptions/initialize"
        case .confirmSubscriptionPayment:
            return "/payments/subscriptions/confirm"
        case .paymentInitialize:
            return "/payments/bookings/initialize"
        case .paymentConfirm:
            return "/payments/bookings/confirm"
        }
    }
    
    public var method: HTTPMethod {
        switch self {
        case .getPackages, .getServiceEligibility:
            return .GET
        case .initializeSubscriptionPayment, .confirmSubscriptionPayment, .paymentInitialize, .paymentConfirm:
            return .POST
        }
    }
    
    public var body: [String: Any]? {
        switch self {
        case .getPackages, .getServiceEligibility:
            return nil
        case .initializeSubscriptionPayment(let priceId, let name):
            return [
                "price_id": priceId,
                "name": name
            ]
        case .confirmSubscriptionPayment(let priceId, let paymentMethodId, let name):
            return [
                "price_id": priceId,
                "payment_method_id": paymentMethodId,
                "name": name
            ]
        case .paymentInitialize(let data):
            return data
        case .paymentConfirm(let data):
            return data
        }
    }
}
