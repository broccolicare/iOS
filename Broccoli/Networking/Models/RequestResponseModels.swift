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
    var specialization_id: Int?
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
            "specialization_id": specialization_id,
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
    let slots: TimeSlotsByPeriod?
    let pricing: PricingInfo?
    let minGapMinutes: Int?
    let service: ServiceInfo?
    let department: DepartmentInfo?
    let message: String?
    
    private enum CodingKeys: String, CodingKey {
        case success, date, slots, pricing, service, department, message
        case minGapMinutes = "min_gap_minutes"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            success = try container.decode(Bool.self, forKey: .success)
        } catch {
            print("❌ [TimeSlotsResponse] Failed to decode 'success': \(error)")
            throw error
        }
        
        date = try? container.decode(String.self, forKey: .date)
        
        do {
            slots = try container.decodeIfPresent(TimeSlotsByPeriod.self, forKey: .slots)
        } catch {
            print("❌ [TimeSlotsResponse] Failed to decode 'slots': \(error)")
            slots = nil
        }
        
        do {
            pricing = try container.decodeIfPresent(PricingInfo.self, forKey: .pricing)
        } catch {
            print("❌ [TimeSlotsResponse] Failed to decode 'pricing': \(error)")
            pricing = nil
        }
        
        do {
            service = try container.decodeIfPresent(ServiceInfo.self, forKey: .service)
        } catch {
            print("❌ [TimeSlotsResponse] Failed to decode 'service': \(error)")
            service = nil
        }
        
        do {
            department = try container.decodeIfPresent(DepartmentInfo.self, forKey: .department)
        } catch {
            print("❌ [TimeSlotsResponse] Failed to decode 'department': \(error)")
            department = nil
        }
        
        minGapMinutes = try? container.decode(Int.self, forKey: .minGapMinutes)
        message = try? container.decode(String.self, forKey: .message)
    }
}

public struct TimeSlotsByPeriod: Codable {
    let morning: [TimeSlot]?
    let afternoon: [TimeSlot]?
    let evening: [TimeSlot]?
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            morning = try container.decodeIfPresent([TimeSlot].self, forKey: .morning)
        } catch {
            print("❌ [TimeSlotsByPeriod] Failed to decode 'morning': \(error)")
            morning = []
        }
        
        do {
            afternoon = try container.decodeIfPresent([TimeSlot].self, forKey: .afternoon)
        } catch {
            print("❌ [TimeSlotsByPeriod] Failed to decode 'afternoon': \(error)")
            afternoon = []
        }
        
        do {
            evening = try container.decodeIfPresent([TimeSlot].self, forKey: .evening)
        } catch {
            print("❌ [TimeSlotsByPeriod] Failed to decode 'evening': \(error)")
            evening = []
        }
    }
}

public struct ServiceInfo: Codable {
    let id: Int
    let code: String
    let name: String
    let price: String
    let duration: Int
    let specialization: SpecializationInfo?
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            id = try container.decode(Int.self, forKey: .id)
        } catch {
            print("❌ [ServiceInfo] Failed to decode 'id': \(error)")
            throw error
        }
        
        do {
            code = try container.decode(String.self, forKey: .code)
        } catch {
            print("❌ [ServiceInfo] Failed to decode 'code': \(error)")
            throw error
        }
        
        do {
            name = try container.decode(String.self, forKey: .name)
        } catch {
            print("❌ [ServiceInfo] Failed to decode 'name': \(error)")
            throw error
        }
        
        do {
            price = try container.decode(String.self, forKey: .price)
        } catch {
            print("❌ [ServiceInfo] Failed to decode 'price': \(error)")
            throw error
        }
        
        do {
            duration = try container.decode(Int.self, forKey: .duration)
        } catch {
            print("❌ [ServiceInfo] Failed to decode 'duration': \(error)")
            throw error
        }
        
        do {
            specialization = try container.decodeIfPresent(SpecializationInfo.self, forKey: .specialization)
        } catch {
            print("❌ [ServiceInfo] Failed to decode 'specialization': \(error)")
            specialization = nil
        }
    }
}

public struct SpecializationInfo: Codable {
    let id: Int
    let code: String
    let name: String
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            id = try container.decode(Int.self, forKey: .id)
        } catch {
            print("❌ [SpecializationInfo] Failed to decode 'id': \(error)")
            throw error
        }
        
        do {
            code = try container.decode(String.self, forKey: .code)
        } catch {
            print("❌ [SpecializationInfo] Failed to decode 'code': \(error)")
            throw error
        }
        
        do {
            name = try container.decode(String.self, forKey: .name)
        } catch {
            print("❌ [SpecializationInfo] Failed to decode 'name': \(error)")
            throw error
        }
    }
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
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            time = try container.decode(String.self, forKey: .time)
        } catch {
            print("❌ [TimeSlot] Failed to decode 'time': \(error)")
            throw error
        }
        
        do {
            displayTime = try container.decode(String.self, forKey: .displayTime)
        } catch {
            print("❌ [TimeSlot] Failed to decode 'display_time': \(error)")
            throw error
        }
        
        do {
            time24h = try container.decode(String.self, forKey: .time24h)
        } catch {
            print("❌ [TimeSlot] Failed to decode 'time_24h': \(error)")
            throw error
        }
        
        do {
            available = try container.decode(Bool.self, forKey: .available)
        } catch {
            print("❌ [TimeSlot] Failed to decode 'available': \(error)")
            throw error
        }
        
        price = try? container.decode(String.self, forKey: .price)
    }
}

public struct PricingInfo: Codable {
    let type: String
    let currency: String
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            type = try container.decode(String.self, forKey: .type)
        } catch {
            print("❌ [PricingInfo] Failed to decode 'type': \(error)")
            throw error
        }
        
        do {
            currency = try container.decode(String.self, forKey: .currency)
        } catch {
            print("❌ [PricingInfo] Failed to decode 'currency': \(error)")
            throw error
        }
    }
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

public struct UpcomingAppointmentsResponse: Codable {
    let success: Bool
    let data: [BookingData]
    let pagination: PaginationInfo
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case data
        case pagination
        case message
    }
    
    // Computed properties for easy access
    var bookings: [BookingData] { data }
    var currentPage: Int { pagination.currentPage }
    var lastPage: Int { pagination.lastPage }
    var perPage: Int { pagination.perPage }
    var total: Int { pagination.total }
}

public struct PaginationInfo: Codable {
    let currentPage: Int
    let lastPage: Int
    let perPage: Int
    let total: Int
    let from: Int?
    let to: Int?
    
    enum CodingKeys: String, CodingKey {
        case currentPage = "current_page"
        case lastPage = "last_page"
        case perPage = "per_page"
        case total
        case from
        case to
    }
}

public struct PendingBookingsResponse: Codable {
    let success: Bool
    let bookings: [BookingData]
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case bookings
        case message
    }
}

public struct MyBookingsResponse: Codable {
    let success: Bool
    let bookings: MyBookingsPaginatedData
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case bookings
        case message
    }
    
    // Computed properties for easy access
    var bookingsList: [BookingData] { bookings.data }
    var currentPage: Int { bookings.currentPage }
    var lastPage: Int { bookings.lastPage }
    var perPage: Int { bookings.perPage }
    var total: Int { bookings.total }
}

public struct MyBookingsPaginatedData: Codable {
    let data: [BookingData]
    let currentPage: Int
    let lastPage: Int
    let perPage: Int
    let total: Int
    let from: Int?
    let to: Int?
    let path: String?
    let firstPageUrl: String?
    let lastPageUrl: String?
    let nextPageUrl: String?
    let prevPageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case data
        case currentPage = "current_page"
        case lastPage = "last_page"
        case perPage = "per_page"
        case total
        case from
        case to
        case path
        case firstPageUrl = "first_page_url"
        case lastPageUrl = "last_page_url"
        case nextPageUrl = "next_page_url"
        case prevPageUrl = "prev_page_url"
    }
}

public struct AcceptBookingResponse: Codable {
    let success: Bool
    let data: BookingData?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case data
        case message
    }
    
    // Computed property for easy access
    var booking: BookingData? { data }
}

public struct RejectBookingResponse: Codable {
    let success: Bool
    let data: BookingData?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case data
        case message
    }
    
    // Computed property for easy access
    var booking: BookingData? { data }
}

public struct BookingData: Codable, Hashable {
    let id: Int
    let userId: Int?
    let departmentId: Int?
    let serviceId: Int?
    let assignedDoctorId: Int?
    let date: String
    let time: String
    let timeSlot: String?
    let amount: String?
    let status: String
    let paymentStatus: String?
    let paymentMethod: String?
    let stripePaymentIntentId: String?
    let stripeCustomerId: String?
    let stripePaymentMethodId: String?
    let doctorStatus: String?
    let doctorNotes: String?
    let doctorRespondedAt: String?
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
        case assignedDoctorId = "assigned_doctor_id"
        case date
        case time
        case timeSlot = "time_slot"
        case amount
        case status
        case paymentStatus = "payment_status"
        case paymentMethod = "payment_method"
        case stripePaymentIntentId = "stripe_payment_intent_id"
        case stripeCustomerId = "stripe_customer_id"
        case stripePaymentMethodId = "stripe_payment_method_id"
        case doctorStatus = "doctor_status"
        case doctorNotes = "doctor_notes"
        case doctorRespondedAt = "doctor_responded_at"
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
    let code: String?
    let description: String?
    let price: String?
    let duration: Int?
    let departmentId: Int?
    let specializationId: Int?
    let parentId: Int?
    let status: String?
    let billingType: String?
    let subscriptionRequired: Int?
    let subscriptionQuotaMonthly: Int?
    let quotaScopedTo: String?
    let requiresDoctor: Int?
    let bookableOnline: Int?
    let stripeProductId: String?
    let stripePriceId: String?
    let createdAt: String?
    let updatedAt: String?
    let specialization: Specialization?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case code
        case description
        case price
        case duration
        case departmentId = "department_id"
        case specializationId = "specialization_id"
        case parentId = "parent_id"
        case status
        case billingType = "billing_type"
        case subscriptionRequired = "subscription_required"
        case subscriptionQuotaMonthly = "subscription_quota_monthly"
        case quotaScopedTo = "quota_scoped_to"
        case requiresDoctor = "requires_doctor"
        case bookableOnline = "bookable_online"
        case stripeProductId = "stripe_product_id"
        case stripePriceId = "stripe_price_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case specialization
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
    let stripeId: String?
    let pmType: String?
    let pmLastFour: String?
    let trialEndsAt: String?
    let twoFactorSecret: String?
    let twoFactorRecoveryCodes: String?
    let twoFactorConfirmedAt: String?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case username
        case stripeId = "stripe_id"
        case pmType = "pm_type"
        case pmLastFour = "pm_last_four"
        case trialEndsAt = "trial_ends_at"
        case twoFactorSecret = "two_factor_secret"
        case twoFactorRecoveryCodes = "two_factor_recovery_codes"
        case twoFactorConfirmedAt = "two_factor_confirmed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
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
    let setupIntent: SetupIntentData?
    let ephemeralKey: EphemeralKeyData?
    let customer: CustomerData?
    let publishableKey: String?
    let amount: String?
    let currency: String?
    let priceId: String?
    let package: PackageData?
    
    // Alternative format for prescription payments (string format)
    let paymentIntentString: String?
    let ephemeralKeyString: String?
    let customerString: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case covered
        case message
        case paymentIntent
        case setupIntent
        case ephemeralKey
        case customer
        case publishableKey
        case amount
        case currency
        case priceId
        case package
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        success = try container.decodeIfPresent(Bool.self, forKey: .success)
        covered = try container.decodeIfPresent(Bool.self, forKey: .covered)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        publishableKey = try container.decodeIfPresent(String.self, forKey: .publishableKey)
        currency = try container.decodeIfPresent(String.self, forKey: .currency)
        priceId = try container.decodeIfPresent(String.self, forKey: .priceId)
        package = try container.decodeIfPresent(PackageData.self, forKey: .package)
        
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
        
        // Try to decode setupIntent (for subscriptions)
        setupIntent = try? container.decode(SetupIntentData.self, forKey: .setupIntent)
        
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
        return setupIntent?.clientSecret ?? paymentIntent?.clientSecret ?? paymentIntentString
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

public struct SetupIntentData: Codable {
    let clientSecret: String
    let id: String?
}

public struct PackageData: Codable {
    let id: Int
    let slug: String
    let billingPeriod: String
    let name: String
    let price: String
    
    private enum CodingKeys: String, CodingKey {
        case id, slug, name, price
        case billingPeriod = "billing_period"
    }
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
    let success: Bool?
    let booking: BookingData?
    let message: String?
    let subscription: SubscriptionData?
    let package: PackageData?
}

public struct SubscriptionData: Codable {
    let id: Int
    let name: String?
    let stripeId: String
    let stripeStatus: String
    let stripePrice: String
    let quantity: Int
    let trialEndsAt: String?
    let endsAt: String?
    
    private enum CodingKeys: String, CodingKey {
        case id, name, quantity
        case stripeId = "stripe_id"
        case stripeStatus = "stripe_status"
        case stripePrice = "stripe_price"
        case trialEndsAt = "trial_ends_at"
        case endsAt = "ends_at"
    }
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
    public let code: String?
    public let name: String
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            id = try container.decode(Int.self, forKey: .id)
        } catch {
            print("❌ [DepartmentInfo] Failed to decode 'id': \(error)")
            throw error
        }
        
        code = try? container.decode(String.self, forKey: .code)
        
        do {
            name = try container.decode(String.self, forKey: .name)
        } catch {
            print("❌ [DepartmentInfo] Failed to decode 'name': \(error)")
            throw error
        }
    }
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

// MARK: - Medical Tourism Models

public struct MedicalTourismEnquiryRequest: Codable {
    public let name: String
    public let email: String
    public let phone: String
    public let password: String
    public let desiredProcedure: String
    public let preferredDestination: String
    public let additionalInformation: String?
    
    private enum CodingKeys: String, CodingKey {
        case name, email, phone, password
        case desiredProcedure = "desired_procedure"
        case preferredDestination = "preferred_destination"
        case additionalInformation = "additional_information"
    }
    
    public init(
        name: String,
        email: String,
        phone: String,
        password: String,
        desiredProcedure: String,
        preferredDestination: String,
        additionalInformation: String?
    ) {
        self.name = name
        self.email = email
        self.phone = phone
        self.password = password
        self.desiredProcedure = desiredProcedure
        self.preferredDestination = preferredDestination
        self.additionalInformation = additionalInformation
    }
    
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "name": name,
            "email": email,
            "phone": phone,
            "password": password,
            "desired_procedure": desiredProcedure,
            "preferred_destination": preferredDestination
        ]
        
        if let additionalInfo = additionalInformation {
            dict["additional_information"] = additionalInfo
        }
        
        return dict
    }
}

public struct MedicalTourismEnquiryResponse: Codable {
    public let message: String
    public let data: MedicalTourismEnquiry
    
    private enum CodingKeys: String, CodingKey {
        case message, data
    }
    
    // Computed property for backward compatibility
    public var success: Bool {
        return !message.isEmpty
    }
}

public struct MedicalTourismEnquiry: Codable, Identifiable {
    public let id: Int
    public let name: String
    public let email: String
    public let phone: String
    public let desiredProcedure: String
    public let preferredDestination: String?
    public let additionalInformation: String?
    public let createdAt: String
    public let updatedAt: String
    
    private enum CodingKeys: String, CodingKey {
        case id, name, email, phone
        case desiredProcedure = "desired_procedure"
        case preferredDestination = "preferred_destination"
        case additionalInformation = "additional_information"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Recovery Journey Models

public struct RecoveryJourneyEnquiryRequest: Codable {
    public let name: String
    public let email: String
    public let phone: String
    public let drug: String
    public let years: String
    public let additionalInformation: String?
    
    private enum CodingKeys: String, CodingKey {
        case name, email, phone
        case drug = "drug_of_addiction"
        case years = "years_of_addiction"
        case additionalInformation = "additional_information"
    }
    
    public init(
        name: String,
        email: String,
        phone: String,
        drug: String,
        years: String,
        additionalInformation: String?
    ) {
        self.name = name
        self.email = email
        self.phone = phone
        self.drug = drug
        self.years = years
        self.additionalInformation = additionalInformation
    }
    
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "full_name": name,
            "email": email,
            "phone": phone,
            "drug_of_addiction": drug,
            "years_of_addiction": years,
        ]
        
        if let additionalInfo = additionalInformation {
            dict["additional_information"] = additionalInfo
        }
        
        return dict
    }
}

public struct RecoveryJourneyEnquiryResponse: Codable {
    public let message: String
    public let data: RecoveryJourneyEnquiry
    
    private enum CodingKeys: String, CodingKey {
        case message, data
    }
    
    // Computed property for backward compatibility
    public var success: Bool {
        return !message.isEmpty
    }
}

public struct RecoveryJourneyEnquiry: Codable, Identifiable {
    public let id: Int
    public let fullName: String
    public let email: String
    public let phone: String
    public let drugOfAddiction: String
    public let yearsOfAddiction: Int
    public let additionalInformation: String?
    public let createdAt: String
    public let updatedAt: String
    
    private enum CodingKeys: String, CodingKey {
        case id, email, phone
        case fullName = "full_name"
        case drugOfAddiction = "drug_of_addiction"
        case yearsOfAddiction = "years_of_addiction"
        case additionalInformation = "additional_information"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
