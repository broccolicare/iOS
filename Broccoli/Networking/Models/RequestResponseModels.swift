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
    let pagination: CursorPaginationInfo
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case data
        case pagination
        case message
    }
    
    // Computed properties for easy access
    var bookings: [BookingData] { data }
    var nextCursor: String? { pagination.nextCursor }
    var hasMore: Bool { pagination.hasMore }
    var perPage: Int { pagination.perPage }
}

public struct CursorPaginationInfo: Codable {
    let nextCursor: String?
    let prevCursor: String?
    let perPage: Int
    let hasMore: Bool

    enum CodingKeys: String, CodingKey {
        case nextCursor = "next_cursor"
        case prevCursor = "prev_cursor"
        case perPage    = "per_page"
        case hasMore    = "has_more"
    }
}

public struct PrescriptionsListResponse: Codable {
    let success: Bool
    let prescriptions: [PrescriptionOrder]
    let pagination: CursorPaginationInfo
    
    enum CodingKeys: String, CodingKey {
        case success
        case prescriptions = "data"
        case pagination
    }
    
    var nextCursor: String? { pagination.nextCursor }
    var hasMore: Bool { pagination.hasMore }
    var perPage: Int { pagination.perPage }
}

public struct MyBookingsResponse: Codable {
    let success: Bool
    let data: [BookingData]
    let pagination: CursorPaginationInfo
    let message: String?

    enum CodingKeys: String, CodingKey {
        case success
        case data
        case pagination
        case message
    }

    var bookingsList: [BookingData] { data }
    var nextCursor: String? { pagination.nextCursor }
    var hasMore: Bool { pagination.hasMore }
    var perPage: Int { pagination.perPage }
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

public struct AssignedDoctorData: Codable, Hashable {
    let id: Int
    let name: String
}

public struct BookingData: Codable, Hashable, Identifiable {
    public let id: Int
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
    let consultationNotes: String?
    let consultationCompletedAt: String?
    let agoraSessionId: String?
    let bookingNumber: String?
    let createdAt: String?
    let updatedAt: String?
    let service: ServiceData?
    let department: DepartmentData?
    let user: UserData?
    let assignedDoctor: AssignedDoctorData?
    
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
        case consultationNotes = "consultation_notes"
        case consultationCompletedAt = "consultation_completed_at"
        case agoraSessionId = "agora_session_id"
        case bookingNumber = "booking_number"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case service
        case department
        case user
        case assignedDoctor = "assigned_doctor"
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
    let data: BookingData?
    let message: String?
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
    
    public init(from decoder: Decoder) throws {
        // Try to get container with dynamic keys
        guard let container = try? decoder.container(keyedBy: AnyCodingKey.self) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Cannot decode container"))
        }
        
        // Decode simple fields - try both snake_case and camelCase
        success = try? container.decodeIfPresent(Bool.self, forKey: AnyCodingKey("success"))
        covered = try? container.decodeIfPresent(Bool.self, forKey: AnyCodingKey("covered"))
        message = try? container.decodeIfPresent(String.self, forKey: AnyCodingKey("message"))
        currency = try? container.decodeIfPresent(String.self, forKey: AnyCodingKey("currency"))
        
        // publishableKey - try camelCase then snake_case
        publishableKey = (try? container.decodeIfPresent(String.self, forKey: AnyCodingKey("publishableKey"))) 
            ?? (try? container.decodeIfPresent(String.self, forKey: AnyCodingKey("publishable_key")))
        
        // priceId - try camelCase then snake_case
        priceId = (try? container.decodeIfPresent(String.self, forKey: AnyCodingKey("priceId")))
            ?? (try? container.decodeIfPresent(String.self, forKey: AnyCodingKey("price_id")))
        
        package = try? container.decodeIfPresent(PackageData.self, forKey: AnyCodingKey("package"))
        
        // Handle amount as either String or Int
        if let amountString = try? container.decode(String.self, forKey: AnyCodingKey("amount")) {
            amount = amountString
        } else if let amountInt = try? container.decode(Int.self, forKey: AnyCodingKey("amount")) {
            amount = String(amountInt)
        } else if let amountDouble = try? container.decode(Double.self, forKey: AnyCodingKey("amount")) {
            amount = String(format: "%.2f", amountDouble)
        } else {
            amount = nil
        }
        
        // setupIntent - try camelCase then snake_case
        setupIntent = (try? container.decode(SetupIntentData.self, forKey: AnyCodingKey("setupIntent")))
            ?? (try? container.decode(SetupIntentData.self, forKey: AnyCodingKey("setup_intent")))
        
        // paymentIntent - try camelCase object, then snake_case object, then string formats
        if let paymentIntentObj = try? container.decode(PaymentIntentData.self, forKey: AnyCodingKey("paymentIntent")) {
            paymentIntent = paymentIntentObj
            paymentIntentString = nil
        } else if let paymentIntentObj = try? container.decode(PaymentIntentData.self, forKey: AnyCodingKey("payment_intent")) {
            paymentIntent = paymentIntentObj
            paymentIntentString = nil
        } else if let paymentIntentStr = try? container.decode(String.self, forKey: AnyCodingKey("paymentIntent")) {
            paymentIntent = nil
            paymentIntentString = paymentIntentStr
        } else if let paymentIntentStr = try? container.decode(String.self, forKey: AnyCodingKey("payment_intent")) {
            paymentIntent = nil
            paymentIntentString = paymentIntentStr
        } else {
            paymentIntent = nil
            paymentIntentString = nil
        }
        
        // ephemeralKey - try camelCase object, then snake_case object, then string formats
        if let ephemeralKeyObj = try? container.decode(EphemeralKeyData.self, forKey: AnyCodingKey("ephemeralKey")) {
            ephemeralKey = ephemeralKeyObj
            ephemeralKeyString = nil
        } else if let ephemeralKeyObj = try? container.decode(EphemeralKeyData.self, forKey: AnyCodingKey("ephemeral_key")) {
            ephemeralKey = ephemeralKeyObj
            ephemeralKeyString = nil
        } else if let ephemeralKeyStr = try? container.decode(String.self, forKey: AnyCodingKey("ephemeralKey")) {
            ephemeralKey = nil
            ephemeralKeyString = ephemeralKeyStr
        } else if let ephemeralKeyStr = try? container.decode(String.self, forKey: AnyCodingKey("ephemeral_key")) {
            ephemeralKey = nil
            ephemeralKeyString = ephemeralKeyStr
        } else {
            ephemeralKey = nil
            ephemeralKeyString = nil
        }
        
        // customer - try object then string formats (both key formats)
        if let customerObj = try? container.decode(CustomerData.self, forKey: AnyCodingKey("customer")) {
            customer = customerObj
            customerString = nil
        } else if let customerStr = try? container.decode(String.self, forKey: AnyCodingKey("customer")) {
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

// Helper struct for dynamic coding keys
private struct AnyCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init(_ stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
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
    public let details: String?
    public let category: String?
    public let price: String?
    public let isActive: Bool
    public let requiresQuestionnaire: Bool?
    public let stripeProductId: String?
    public let createdAt: String?
    public let updatedAt: String?
    
    private enum CodingKeys: String, CodingKey {
        case id, name, description, details, category, price
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
    public let bookableOnline: Int?
    public let department: ServiceDepartment?
    public let subServices: [SubService]
    
    private enum CodingKeys: String, CodingKey {
        case id, name, description, price, duration, department
        case requiresDoctor = "requires_doctor"
        case bookableOnline = "bookable_online"
        case subServices = "sub_services"
    }
}

public struct ServiceDepartment: Codable, Identifiable {
    public let id: Int
    public let name: String
    
    private enum CodingKeys: String, CodingKey {
        case id, name
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

// MARK: - Prescription Patient Models (for list response)

public struct PrescriptionPatient: Codable, Identifiable {
    public let id: Int
    public let name: String
    public let email: String
    public let username: String?
    public let emailVerifiedAt: String?
    public let status: String?
    public let createdAt: String?
    public let roles: [String]?
    public let profile: PatientProfile?
    public let subscriptions: [PatientSubscription]?
    
    private enum CodingKeys: String, CodingKey {
        case id, name, email, username, status, roles, profile, subscriptions
        case emailVerifiedAt = "email_verified_at"
        case createdAt = "created_at"
    }
}

public struct PatientProfile: Codable {
    public let phoneCode: String?
    public let phone: String?
    public let description: String?
    public let gender: String?
    public let bloodGroup: String?
    public let bloodGroupId: Int?
    public let dateOfBirth: String?
    public let address: String?
    public let city: String?
    public let state: String?
    public let country: String?
    public let postalCode: String?
    public let profileImage: String?
    
    private enum CodingKeys: String, CodingKey {
        case phoneCode = "phone_code"
        case phone, description, gender
        case bloodGroup = "blood_group"
        case bloodGroupId = "blood_group_id"
        case dateOfBirth = "date_of_birth"
        case address, city, state, country
        case postalCode = "postal_code"
        case profileImage = "profile_image"
    }
}

public struct PatientSubscription: Codable, Identifiable {
    public let id: Int
    public let type: String
    public let stripeStatus: String
    public let stripePrice: String
    public let endsAt: String?
    
    private enum CodingKeys: String, CodingKey {
        case id, type
        case stripeStatus = "stripe_status"
        case stripePrice = "stripe_price"
        case endsAt = "ends_at"
    }
}

public struct PrescriptionOrder: Codable, Identifiable {
    public let id: Int
    public let status: String
    public let paymentStatus: String
    public let amount: String
    public let validUntil: String
    public let notes: String?
    public let adminNotes: String?
    public let rejectionReason: String?
    public let createdAt: String
    public let updatedAt: String
    public let approvedAt: String?
    public let rejectedAt: String?
    public let assignedAt: String?
    public let sentAt: String?
    public let completedAt: String?
    public let treatment: Treatment
    public let patient: PrescriptionPatient?
    public let doctor: Doctor?
    public let pharmacy: Pharmacy?
    public let answers: [PrescriptionAnswerDetail]?
    
    private enum CodingKeys: String, CodingKey {
        case id, status, notes, treatment, answers, patient, doctor, pharmacy
        case paymentStatus = "payment_status"
        case amount
        case validUntil = "valid_until"
        case rejectionReason = "rejection_reason"
        case adminNotes = "admin_notes"
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
    public let medicalProcedureId: Int
    public let medicalDestinationId: Int
    public let additionalInformation: String?
    
    private enum CodingKeys: String, CodingKey {
        case name, email, phone
        case medicalProcedureId = "medical_procedure_id"
        case medicalDestinationId = "medical_destination_id"
        case additionalInformation = "additional_information"
    }
    
    public init(
        name: String,
        email: String,
        phone: String,
        medicalProcedureId: Int,
        medicalDestinationId: Int,
        additionalInformation: String?
    ) {
        self.name = name
        self.email = email
        self.phone = phone
        self.medicalProcedureId = medicalProcedureId
        self.medicalDestinationId = medicalDestinationId
        self.additionalInformation = additionalInformation
    }
    
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "name": name,
            "email": email,
            "phone": phone,
            "medical_procedure_id": medicalProcedureId,
            "medical_destination_id": medicalDestinationId
        ]
        
        if let additionalInfo = additionalInformation {
            dict["additional_information"] = additionalInfo
        }
        
        return dict
    }
}

public struct MedicalTourismEnquiryResponse: Codable {
    public let success: Bool
    public let message: String
    public let data: MedicalTourismEnquiry?
}

public struct MedicalTourismEnquiry: Codable, Identifiable {
    public let id: Int
    public let name: String
    public let email: String
    public let phone: String
    public let additionalInformation: String?
    public let createdAt: String?
    public let updatedAt: String?
    
    private enum CodingKeys: String, CodingKey {
        case id, name, email, phone
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
    public let recoveryDrugId: Int
    public let recoveryAddictionYearId: Int
    public let additionalInformation: String?
    
    private enum CodingKeys: String, CodingKey {
        case name, email, phone
        case recoveryDrugId = "recovery_drug_id"
        case recoveryAddictionYearId = "recovery_addiction_year_id"
        case additionalInformation = "additional_information"
    }
    
    public init(
        name: String,
        email: String,
        phone: String,
        recoveryDrugId: Int,
        recoveryAddictionYearId: Int,
        additionalInformation: String?
    ) {
        self.name = name
        self.email = email
        self.phone = phone
        self.recoveryDrugId = recoveryDrugId
        self.recoveryAddictionYearId = recoveryAddictionYearId
        self.additionalInformation = additionalInformation
    }
    
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "full_name": name,
            "email": email,
            "phone": phone,
            "recovery_drug_id": recoveryDrugId,
            "recovery_addiction_year_id": recoveryAddictionYearId,
        ]
        
        if let additionalInfo = additionalInformation {
            dict["additional_information"] = additionalInfo
        }
        
        return dict
    }
}

public struct RecoveryJourneyEnquiryResponse: Codable {
    public let success: Bool
    public let message: String
    public let data: RecoveryJourneyEnquiry?
}

public struct RecoveryJourneyEnquiry: Codable, Identifiable {
    public let id: Int
    public let fullName: String
    public let email: String
    public let phone: String
    public let recoveryDrugId: Int?
    public let recoveryAddictionYearId: Int?
    public let additionalInformation: String?
    public let createdAt: String?
    public let updatedAt: String?
    
    private enum CodingKeys: String, CodingKey {
        case id, email, phone
        case fullName = "full_name"
        case recoveryDrugId = "recovery_drug_id"
        case recoveryAddictionYearId = "recovery_addiction_year_id"
        case additionalInformation = "additional_information"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Video Call Models

public struct AgoraTokenResponse: Codable {
    public let success: Bool?
    public let appId: String?
    public let token: String?
    public let channelName: String?
    public let uid: UInt?
    public let expiresIn: Int?
    public let message: String?
    
    private enum CodingKeys: String, CodingKey {
        case success, token, uid, message
        case appId = "app_id"
        case channelName = "channel_name"
        case expiresIn = "expires_in"
    }
}

public struct VideoCallStatusResponse: Codable {
    public let success: Bool
    public let booking: BookingData?
    public let message: String?
    
    private enum CodingKeys: String, CodingKey {
        case success, booking, message
    }
}
