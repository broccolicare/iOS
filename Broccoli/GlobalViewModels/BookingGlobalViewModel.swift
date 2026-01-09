//
//  BookingGlobalViewModel.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 02/12/25.
//

import Foundation
import Combine
@_spi(CustomerSessionBetaAccess) import StripePaymentSheet

@MainActor
public final class BookingGlobalViewModel: ObservableObject {
    private let bookingService: BookingServiceProtocol
    
    // Published UI state
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var showErrorToast: Bool = false
    @Published public var showSuccessToast: Bool = false
    
    // Stripe Payment state
    @Published public var paymentSheet: PaymentSheet? = nil
    @Published public var paymentResult: PaymentSheetResult? = nil
    @Published public var isPaymentReady: Bool = false
    @Published public var currentPaymentIntentId: String? = nil
    @Published public var confirmedBooking: BookingData? = nil
    
    // Booking form data
    @Published public var selectedDate: Date? = nil
    @Published public var selectedTimeSlot: String? = nil
    @Published public var selectedTimeSlotPeriod: String? = nil // "morning", "afternoon", "evening"
    @Published public var selectedSpecialization: Specialization? = nil
    @Published public var selectedPrescription: PrescriptionItem? = nil
    @Published public var selectedDoctor: String? = nil
    @Published public var selectedDepartmentId: String? = nil
    @Published public var isGP: String? = nil // "0" or "1"
    @Published public var additionalNotes: String = ""
    @Published public var uploadedDocuments: [String] = [] // Document URLs or IDs
    
    // Available time slots (to be fetched from API)
    @Published public var availableTimeSlots: [String] = []
    @Published public var morningSlots: [TimeSlot] = []
    @Published public var afternoonSlots: [TimeSlot] = []
    @Published public var eveningSlots: [TimeSlot] = []
    @Published public var pricingInfo: PricingInfo? = nil
    
    // Treatments (for prescriptions)
    @Published public var treatments: [Treatment] = []
    
    // Services (for department-based bookings)
    @Published public var services: [Service] = []
    @Published public var currentDepartment: DepartmentInfo? = nil
    @Published public var selectedService: Service? = nil
    
    // Questionnaire
    @Published public var currentQuestionnaire: TreatmentWithQuestionnaire? = nil
    @Published public var questionnaireAnswers: [Int: [Int]] = [:] // questionId: [optionIds] for multiple/single choice
    @Published public var questionnaireTextAnswers: [Int: String] = [:] // questionId: text answer
    
    // Prescription Order
    @Published public var currentPrescriptionOrder: PrescriptionOrder? = nil
    @Published public var requiresPayment: Bool = false
    @Published public var promptAddPharmacy: Bool = false
    
    // Booking history
    @Published public var currentBookingId: String? = nil
    
    // Upcoming appointments
    @Published public var upcomingAppointments: [BookingData] = []
    @Published public var currentPage: Int = 1
    @Published public var lastPage: Int = 1
    @Published public var totalAppointments: Int = 0
    @Published public var isLoadingAppointments: Bool = false
    
    // Pending bookings for doctor
    @Published public var pendingBookings: [BookingData] = []
    @Published public var isLoadingPendingBookings: Bool = false
    
    // My/Accepted bookings for doctor
    @Published public var myBookings: [BookingData] = []
    @Published public var isLoadingMyBookings: Bool = false
    
    public init(bookingService: BookingServiceProtocol) {
        self.bookingService = bookingService
    }
    
    // MARK: - Computed Properties
    
    public var isBookingFormValid: Bool {
        return selectedDate != nil && selectedTimeSlot != nil
    }
    
    public var formattedSelectedDate: String {
        guard let date = selectedDate else {
            return "No date selected"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    public var formattedSelectedTimeSlot: String {
        return selectedTimeSlot ?? "No time selected"
    }
    
    // MARK: - Methods
    
    /// Reset booking form to initial state
    public func resetBookingForm() {
        selectedDate = nil
        selectedTimeSlot = nil
        selectedTimeSlotPeriod = nil
        selectedSpecialization = nil
        selectedPrescription = nil
        selectedDoctor = nil
        selectedDepartmentId = nil
        isGP = nil
        additionalNotes = ""
        uploadedDocuments = []
        availableTimeSlots = []
        morningSlots = []
        afternoonSlots = []
        eveningSlots = []
        pricingInfo = nil
        currentQuestionnaire = nil
        questionnaireAnswers = [:]
        questionnaireTextAnswers = [:]
        currentPrescriptionOrder = nil
        requiresPayment = false
        promptAddPharmacy = false
        currentBookingId = nil
        errorMessage = nil
        
        // Reset service-related fields
        selectedService = nil
        services = []
        currentDepartment = nil
    }
    
    /// Fetch available time slots for the selected date
    public func fetchAvailableTimeSlots() async {
        guard let date = selectedDate else {
            errorMessage = "Please select a date first"
            showErrorToast = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await bookingService.fetchAvailableTimeSlots(
                date: date,
                isGP: isGP,
                departmentId: selectedDepartmentId,
                serviceId: selectedService?.id != nil ? "\(selectedService?.id ?? 0)" : nil
            )
            
            if response.success {
                // Store slots by period from API response
                morningSlots = response.slots?.morning ?? []
                afternoonSlots = response.slots?.afternoon ?? []
                eveningSlots = response.slots?.evening ?? []
                
                // Combine all available slots for backward compatibility
                let allSlots = (morningSlots + afternoonSlots + eveningSlots).filter { $0.available }
                availableTimeSlots = allSlots.map { $0.displayTime }
                
                // Store pricing info
                pricingInfo = response.pricing
                
                // Store department info
                currentDepartment = response.department
            } else {
                errorMessage = response.message ?? "Failed to fetch available time slots"
                showErrorToast = true
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            showErrorToast = true
        }
        
        isLoading = false
    }
    
    /// Fetch active treatments for prescriptions
    public func fetchActiveTreatments() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await bookingService.fetchActiveTreatments()
            
            if response.success {
                treatments = response.treatments
            } else {
                errorMessage = response.message ?? "Failed to fetch treatments"
                showErrorToast = true
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            showErrorToast = true
        }
        
        isLoading = false
    }
    
    /// Fetch department services by department ID
    public func loadDepartmentServices(departmentId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await bookingService.fetchDepartmentServices(departmentId: departmentId)
            
            if response.success {
                services = response.data
                currentDepartment = response.department
                print("✅ Loaded \(services.count) services for department: \(response.department.name)")
            } else {
                errorMessage = "Failed to fetch services"
                showErrorToast = true
                services = []
                currentDepartment = nil
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            showErrorToast = true
            services = []
            currentDepartment = nil
        }
        
        isLoading = false
    }
    
    /// Fetch questionnaire for a specific treatment
    public func fetchTreatmentQuestionnaire(treatmentId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await bookingService.fetchTreatmentQuestionnaire(treatmentId: treatmentId)
            
            if response.success {
                currentQuestionnaire = response.treatment
            } else {
                errorMessage = "Failed to fetch questionnaire"
                showErrorToast = true
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            showErrorToast = true
        }
        
        isLoading = false
    }
    
    /// Create prescription order with questionnaire answers
    public func createPrescriptionOrder() async -> Bool {
        guard let questionnaire = currentQuestionnaire else {
            errorMessage = "No questionnaire data available"
            showErrorToast = true
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        // Prepare answers array
        var answers: [[String: Any]] = []
        
        // Add option-based answers (multiple_choice and single_choice)
        for (questionId, optionIds) in questionnaireAnswers {
            // Get option texts from the questionnaire
            if let question = findQuestion(by: questionId, in: questionnaire) {
                let selectedOptionTexts = question.options
                    .filter { optionIds.contains($0.id) }
                    .map { $0.optionText }
                    .joined(separator: ", ")
                
                if !selectedOptionTexts.isEmpty {
                    answers.append([
                        "question_id": questionId,
                        "answer_text": selectedOptionTexts
                    ])
                }
            }
        }
        
        // Add text-based answers
        for (questionId, text) in questionnaireTextAnswers {
            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                answers.append([
                    "question_id": questionId,
                    "answer_text": text
                ])
            }
        }
        
        // Prepare request data
        let requestData: [String: Any] = [
            "treatment_id": questionnaire.id,
            "answers": answers
        ]
        
        do {
            let response = try await bookingService.createPrescriptionOrder(data: requestData)
            
            if response.success {
                // Save prescription data for further processing
                currentPrescriptionOrder = response.prescription
                requiresPayment = response.requiresPayment
                promptAddPharmacy = response.promptAddPharmacy
                
                // If payment is required, initialize payment automatically
                if response.requiresPayment {
                    if let paymentResponse = await initializePrescriptionPayment() {
                        // Check response success and if payment is covered by subscription
                        if paymentResponse.success == true {
                            // Check if subscription covers the cost
                            if paymentResponse.covered == true {
                                // Subscription covers the cost - no payment needed
                                // Directly confirm the payment
                                if let confirmResponse = await confirmPrescriptionPayment() {
                                    showSuccessToast = true
                                    isLoading = false
                                    return true
                                } else {
                                    isLoading = false
                                    return false
                                }
                            } else {
                                // Payment required - prepare Stripe payment sheet
                                // The payment sheet will be shown in the view when isPaymentReady is true
                                preparePaymentSheet(with: paymentResponse)
                                isLoading = false
                                return true
                            }
                        } else {
                            // Payment initialization failed
                            errorMessage = paymentResponse.message ?? "Failed to initialize payment"
                            showErrorToast = true
                            isLoading = false
                            return false
                        }
                    } else {
                        // Failed to initialize payment
                        isLoading = false
                        return false
                    }
                } else {
                    // No payment required
                    showSuccessToast = true
                    isLoading = false
                    return true
                }
            } else {
                errorMessage = response.message ?? "Failed to create prescription order"
                showErrorToast = true
                isLoading = false
                return false
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            showErrorToast = true
            isLoading = false
            return false
        }
    }
    
    // Helper function to find question by ID in questionnaire
    private func findQuestion(by questionId: Int, in questionnaire: TreatmentWithQuestionnaire) -> QuestionnaireQuestion? {
        for group in questionnaire.questionnaireGroups {
            if let question = group.questions.first(where: { $0.id == questionId }) {
                return question
            }
        }
        return nil
    }
    
    /// Initialize prescription payment - Step 1: Check subscription and get payment intent
    public func initializePrescriptionPayment() async -> PaymentInitializeResponse? {
        guard let prescription = currentPrescriptionOrder else {
            errorMessage = "No prescription order available"
            showErrorToast = true
            return nil
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await bookingService.initializePrescriptionPayment(prescriptionId: String(prescription.id))
            
            isLoading = false
            return response
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            showErrorToast = true
            isLoading = false
            return nil
        }
    }
    
    /// Confirm prescription payment - Step 2: Confirm payment after successful Stripe payment
    public func confirmPrescriptionPayment() async -> PaymentConfirmResponse? {
        guard let prescription = currentPrescriptionOrder else {
            errorMessage = "No prescription order available"
            showErrorToast = true
            return nil
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await bookingService.confirmPrescriptionPayment(prescriptionId: String(prescription.id))
            
            isLoading = false
            return response
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            showErrorToast = true
            isLoading = false
            return nil
        }
    }
    
    /// Initialize payment - Step 1: Check subscription and get payment intent
    public func initializePayment() async -> PaymentInitializeResponse? {
        guard isBookingFormValid else {
            errorMessage = "Please fill all required fields"
            showErrorToast = true
            return nil
        }
        
        isLoading = true
        errorMessage = nil
        
        // Prepare booking data
        var paymentData: [String: Any] = [:]
        
        // Required: date in YYYY-MM-DD format
        if let date = selectedDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            paymentData["date"] = formatter.string(from: date)
        }
        
        // Required: time in HH:mm format
        if let timeSlot = selectedTimeSlot {
            paymentData["time"] = timeSlot
        }
        
        // Optional: time_slot period (morning/afternoon/evening)
        if let period = selectedTimeSlotPeriod {
            paymentData["time_slot"] = period
        }
        
        // Optional: department_id
        if let departmentId = selectedDepartmentId, let deptId = Int(departmentId) {
            paymentData["department_id"] = deptId
        }
        
        // Optional: service_id (from selected specialization)
        if let service = selectedService {
            paymentData["service_id"] = service.id
        }
        
        do {
            let response = try await bookingService.initializePayment(data: paymentData)
            isLoading = false
            return response
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            showErrorToast = true
            isLoading = false
            return nil
        }
    }
    
    /// Confirm payment - Step 2: After successful payment, confirm and create booking
    public func confirmPayment(paymentIntentId: String) async -> PaymentConfirmResponse? {
        guard isBookingFormValid else {
            errorMessage = "Please fill all required fields"
            showErrorToast = true
            return nil
        }
        
        isLoading = true
        errorMessage = nil
        
        // Prepare booking data with payment intent
        var confirmData: [String: Any] = [:]
        
        confirmData["payment_intent_id"] = paymentIntentId
        
        // Required: date in YYYY-MM-DD format
        if let date = selectedDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            confirmData["date"] = formatter.string(from: date)
        }
        
        // Required: time in HH:mm format
        if let timeSlot = selectedTimeSlot {
            confirmData["time"] = timeSlot
        }
        
        // Optional: time_slot period (morning/afternoon/evening)
        if let period = selectedTimeSlotPeriod {
            confirmData["time_slot"] = period
        }
        
        // Optional: department_id
        if let departmentId = selectedDepartmentId, let deptId = Int(departmentId) {
            confirmData["department_id"] = deptId
        }
        
        // Optional: service_id (from selected specialization)
        if let service = selectedService {
            confirmData["service_id"] = service.id
        }
        
        do {
            let response = try await bookingService.confirmPayment(data: confirmData)
            
            if response.success, let booking = response.booking {
                currentBookingId = String(booking.id)
                showSuccessToast = true
                isLoading = false
                return response
            } else {
                errorMessage = response.message ?? "Failed to confirm booking"
                showErrorToast = true
                isLoading = false
                return nil
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            showErrorToast = true
            isLoading = false
            return nil
        }
    }
    
    /// Upload document for booking
    public func uploadDocument(_ documentData: Data, fileName: String) async -> Bool {
        guard let bookingId = currentBookingId else {
            errorMessage = "No active booking found"
            showErrorToast = true
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await bookingService.uploadDocument(bookingId: bookingId, documentData: documentData, fileName: fileName)
            
            if response.success, let data = response.data {
                uploadedDocuments.append(data.documentUrl)
                isLoading = false
                return true
            } else {
                errorMessage = response.message ?? "Failed to upload document"
                showErrorToast = true
                isLoading = false
                return false
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            showErrorToast = true
            isLoading = false
            return false
        }
    }
    
    /// Remove uploaded document
    public func removeDocument(at index: Int) {
        guard index < uploadedDocuments.count else { return }
        uploadedDocuments.remove(at: index)
    }
    
    // MARK: - Stripe Payment Methods
    
    /// Prepare payment sheet with payment initialize response
    public func preparePaymentSheet(with response: PaymentInitializeResponse) {
        // Debug logging
        print("🔍 PaymentInitializeResponse Debug:")
        print("  - success: \(response.success ?? false)")
        print("  - covered: \(response.covered ?? false)")
        print("  - amount: \(response.amount ?? "nil")")
        print("  - currency: \(response.currency ?? "nil")")
        print("  - publishableKey: \(response.publishableKey ?? "nil")")
        print("  - paymentIntent (object): \(response.paymentIntent != nil ? "exists" : "nil")")
        print("  - paymentIntentString: \(response.paymentIntentString ?? "nil")")
        print("  - ephemeralKey (object): \(response.ephemeralKey != nil ? "exists" : "nil")")
        print("  - ephemeralKeyString: \(response.ephemeralKeyString ?? "nil")")
        print("  - customer (object): \(response.customer != nil ? "exists" : "nil")")
        print("  - customerString: \(response.customerString ?? "nil")")
        
        if let paymentIntent = response.paymentIntent {
            print("  - paymentIntent.clientSecret: \(paymentIntent.clientSecret)")
            print("  - paymentIntent.id: \(paymentIntent.id)")
        }
        
        if let ephemeralKey = response.ephemeralKey {
            print("  - ephemeralKey.secret: \(ephemeralKey.secret)")
        }
        
        if let customer = response.customer {
            print("  - customer.id: \(customer.id)")
        }
        
        print("  - clientSecret (computed): \(response.clientSecret ?? "nil")")
        print("  - customerId (computed): \(response.customerId ?? "nil")")
        print("  - ephemeralKeySecret (computed): \(response.ephemeralKeySecret ?? "nil")")
        
        // Get client secret from either format (object or string)
        guard let clientSecret = response.clientSecret else {
            errorMessage = "Invalid payment response from server - clientSecret is nil"
            showErrorToast = true
            return
        }
        
        // Configure Stripe with publishable key from environment or backend
        let publishableKey = response.publishableKey ?? AppEnvironment.current.stripePublishableKey
        STPAPIClient.shared.publishableKey = publishableKey
        
        // Create PaymentSheet configuration
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Broccoli Care"
        configuration.allowsDelayedPaymentMethods = true
        configuration.returnURL = "broccoli://stripe-redirect"
        
        // If customer info is provided, add it to configuration (works with both formats)
        if let customerId = response.customerId,
           let ephemeralKeySecret = response.ephemeralKeySecret {
            configuration.customer = .init(
                id: customerId,
                ephemeralKeySecret: ephemeralKeySecret
            )
        }
        
        // Store payment intent ID for later use (extract from client secret if needed)
        if let paymentIntent = response.paymentIntent {
            self.currentPaymentIntentId = paymentIntent.id
        } else if let paymentIntentString = response.paymentIntentString {
            // Extract payment intent ID from the client secret string (format: pi_xxx_secret_yyy)
            let components = paymentIntentString.components(separatedBy: "_secret_")
            self.currentPaymentIntentId = components.first
        }
        
        // Initialize PaymentSheet with the payment intent client secret
        self.paymentSheet = PaymentSheet(
            paymentIntentClientSecret: clientSecret,
            configuration: configuration
        )
        self.isPaymentReady = true
    }
    
    /// Handle payment completion callback
    public func onPaymentCompletion(result: PaymentSheetResult, paymentIntentId: String) async -> PaymentConfirmResponse? {
        self.paymentResult = result
        
        switch result {
        case .completed:
            // Payment successful - confirm booking on backend
            let response = await confirmPayment(paymentIntentId: paymentIntentId)
            if let booking = response?.booking {
                self.confirmedBooking = booking
            }
            return response
            
        case .failed(let error):
            errorMessage = "Payment failed: \(error.localizedDescription)"
            showErrorToast = true
            return nil
            
        case .canceled:
            errorMessage = "Payment was canceled"
            showErrorToast = true
            return nil
        }
    }
    
    /// Handle prescription payment completion callback
    public func onPrescriptionPaymentCompletion(result: PaymentSheetResult) async -> PaymentConfirmResponse? {
        self.paymentResult = result
        
        switch result {
        case .completed:
            // Payment successful - confirm prescription payment on backend
            let response = await confirmPrescriptionPayment()
            if response?.success == true {
                showSuccessToast = true
            }
            return response
            
        case .failed(let error):
            errorMessage = "Payment failed: \(error.localizedDescription)"
            showErrorToast = true
            return nil
            
        case .canceled:
            errorMessage = "Payment was canceled"
            showErrorToast = true
            return nil
        }
    }
    
    // MARK: - Upcoming Appointments
    
    /// Fetch upcoming confirmed appointments with pagination
    public func fetchUpcomingConfirmedAppointments(perPage: Int = 10, page: Int = 1, loadMore: Bool = false) async {
        isLoadingAppointments = true
        errorMessage = nil
        
        do {
            let response = try await bookingService.fetchUpcomingConfirmedAppointments(perPage: perPage, page: page)
            
            if loadMore {
                // Append to existing appointments for pagination
                self.upcomingAppointments.append(contentsOf: response.bookings)
            } else {
                // Replace appointments (for initial load or refresh)
                self.upcomingAppointments = response.bookings
            }
            
            self.currentPage = response.currentPage
            self.lastPage = response.lastPage
            self.totalAppointments = response.total
            
        } catch {
            errorMessage = error.localizedDescription
            showErrorToast = true
        }
        
        isLoadingAppointments = false
    }
    
    /// Load next page of appointments
    public func loadMoreAppointments() async {
        guard currentPage < lastPage else { return }
        await fetchUpcomingConfirmedAppointments(perPage: 10, page: currentPage + 1, loadMore: true)
    }
    
    /// Refresh appointments (reset to page 1)
    public func refreshAppointments() async {
        await fetchUpcomingConfirmedAppointments(perPage: 10, page: 1, loadMore: false)
    }
    
    // MARK: - Pending Bookings For Doctor
    
    /// Fetch pending bookings for doctor
    public func fetchPendingBookingsForDoctor() async {
        isLoadingPendingBookings = true
        errorMessage = nil
        
        do {
            let response = try await bookingService.fetchPendingBookingsForDoctor()
            
            if response.success {
                self.pendingBookings = response.bookings
            } else {
                errorMessage = response.message ?? "Failed to fetch pending bookings"
                showErrorToast = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showErrorToast = true
        }
        
        isLoadingPendingBookings = false
    }
    
    /// Refresh pending bookings
    public func refreshPendingBookings() async {
        await fetchPendingBookingsForDoctor()
    }
    
    // MARK: - My/Accepted Bookings For Doctor
    
    /// Fetch my/accepted bookings for doctor
    public func fetchMyBookingsForDoctor() async {
        isLoadingMyBookings = true
        errorMessage = nil
        
        do {
            let response = try await bookingService.fetchMyBookingsForDoctor()
            
            if response.success {
                self.myBookings = response.bookingsList
            } else {
                errorMessage = response.message ?? "Failed to fetch my bookings"
                showErrorToast = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showErrorToast = true
        }
        
        isLoadingMyBookings = false
    }
    
    /// Refresh my bookings
    public func refreshMyBookings() async {
        await fetchMyBookingsForDoctor()
    }
    
    // MARK: - Accept/Reject Bookings For Doctor
    
    /// Accept a booking for doctor
    public func acceptBooking(bookingId: Int) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await bookingService.acceptBooking(bookingId: bookingId)
            
            if response.success {
                showSuccessToast = true
                isLoading = false
                return true
            } else {
                errorMessage = response.message ?? "Failed to accept booking"
                showErrorToast = true
                isLoading = false
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            showErrorToast = true
            isLoading = false
            return false
        }
    }
    
    /// Reject a booking for doctor
    public func rejectBooking(bookingId: Int, reason: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await bookingService.rejectBooking(bookingId: bookingId, reason: reason)
            
            if response.success {
                showSuccessToast = true
                isLoading = false
                return true
            } else {
                errorMessage = response.message ?? "Failed to reject booking"
                showErrorToast = true
                isLoading = false
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            showErrorToast = true
            isLoading = false
            return false
        }
    }
}
