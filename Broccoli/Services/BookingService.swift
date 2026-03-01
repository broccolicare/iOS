//
//  BookingService.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 02/12/25.
//

import Foundation

public protocol BookingServiceProtocol {
    func fetchAvailableTimeSlots(date: Date, isGP: String?, departmentId: String?, serviceId: String?) async throws -> TimeSlotsResponse
    func fetchActiveTreatments() async throws -> TreatmentsResponse
    func fetchTreatmentQuestionnaire(treatmentId: String) async throws -> QuestionnaireResponse
    func createPrescriptionOrder(data: [String: Any]) async throws -> PrescriptionOrderResponse
    func initializePrescriptionPayment(prescriptionId: String) async throws -> PaymentInitializeResponse
    func confirmPrescriptionPayment(prescriptionId: String) async throws -> PaymentConfirmResponse
    func createBooking(data: [String: Any]) async throws -> BookingResponse
    func fetchBookingDetails(bookingId: String) async throws -> BookingDetailResponse
    func cancelBooking(bookingId: String) async throws -> BookingResponse
    func uploadDocument(bookingId: String, documentData: Data, fileName: String) async throws -> DocumentUploadResponse
    func initializePayment(data: [String: Any]) async throws -> PaymentInitializeResponse
    func confirmPayment(data: [String: Any]) async throws -> PaymentConfirmResponse
    func fetchDepartmentServices(departmentId: String) async throws -> ServicesResponse
    func fetchPatientBookings(type: String?, status: String?, perPage: Int, cursor: String?) async throws -> UpcomingAppointmentsResponse
    func fetchPrescriptions(type: String?, perPage: Int, cursor: String?) async throws -> PrescriptionsListResponse
    func fetchDoctorBookings(type: String?, perPage: Int, cursor: String?) async throws -> MyBookingsResponse
    func acceptBooking(bookingId: Int) async throws -> AcceptBookingResponse
    func rejectBooking(bookingId: Int, reason: String) async throws -> RejectBookingResponse
    func generateAgoraToken(bookingId: Int, channelName: String, expireSeconds: Int) async throws -> AgoraTokenResponse
    func startVideoCall(bookingId: Int) async throws -> VideoCallStatusResponse
    func endConsultation(bookingId: Int, consultationNotes: String) async throws -> VideoCallStatusResponse
    func notifyJoined(bookingId: Int) async throws -> VideoCallStatusResponse
}

public final class BookingService: BaseService, BookingServiceProtocol {
    private let httpClient: HTTPClientProtocol
    
    public init(httpClient: HTTPClientProtocol) {
        self.httpClient = httpClient
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Fetch available time slots for a specific date and optional department
    public func fetchAvailableTimeSlots(date: Date, isGP: String?, departmentId: String?, serviceId: String?) async throws -> TimeSlotsResponse {
        return try await handleServiceError {
            let endpoint = BookingEndpoint.availableTimeSlots(date: date, isGP: isGP, departmentId: departmentId, serviceId: serviceId)
            return try await httpClient.request(endpoint)
        }
    }
    
    /// Fetch active treatments for prescriptions
    public func fetchActiveTreatments() async throws -> TreatmentsResponse {
        return try await handleServiceError {
            let endpoint = BookingEndpoint.activeTreatments
            return try await httpClient.request(endpoint)
        }
    }
    
    /// Fetch questionnaire for a specific treatment
    public func fetchTreatmentQuestionnaire(treatmentId: String) async throws -> QuestionnaireResponse {
        return try await handleServiceError {
            let endpoint = BookingEndpoint.treatmentDetails(treatmentId)
            return try await httpClient.request(endpoint)
        }
    }
    
    /// Create prescription order with questionnaire answers
    public func createPrescriptionOrder(data: [String: Any]) async throws -> PrescriptionOrderResponse {
        return try await handleServiceError {
            let endpoint = BookingEndpoint.createPrescriptionOrder(data)
            return try await httpClient.request(endpoint)
        }
    }
    
    /// Initialize prescription payment - check subscription and get payment intent if needed
    public func initializePrescriptionPayment(prescriptionId: String) async throws -> PaymentInitializeResponse {
        return try await handleServiceError {
            let endpoint = BookingEndpoint.initialisePrescriptionPayment(prescriptionId)
            return try await httpClient.request(endpoint)
        }
    }
    
    /// Confirm prescription payment after successful payment
    public func confirmPrescriptionPayment(prescriptionId: String) async throws -> PaymentConfirmResponse {
        return try await handleServiceError {
            let endpoint = BookingEndpoint.confirmPrescriptionPayment(prescriptionId)
            return try await httpClient.request(endpoint)
        }
    }
    
    /// Create a new booking appointment
    public func createBooking(data: [String: Any]) async throws -> BookingResponse {
        return try await handleServiceError {
            let endpoint = BookingEndpoint.createBooking(data)
            return try await httpClient.request(endpoint)
        }
    }
    
    /// Fetch booking details by ID
    public func fetchBookingDetails(bookingId: String) async throws -> BookingDetailResponse {
        return try await handleServiceError {
            let endpoint = BookingEndpoint.bookingDetails(bookingId)
            return try await httpClient.request(endpoint)
        }
    }
    
    /// Cancel an existing booking
    public func cancelBooking(bookingId: String) async throws -> BookingResponse {
        return try await handleServiceError {
            let endpoint = BookingEndpoint.cancelBooking(bookingId)
            return try await httpClient.request(endpoint)
        }
    }
    
    /// Upload document for booking
    public func uploadDocument(bookingId: String, documentData: Data, fileName: String) async throws -> DocumentUploadResponse {
        return try await handleServiceError {
            let endpoint = BookingEndpoint.uploadDocument(bookingId: bookingId, documentData: documentData, fileName: fileName)
            return try await httpClient.request(endpoint)
        }
    }
    
    /// Initialize payment - check subscription and get payment intent if needed
    public func initializePayment(data: [String: Any]) async throws -> PaymentInitializeResponse {
        return try await handleServiceError {
            let endpoint = BookingEndpoint.paymentInitialize(data)
            return try await httpClient.request(endpoint)
        }
    }
    
    /// Confirm payment and create booking after successful payment
    public func confirmPayment(data: [String: Any]) async throws -> PaymentConfirmResponse {
        return try await handleServiceError {
            let endpoint = BookingEndpoint.paymentConfirm(data)
            return try await httpClient.request(endpoint)
        }
    }
    
    /// Fetch department services by department ID
    public func fetchDepartmentServices(departmentId: String) async throws -> ServicesResponse {
        return try await handleServiceError {
            let endpoint = BookingEndpoint.loadServices(departmentId)
            return try await httpClient.request(endpoint)
        }
    }
    
    /// Fetch patient bookings with optional type/status/cursor filters
    public func fetchPatientBookings(type: String? = nil, status: String? = nil, perPage: Int = 15, cursor: String? = nil) async throws -> UpcomingAppointmentsResponse {
        return try await handleServiceError {
            let endpoint = BookingEndpoint.patientBookings(type: type, status: status, perPage: perPage, cursor: cursor)
            return try await httpClient.request(endpoint)
        }
    }
    
    /// Fetch prescriptions with optional type/cursor filters
    public func fetchPrescriptions(type: String? = nil, perPage: Int = 15, cursor: String? = nil) async throws -> PrescriptionsListResponse {
        return try await handleServiceError {
            let endpoint = BookingEndpoint.prescriptions(type: type, perPage: perPage, cursor: cursor)
            return try await httpClient.request(endpoint)
        }
    }
    
    /// Fetch doctor bookings with optional type/cursor filters
    public func fetchDoctorBookings(type: String? = nil, perPage: Int = 15, cursor: String? = nil) async throws -> MyBookingsResponse {
        return try await handleServiceError {
            let endpoint = BookingEndpoint.doctorBookings(type: type, perPage: perPage, cursor: cursor)
            return try await httpClient.request(endpoint)
        }
    }
    
    /// Accept booking for doctor
    public func acceptBooking(bookingId: Int) async throws -> AcceptBookingResponse {
        return try await handleServiceError {
            let endpoint = BookingEndpoint.acceptBooking(bookingId)
            return try await httpClient.request(endpoint)
        }
    }
    
    /// Reject booking for doctor
    public func rejectBooking(bookingId: Int, reason: String) async throws -> RejectBookingResponse {
        return try await handleServiceError {
            let endpoint = BookingEndpoint.rejectBooking(bookingId: bookingId, reason: reason)
            return try await httpClient.request(endpoint)
        }
    }
    
    /// Generate Agora token for video call
    public func generateAgoraToken(bookingId: Int, channelName: String, expireSeconds: Int = 3600) async throws -> AgoraTokenResponse {
        return try await handleServiceError {
            let body: [String: Any] = [
                "booking_id": bookingId,
                "channel_name": channelName,
                "expire_seconds": expireSeconds
            ]
            let endpoint = BookingEndpoint.generateAgoraToken(body)
            return try await httpClient.request(endpoint)
        }
    }
    
    /// Start video call for a booking
    public func startVideoCall(bookingId: Int) async throws -> VideoCallStatusResponse {
        return try await handleServiceError {
            let endpoint = BookingEndpoint.startVideoCall(bookingId: bookingId)
            return try await httpClient.request(endpoint)
        }
    }
    
    /// End video call with doctor notes
    public func endConsultation(bookingId: Int, consultationNotes: String) async throws -> VideoCallStatusResponse {
        return try await handleServiceError {
            let endpoint = BookingEndpoint.endConsultation(bookingId: bookingId, consultationNotes: consultationNotes)
            return try await httpClient.request(endpoint)
        }
    }

    /// Notify backend that the user has joined the Agora channel
    public func notifyJoined(bookingId: Int) async throws -> VideoCallStatusResponse {
        return try await handleServiceError {
            let endpoint = BookingEndpoint.consultationJoined(bookingId: bookingId)
            return try await httpClient.request(endpoint)
        }
    }
}


