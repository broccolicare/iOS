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
    let serviceId: Int?
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
    let specialty: String?
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
    let success: Bool?
    let covered: Bool?
    let message: String?
    let paymentIntent: PaymentIntentData?
    let ephemeralKey: EphemeralKeyData?
    let customer: CustomerData?
    let publishableKey: String?
    let amount: String?
    let currency: String?
    
    // Alternative format for prescription payments (string format)
    let paymentIntentString: String?
    let ephemeralKeyString: String?
    let customerString: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case covered
        case message
        case paymentIntent
        case ephemeralKey
        case customer
        case publishableKey
        case amount
        case currency
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        success = try container.decodeIfPresent(Bool.self, forKey: .success)
        covered = try container.decodeIfPresent(Bool.self, forKey: .covered)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        publishableKey = try container.decodeIfPresent(String.self, forKey: .publishableKey)
        currency = try container.decodeIfPresent(String.self, forKey: .currency)
        
        // Handle amount as either String or Int
        if let amountString = try? container.decode(String.self, forKey: .amount) {
            amount = amountString
        } else if let amountInt = try? container.decode(Int.self, forKey: .amount) {
            amount = String(amountInt)
        } else if let amountDouble = try? container.decode(Double.self, forKey: .amount) {
            amount = String(format: "%.2f", amountDouble)
        } else {
            amount = nil
        }
        
        // Try to decode as objects first (booking format), then as strings (prescription format)
        if let paymentIntentObj = try? container.decode(PaymentIntentData.self, forKey: .paymentIntent) {
            paymentIntent = paymentIntentObj
            paymentIntentString = nil
        } else if let paymentIntentStr = try? container.decode(String.self, forKey: .paymentIntent) {
            paymentIntent = nil
            paymentIntentString = paymentIntentStr
        } else {
            paymentIntent = nil
            paymentIntentString = nil
        }
        
        if let ephemeralKeyObj = try? container.decode(EphemeralKeyData.self, forKey: .ephemeralKey) {
            ephemeralKey = ephemeralKeyObj
            ephemeralKeyString = nil
        } else if let ephemeralKeyStr = try? container.decode(String.self, forKey: .ephemeralKey) {
            ephemeralKey = nil
            ephemeralKeyString = ephemeralKeyStr
        } else {
            ephemeralKey = nil
            ephemeralKeyString = nil
        }
        
        if let customerObj = try? container.decode(CustomerData.self, forKey: .customer) {
            customer = customerObj
            customerString = nil
        } else if let customerStr = try? container.decode(String.self, forKey: .customer) {
            customer = nil
            customerString = customerStr
        } else {
            customer = nil
            customerString = nil
        }
    }
    
    // Helper to get client secret regardless of format
    var clientSecret: String? {
        return paymentIntent?.clientSecret ?? paymentIntentString
    }
    
    // Helper to get customer ID regardless of format
    var customerId: String? {
        return customer?.id ?? customerString
    }
    
    // Helper to get ephemeral key secret regardless of format
    var ephemeralKeySecret: String? {
        return ephemeralKey?.secret ?? ephemeralKeyString
    }
}

public struct PaymentIntentData: Codable {
    let clientSecret: String
    let id: String
}

public struct EphemeralKeyData: Codable {
    let secret: String
    
    private enum CodingKeys: String, CodingKey {
        case secret
    }
}

public struct CustomerData: Codable {
    let id: String
    
    private enum CodingKeys: String, CodingKey {
        case id
    }
}

public struct PaymentConfirmResponse: Codable {
    let success: Bool
    let booking: BookingData?
    let message: String?
}

// MARK: - Treatments Models

public struct TreatmentsResponse: Codable {
    public let success: Bool
    public let treatments: [Treatment]
    public let message: String?
}

public struct Treatment: Codable, Identifiable {
    public let id: Int
    public let name: String
    public let description: String?
    public let category: String?
    public let price: String?
    public let isActive: Bool
    public let requiresQuestionnaire: Bool?
    public let stripeProductId: String?
    public let createdAt: String?
    public let updatedAt: String?
    
    private enum CodingKeys: String, CodingKey {
        case id, name, description, category, price
        case isActive = "is_active"
        case requiresQuestionnaire = "requires_questionnaire"
        case stripeProductId = "stripe_product_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Services Models

public struct ServicesResponse: Codable {
    public let success: Bool
    public let department: DepartmentInfo
    public let data: [Service]
}

public struct DepartmentInfo: Codable {
    public let id: Int
    public let name: String
}

public struct Service: Codable, Identifiable {
    public let id: Int
    public let name: String
    public let description: String?
    public let price: String
    public let duration: Int
    public let requiresDoctor: Int
    public let subServices: [SubService]
    
    private enum CodingKeys: String, CodingKey {
        case id, name, description, price, duration
        case requiresDoctor = "requires_doctor"
        case subServices = "sub_services"
    }
}

public struct SubService: Codable, Identifiable {
    public let id: Int
    public let name: String
    public let description: String?
    public let price: String
    public let duration: Int
    
    private enum CodingKeys: String, CodingKey {
        case id, name, description, price, duration
    }
}

// MARK: - Questionnaire Models

public struct QuestionnaireResponse: Codable {
    public let success: Bool
    public let treatment: TreatmentWithQuestionnaire
}

public struct TreatmentWithQuestionnaire: Codable, Identifiable {
    public let id: Int
    public let name: String
    public let description: String?
    public let category: String?
    public let price: String?
    public let isActive: Bool
    public let requiresQuestionnaire: Bool?
    public let stripeProductId: String?
    public let createdAt: String?
    public let updatedAt: String?
    public let questionnaireGroups: [QuestionnaireGroup]
    
    private enum CodingKeys: String, CodingKey {
        case id, name, description, category, price
        case isActive = "is_active"
        case requiresQuestionnaire = "requires_questionnaire"
        case stripeProductId = "stripe_product_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case questionnaireGroups = "questionnaire_groups"
    }
}

public struct QuestionnaireGroup: Codable, Identifiable {
    public let id: Int
    public let treatmentId: Int
    public let title: String
    public let description: String?
    public let type: String
    public let order: Int
    public let isActive: Bool
    public let questions: [QuestionnaireQuestion]
    public let createdAt: String?
    public let updatedAt: String?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case treatmentId = "treatment_id"
        case title, description, type, order
        case isActive = "is_active"
        case questions
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

public struct QuestionnaireQuestion: Codable, Identifiable {
    public let id: Int
    public let questionnaireGroupId: Int
    public let questionText: String
    public let questionType: String // "multiple_choice", "single_choice", "text"
    public let isRequired: Bool
    public let order: Int
    public let validationRules: String?
    public let options: [QuestionOption]
    public let createdAt: String?
    public let updatedAt: String?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case questionnaireGroupId = "questionnaire_group_id"
        case questionText = "question_text"
        case questionType = "question_type"
        case isRequired = "is_required"
        case order
        case validationRules = "validation_rules"
        case options
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

public struct QuestionOption: Codable, Identifiable {
    public let id: Int
    public let questionId: Int
    public let optionText: String
    public let order: Int
    public let hasFollowUp: Bool
    
    private enum CodingKeys: String, CodingKey {
        case id
        case questionId = "question_id"
        case optionText = "option_text"
        case order
        case hasFollowUp = "has_follow_up"
    }
}

// MARK: - Prescription Order Models

public struct PrescriptionOrderRequest: Codable {
    public let treatmentId: Int
    public let answers: [PrescriptionAnswer]
    
    private enum CodingKeys: String, CodingKey {
        case treatmentId = "treatment_id"
        case answers
    }
}

public struct PrescriptionAnswer: Codable {
    public let questionId: Int
    public let answerText: String?
    public let selectedOptions: [Int]?
    
    private enum CodingKeys: String, CodingKey {
        case questionId = "question_id"
        case answerText = "answer_text"
        case selectedOptions = "selected_options"
    }
}

public struct PrescriptionOrderResponse: Codable {
    public let success: Bool
    public let message: String?
    public let requiresPayment: Bool
    public let promptAddPharmacy: Bool
    public let prescription: PrescriptionOrder?
    
    private enum CodingKeys: String, CodingKey {
        case success, message
        case requiresPayment = "requires_payment"
        case promptAddPharmacy = "prompt_add_pharmacy"
        case prescription
    }
}

public struct PrescriptionOrder: Codable, Identifiable {
    public let id: Int
    public let status: String
    public let paymentStatus: String
    public let amount: String
    public let validUntil: String
    public let notes: String?
    public let rejectionReason: String?
    public let createdAt: String
    public let updatedAt: String
    public let approvedAt: String?
    public let rejectedAt: String?
    public let assignedAt: String?
    public let sentAt: String?
    public let completedAt: String?
    public let treatment: Treatment
    public let answers: [PrescriptionAnswerDetail]
    
    private enum CodingKeys: String, CodingKey {
        case id, status, notes, treatment, answers
        case paymentStatus = "payment_status"
        case amount
        case validUntil = "valid_until"
        case rejectionReason = "rejection_reason"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case approvedAt = "approved_at"
        case rejectedAt = "rejected_at"
        case assignedAt = "assigned_at"
        case sentAt = "sent_at"
        case completedAt = "completed_at"
    }
}

public struct PrescriptionAnswerDetail: Codable, Identifiable {
    public let id: Int
    public let answerText: String
    public let option: String?
    public let answeredAt: String
    public let question: AnsweredQuestion
    
    private enum CodingKeys: String, CodingKey {
        case id
        case answerText = "answer_text"
        case option
        case answeredAt = "answered_at"
        case question
    }
}

public struct AnsweredQuestion: Codable, Identifiable {
    public let id: Int
    public let questionnaireGroupId: Int
    public let questionText: String
    public let questionType: String
    public let isRequired: Bool
    public let order: Int
    public let validationRules: String?
    public let createdAt: String?
    public let updatedAt: String?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case questionnaireGroupId = "questionnaire_group_id"
        case questionText = "question_text"
        case questionType = "question_type"
        case isRequired = "is_required"
        case order
        case validationRules = "validation_rules"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
