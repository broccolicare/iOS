//
//  RequestResponseModels.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 14/10/25.
//

import Foundation

public enum ServiceError: Error, LocalizedError {
    case server(message: String)
    case unauthorized(message: String)
    case validation(message: String)
    case unknown(message: String)
    
    public var errorDescription: String? {
        switch self {
        case .server(let m): return m
        case .unauthorized(let m): return m
        case .validation(let m): return m
        case .unknown(let m): return m
        }
    }
}

public struct SignUpRequest: Codable {
    var name: String
    var username: String
    var email: String
    var gender: String
    var countryCode: String
    var phoneNumber: String
    var medicalLicenseNumber: String?
    var specializations: [Int]?
    var description: String?
    var password: String
    var confirmPassword: String

    var userType: UserType

    func toDictionary() -> [String: Any?] {
        var dict: [String: Any?] = [
            "name": name,
            "username": username,
            "email": email,
            "gender": gender.lowercased(),
            "phone_code": countryCode,
            "phone": phoneNumber,
            "password": password,
            "password_confirmation": confirmPassword,
            "role": userType.rawValue,
            "medical_license_number": medicalLicenseNumber?.isEmpty == false ? medicalLicenseNumber : nil,
            "specializations": specializations?.isEmpty == false ? specializations : nil,
            "description": description?.isEmpty == false ? description : nil
        ]

        // Remove nil values
        dict = dict.filter { $0.value != nil }
        
        return dict
    }
}

public struct SignupResponse: Codable {
    public let token: String?
    public let message: String?
    public let user: User?
}

// MARK: - Response Models
public struct TimeSlotsResponse: Codable {
    let success: Bool
    let date: String?
    let isGP: Int?
    let departmentId: String?
    let serviceId: String?
    let slots: TimeSlotsByPeriod?
    let pricing: PricingInfo?
    let minGapMinutes: Int?
    let message: String?
    
    private enum CodingKeys: String, CodingKey {
        case success, date, slots, pricing, message
        case isGP = "is_gp"
        case departmentId = "department_id"
        case serviceId = "service_id"
        case minGapMinutes = "min_gap_minutes"
    }
}

public struct TimeSlotsByPeriod: Codable {
    let morning: [TimeSlot]?
    let afternoon: [TimeSlot]?
    let evening: [TimeSlot]?
}

public struct TimeSlot: Codable, Identifiable {
    public var id: String { time }
    let time: String
    let displayTime: String
    let time24h: String
    let available: Bool
    let price: String?
    
    private enum CodingKeys: String, CodingKey {
        case time, available, price
        case displayTime = "display_time"
        case time24h = "time_24h"
    }
}

public struct PricingInfo: Codable {
    let type: String
    let currency: String
}

public struct BookingResponse: Codable {
    let success: Bool
    let booking: BookingData?
    let paymentIntent: String?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case booking
        case paymentIntent = "payment_intent"
        case message
    }
}

public struct BookingData: Codable, Hashable {
    let id: Int
    let userId: Int?
    let departmentId: Int?
    let serviceId: Int?
    let date: String
    let time: String
    let timeSlot: String?
    let amount: String?
    let status: String
    let paymentStatus: String?
    let paymentMethod: String?
    let stripePaymentIntentId: String?
    let createdAt: String?
    let updatedAt: String?
    let service: ServiceData?
    let department: DepartmentData?
    let user: UserData?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case departmentId = "department_id"
        case serviceId = "service_id"
        case date
        case time
        case timeSlot = "time_slot"
        case amount
        case status
        case paymentStatus = "payment_status"
        case paymentMethod = "payment_method"
        case stripePaymentIntentId = "stripe_payment_intent_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case service
        case department
        case user
    }
}

public struct ServiceData: Codable, Hashable {
    let id: Int
    let name: String
    let description: String?
    let price: String?
    let duration: Int?
    let departmentId: Int?
    let status: String?
    let billingType: String?
    let subscriptionRequired: Int?
    let requiresDoctor: Int?
    let bookableOnline: Int?
    let stripeProductId: String?
    let stripePriceId: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case price
        case duration
        case departmentId = "department_id"
        case status
        case billingType = "billing_type"
        case subscriptionRequired = "subscription_required"
        case requiresDoctor = "requires_doctor"
        case bookableOnline = "bookable_online"
        case stripeProductId = "stripe_product_id"
        case stripePriceId = "stripe_price_id"
    }
}

public struct DepartmentData: Codable, Hashable {
    let id: Int
    let name: String
    let code: String?
    let description: String?
    let status: String?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case code
        case description
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

public struct UserData: Codable, Hashable {
    let id: Int
    let name: String
    let email: String
    let username: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case username
    }
}

public struct BookingDetailResponse: Codable {
    let success: Bool
    let data: BookingDetail?
    let message: String?
}

public struct BookingDetail: Codable {
    let bookingId: String
    let patientName: String?
    let doctorName: String?
    let speciality: String?
    let appointmentDate: String?
    let appointmentTime: String?
    let status: String
    let notes: String?
    let documents: [String]?
}

public struct DocumentUploadResponse: Codable {
    let success: Bool
    let data: DocumentData?
    let message: String?
}

public struct DocumentData: Codable {
    let documentId: String
    let documentUrl: String
    let fileName: String
}

// MARK: - Payment Models

public struct PaymentInitializeResponse: Codable {
    let covered: Bool
    let message: String?
    let paymentIntent: PaymentIntentData?
    let ephemeralKey: EphemeralKeyData?
    let customer: CustomerData?
    let publishableKey: String?
    let amount: String?
    let currency: String?
    
    enum CodingKeys: String, CodingKey {
        case covered
        case message
        case paymentIntent
        case ephemeralKey
        case customer
        case publishableKey
        case amount
        case currency
    }
}

public struct PaymentIntentData: Codable {
    let clientSecret: String
    let id: String
}

public struct EphemeralKeyData: Codable {
    let secret: String
}

public struct CustomerData: Codable {
    let id: String
}

public struct PaymentConfirmResponse: Codable {
    let success: Bool
    let booking: BookingData?
    let message: String?
}
