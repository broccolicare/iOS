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
    public let bookingService: BookingServiceProtocol
    
    // Published UI state
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var showErrorToast: Bool = false
    @Published public var showSuccessToast: Bool = false
    @Published public var isFetchingBookingDetail: Bool = false
    
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
    @Published public var upcomingNextCursor: String? = nil
    @Published public var upcomingHasMore: Bool = false
    @Published public var isLoadingAppointments: Bool = false
    
    // Past appointments
    @Published public var pastAppointments: [BookingData] = []
    @Published public var pastNextCursor: String? = nil
    @Published public var pastHasMore: Bool = false
    @Published public var isLoadingPastAppointments: Bool = false
    
    // Pending bookings for doctor
    @Published public var pendingBookings: [BookingData] = []
    @Published public var isLoadingPendingBookings: Bool = false
    
    // My/Accepted bookings for doctor
    @Published public var myBookings: [BookingData] = []
    @Published public var isLoadingMyBookings: Bool = false
    
    // Past/history bookings for doctor
    @Published public var doctorBookingHistory: [BookingData] = []
    @Published public var isLoadingDoctorHistory: Bool = false
    @Published public var doctorHistoryNextCursor: String? = nil
    @Published public var doctorHistoryHasMore: Bool = false
    @Published public var doctorHistoryPerPage: Int = 15
    
    // Prescriptions
    @Published public var prescriptions: [PrescriptionOrder] = []
    @Published public var isLoadingPrescriptions: Bool = false
    @Published public var prescriptionsNextCursor: String? = nil
    @Published public var prescriptionsHasMore: Bool = false
    
    // Prescription History
    @Published public var prescriptionHistory: [PrescriptionOrder] = []
    @Published public var isLoadingPrescriptionHistory: Bool = false
    @Published public var prescriptionHistoryNextCursor: String? = nil
    @Published public var prescriptionHistoryHasMore: Bool = false
    
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
        showErrorToast = false
        
        // Reset service-related fields
        selectedService = nil
        services = []
        currentDepartment = nil
    }
    
    /// Reset prescription flow to initial state
    public func resetPrescriptionFlow() {
        print("🔄 [Prescription] Resetting prescription flow")
        selectedPrescription = nil
        currentQuestionnaire = nil
        questionnaireAnswers = [:]
        questionnaireTextAnswers = [:]
        currentPrescriptionOrder = nil
        requiresPayment = false
        promptAddPharmacy = false
        
        // Reset payment-related state
        paymentSheet = nil
        paymentResult = nil
        isPaymentReady = false
        currentPaymentIntentId = nil
        
        errorMessage = nil
        print("✅ [Prescription] Reset complete")
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
    public func createPrescriptionOrder(pharmacyId: Int? = nil) async -> Bool {
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
        var requestData: [String: Any] = [
            "treatment_id": questionnaire.id,
            "answers": answers
        ]
        if let pharmacyId { requestData["pharmacy_id"] = pharmacyId }
        
        do {
            let response = try await bookingService.createPrescriptionOrder(data: requestData)
            
            if response.success {
                // Save prescription data for further processing
                currentPrescriptionOrder = response.prescription
                requiresPayment = response.requiresPayment
                promptAddPharmacy = response.promptAddPharmacy
                
                // If payment is required, initialize payment automatically
                if response.requiresPayment {
                    print("💰 [Prescription Order] Payment required, initializing...")
                    if let paymentResponse = await initializePrescriptionPayment() {
                        print("💰 [Prescription Order] Payment response received")
                        print("  - success: \(paymentResponse.success ?? false)")
                        print("  - covered: \(paymentResponse.covered ?? false)")
                        
                        // Check if payment initialization failed explicitly
                        if paymentResponse.success == false {
                            // Payment initialization failed
                            errorMessage = paymentResponse.message ?? "Failed to initialize payment"
                            showErrorToast = true
                            isLoading = false
                            return false
                        }
                        
                        // Check if subscription covers the cost
                        if paymentResponse.covered == true {
                            print("💰 [Prescription Order] Covered by subscription, confirming...")
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
                            print("💰 [Prescription Order] Not covered, preparing payment sheet...")
                            // Payment required - prepare Stripe payment sheet
                            // The payment sheet will be shown in the view when isPaymentReady is true
                            preparePaymentSheet(with: paymentResponse)
                            print("💰 [Prescription Order] Payment sheet prepared, isPaymentReady: \(isPaymentReady)")
                            isLoading = false
                            return true
                        }
                    } else {
                        // Failed to initialize payment
                        print("❌ [Prescription Order] Failed to initialize payment")
                        errorMessage = "Failed to initialize payment. Please try again."
                        showErrorToast = true
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
        
        print("💰 [Prescription Payment] Initializing payment:")
        print("  - Prescription ID: \(prescription.id)")
        print("  - Amount: \(prescription.amount)")
        print("  - Treatment price: \(prescription.treatment.price)")
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await bookingService.initializePrescriptionPayment(prescriptionId: String(prescription.id))
            
            print("💰 [Prescription Payment] Response received:")
            print("  - Success: \(response.success ?? false)")
            print("  - Covered: \(response.covered ?? false)")
            print("  - Amount: \(response.amount ?? "nil")")
            print("  - Currency: \(response.currency ?? "nil")")
            print("  - publishableKey: \(response.publishableKey ?? "nil")")
            print("  - paymentIntent (object): \(response.paymentIntent != nil ? "exists" : "nil")")
            print("  - paymentIntentString: \(response.paymentIntentString ?? "nil")")
            print("  - ephemeralKey (object): \(response.ephemeralKey != nil ? "exists" : "nil")")
            print("  - ephemeralKeyString: \(response.ephemeralKeyString ?? "nil")")
            print("  - customer (object): \(response.customer != nil ? "exists" : "nil")")
            print("  - customerString: \(response.customerString ?? "nil")")
            print("  - clientSecret (computed): \(response.clientSecret ?? "nil")")
            print("  - customerId (computed): \(response.customerId ?? "nil")")
            print("  - ephemeralKeySecret (computed): \(response.ephemeralKeySecret ?? "nil")")
            
            isLoading = false
            return response
        } catch {
            print("❌ [Prescription Payment] Error: \(error.localizedDescription)")
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
            
            if response.success == true, let booking = response.booking {
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
            print("❌ [Payment Sheet] ERROR: clientSecret is nil")
            errorMessage = "Invalid payment response from server - clientSecret is nil"
            showErrorToast = true
            isPaymentReady = false
            return
        }
        
        print("✅ [Payment Sheet] Client secret found: \(clientSecret.prefix(30))...")
        
        print("✅ [Payment Sheet] Client secret found: \(clientSecret.prefix(30))...")
        
        // Configure Stripe with publishable key from environment or backend
        let publishableKey = response.publishableKey ?? AppEnvironment.current.stripePublishableKey
        STPAPIClient.shared.publishableKey = publishableKey
        print("✅ [Payment Sheet] Publishable key configured: \(publishableKey.prefix(20))...")
        
        // Create PaymentSheet configuration
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Broccoli Care"
        configuration.allowsDelayedPaymentMethods = true
        configuration.returnURL = "broccoli://stripe-redirect"
        print("✅ [Payment Sheet] Configuration created")
        
        // If customer info is provided, add it to configuration (works with both formats)
        if let customerId = response.customerId,
           let ephemeralKeySecret = response.ephemeralKeySecret {
            print("✅ [Payment Sheet] Setting customer: \(customerId)")
            configuration.customer = .init(
                id: customerId,
                ephemeralKeySecret: ephemeralKeySecret
            )
        } else {
            print("⚠️ [Payment Sheet] No customer info provided")
        }
        
        // Store payment intent ID for later use (extract from client secret if needed)
        if let paymentIntent = response.paymentIntent {
            self.currentPaymentIntentId = paymentIntent.id
            print("✅ [Payment Sheet] Payment intent ID: \(paymentIntent.id)")
        } else if let paymentIntentString = response.paymentIntentString {
            // Extract payment intent ID from the client secret string (format: pi_xxx_secret_yyy)
            let components = paymentIntentString.components(separatedBy: "_secret_")
            self.currentPaymentIntentId = components.first
            print("✅ [Payment Sheet] Payment intent ID (from string): \(components.first ?? "nil")")
        }
        
        // Initialize PaymentSheet with the payment intent client secret
        self.paymentSheet = PaymentSheet(
            paymentIntentClientSecret: clientSecret,
            configuration: configuration
        )
        self.isPaymentReady = true
        
        print("✅ [Payment Sheet] Prepared successfully")
        print("  - Client Secret: \(clientSecret.prefix(20))...")
        print("  - isPaymentReady: true")
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
                print("✅ [Prescription Payment] Success - will reset on return to prescription list")
            }
            return response
            
        case .failed(let error):
            errorMessage = "Payment failed: \(error.localizedDescription)"
            showErrorToast = true
            print("❌ [Prescription Payment] Failed - will reset on return to prescription list")
            return nil
            
        case .canceled:
            errorMessage = "Payment was canceled"
            showErrorToast = true
            print("⚠️ [Prescription Payment] Canceled - will reset on return to prescription list")
            return nil
        }
    }
    
    // MARK: - Upcoming Appointments

    /// Fetch upcoming appointments (active: pending + confirmed, date >= today)
    public func fetchUpcomingAppointments(perPage: Int = 10, cursor: String? = nil, loadMore: Bool = false) async {
        isLoadingAppointments = true
        errorMessage = nil
        
        do {
            let response = try await bookingService.fetchPatientBookings(type: "active", status: nil, perPage: perPage, cursor: cursor)
            
            if loadMore {
                self.upcomingAppointments.append(contentsOf: response.bookings)
            } else {
                self.upcomingAppointments = response.bookings
            }
            
            self.upcomingNextCursor = response.nextCursor
            self.upcomingHasMore = response.hasMore
            
        } catch {
            errorMessage = error.localizedDescription
            showErrorToast = true
        }
        
        isLoadingAppointments = false
    }
    
    /// Fetch upcoming confirmed appointments only (used by home screen)
    public func fetchUpcomingConfirmedAppointments(perPage: Int = 10, cursor: String? = nil, loadMore: Bool = false) async {
        isLoadingAppointments = true
        errorMessage = nil
        
        do {
            let response = try await bookingService.fetchPatientBookings(type: "active", status: "confirmed", perPage: perPage, cursor: cursor)
            
            if loadMore {
                self.upcomingAppointments.append(contentsOf: response.bookings)
            } else {
                self.upcomingAppointments = response.bookings
            }
            
            self.upcomingNextCursor = response.nextCursor
            self.upcomingHasMore = response.hasMore
            
        } catch {
            errorMessage = error.localizedDescription
            showErrorToast = true
        }
        
        isLoadingAppointments = false
    }
    
    /// Load next page of appointments
    public func loadMoreAppointments() async {
        guard upcomingHasMore else { return }
        await fetchUpcomingConfirmedAppointments(cursor: upcomingNextCursor, loadMore: true)
    }
    
    /// Refresh appointments (reset to first page)
    public func refreshAppointments() async {
        upcomingNextCursor = nil
        await fetchUpcomingConfirmedAppointments(cursor: nil, loadMore: false)
    }
    
    // MARK: - Past Appointments
    
    /// Fetch past bookings (completed + cancelled, all dates)
    public func fetchPastBookings(perPage: Int = 10, cursor: String? = nil, loadMore: Bool = false) async {
        isLoadingPastAppointments = true
        errorMessage = nil
        
        do {
            let response = try await bookingService.fetchPatientBookings(type: "past", status: nil, perPage: perPage, cursor: cursor)
            
            if loadMore {
                self.pastAppointments.append(contentsOf: response.bookings)
            } else {
                self.pastAppointments = response.bookings
            }
            
            self.pastNextCursor = response.nextCursor
            self.pastHasMore = response.hasMore
            
        } catch {
            errorMessage = error.localizedDescription
            showErrorToast = true
        }
        
        isLoadingPastAppointments = false
    }
    
    /// Load next page of past appointments
    public func loadMorePastAppointments() async {
        guard pastHasMore else { return }
        await fetchPastBookings(cursor: pastNextCursor, loadMore: true)
    }
    
    /// Refresh past appointments (reset to first page)
    public func refreshPastAppointments() async {
        pastNextCursor = nil
        await fetchPastBookings(cursor: nil, loadMore: false)
    }
    
    // MARK: - Active Bookings For Doctor
    
    /// Fetch active bookings for doctor: unassigned pending + accepted upcoming.
    /// Splits the combined list into `pendingBookings` (unclaimed) and `myBookings` (accepted).
    public func fetchPendingBookingsForDoctor() async {
        isLoadingPendingBookings = true
        isLoadingMyBookings = true
        errorMessage = nil
        
        do {
            let response = try await bookingService.fetchDoctorBookings(type: "active", perPage: 50, cursor: nil)
            self.pendingBookings = response.bookingsList.filter { $0.doctorStatus == "pending" }
            self.myBookings = response.bookingsList.filter { $0.doctorStatus == "accepted" }
        } catch {
            errorMessage = error.localizedDescription
            showErrorToast = true
        }
        
        isLoadingPendingBookings = false
        isLoadingMyBookings = false
    }
    
    /// Refresh active bookings
    public func refreshPendingBookings() async {
        await fetchPendingBookingsForDoctor()
    }
    
    // MARK: - Doctor Booking History
    
    /// Fetch past/completed bookings for doctor with cursor pagination
    public func fetchDoctorBookingHistory(perPage: Int = 15, cursor: String? = nil, loadMore: Bool = false) async {
        isLoadingDoctorHistory = true
        errorMessage = nil
        
        do {
            let response = try await bookingService.fetchDoctorBookings(type: "past", perPage: perPage, cursor: cursor)
            
            if loadMore {
                self.doctorBookingHistory.append(contentsOf: response.bookingsList)
            } else {
                self.doctorBookingHistory = response.bookingsList
            }
            self.doctorHistoryNextCursor = response.nextCursor
            self.doctorHistoryHasMore = response.hasMore
            self.doctorHistoryPerPage = response.perPage
        } catch {
            errorMessage = error.localizedDescription
            showErrorToast = true
        }
        
        isLoadingDoctorHistory = false
    }
    
    /// Load next page of doctor booking history
    public func loadMoreDoctorBookingHistory() async {
        guard doctorHistoryHasMore else { return }
        await fetchDoctorBookingHistory(perPage: doctorHistoryPerPage, cursor: doctorHistoryNextCursor, loadMore: true)
    }
    
    /// Refresh doctor booking history
    public func refreshDoctorBookingHistory() async {
        doctorHistoryNextCursor = nil
        await fetchDoctorBookingHistory(loadMore: false)
    }
    
    // MARK: - Prescriptions
    
    /// Fetch active prescriptions for patient
    public func fetchPrescriptions(perPage: Int = 15, cursor: String? = nil, loadMore: Bool = false) async {
        isLoadingPrescriptions = true
        errorMessage = nil
        
        do {
            let response = try await bookingService.fetchPrescriptions(type: "active", perPage: perPage, cursor: cursor)
            
            if loadMore {
                self.prescriptions.append(contentsOf: response.prescriptions)
            } else {
                self.prescriptions = response.prescriptions
            }
            self.prescriptionsNextCursor = response.nextCursor
            self.prescriptionsHasMore = response.hasMore
        } catch {
            errorMessage = error.localizedDescription
            showErrorToast = true
        }
        
        isLoadingPrescriptions = false
    }
    
    /// Load next page of prescriptions
    public func loadMorePrescriptions() async {
        guard prescriptionsHasMore else { return }
        await fetchPrescriptions(cursor: prescriptionsNextCursor, loadMore: true)
    }
    
    /// Refresh prescriptions
    public func refreshPrescriptions() async {
        prescriptionsNextCursor = nil
        await fetchPrescriptions(loadMore: false)
    }
    
    // MARK: - Prescription History
    
    /// Fetch past prescriptions for patient
    public func fetchPrescriptionHistory(perPage: Int = 15, cursor: String? = nil, loadMore: Bool = false) async {
        isLoadingPrescriptionHistory = true
        errorMessage = nil
        
        do {
            let response = try await bookingService.fetchPrescriptions(type: "past", perPage: perPage, cursor: cursor)
            
            if loadMore {
                self.prescriptionHistory.append(contentsOf: response.prescriptions)
            } else {
                self.prescriptionHistory = response.prescriptions
            }
            self.prescriptionHistoryNextCursor = response.nextCursor
            self.prescriptionHistoryHasMore = response.hasMore
        } catch {
            errorMessage = error.localizedDescription
            showErrorToast = true
        }
        
        isLoadingPrescriptionHistory = false
    }
    
    /// Load next page of prescription history
    public func loadMorePrescriptionHistory() async {
        guard prescriptionHistoryHasMore else { return }
        await fetchPrescriptionHistory(cursor: prescriptionHistoryNextCursor, loadMore: true)
    }
    
    /// Refresh prescription history
    public func refreshPrescriptionHistory() async {
        prescriptionHistoryNextCursor = nil
        await fetchPrescriptionHistory(loadMore: false)
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
    
    // MARK: - Video Call Methods
    
    /// Generate Agora token and start video call (for doctor)
    public func generateTokenAndStartCall(booking: BookingData) async {
        isLoading = true
        errorMessage = nil
        
        // ── TEST MODE ─────────────────────────────────────────────────────────
        // When enabled, skip the token API entirely and use hard-coded credentials.
        // Flip VideoCallTestConfig.isEnabled = false before shipping to production.
        if VideoCallTestConfig.isEnabled {
            print("🧪 [BookingVM] Test mode ON — using hardcoded Agora credentials (doctor)")
            await MainActor.run {
                Router.shared.push(.videoCall(
                    booking: booking,
                    token: VideoCallTestConfig.token,
                    channelName: VideoCallTestConfig.channelName,
                    uid: VideoCallTestConfig.doctorUID
                ))
                isLoading = false
            }
            return
        }
        // ──────────────────────────────────────────────────────────────────────
        
        do {
            // Build channel name: prefer agora_session_id from booking, else construct one
            let channelName = booking.agoraSessionId ?? "booking_\(booking.id)_\(Int(Date().timeIntervalSince1970))"
            
            // 1. Generate Agora token from backend
            let tokenResponse = try await bookingService.generateAgoraToken(bookingId: booking.id, channelName: channelName, expireSeconds: 3600)
            
            guard let token = tokenResponse.token,
                  let channel = tokenResponse.channelName,
                  let uid = tokenResponse.uid else {
                throw NSError(domain: "Agora", code: -1, userInfo: [NSLocalizedDescriptionKey: tokenResponse.message ?? "Failed to generate token"])
            }
            
            // 2. Mark call as started in backend
            // TODO: Endpoint not yet implemented — re-enable when available
            // _ = try await bookingService.startVideoCall(bookingId: booking.id)
            
            // 3. Navigate to video call screen
            await MainActor.run {
                Router.shared.push(.videoCall(
                    booking: booking,
                    token: token,
                    channelName: channel,
                    uid: uid
                ))
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to start video call: \(error.localizedDescription)"
                showErrorToast = true
                isLoading = false
            }
        }
    }
    
    /// Generate Agora token and join video call (for patient)
    public func generateTokenAndJoinCall(booking: BookingData) async {
        isLoading = true
        errorMessage = nil
        
        // ── TEST MODE ─────────────────────────────────────────────────────────
        if VideoCallTestConfig.isEnabled {
            print("🧪 [BookingVM] Test mode ON — using hardcoded Agora credentials (patient)")
            await MainActor.run {
                Router.shared.push(.videoCall(
                    booking: booking,
                    token: VideoCallTestConfig.token,
                    channelName: VideoCallTestConfig.channelName,
                    uid: VideoCallTestConfig.patientUID
                ))
                isLoading = false
            }
            return
        }
        // ──────────────────────────────────────────────────────────────────────
        
        do {
            // Build channel name: prefer agora_session_id from booking, else construct one
            let channelName = booking.agoraSessionId ?? "booking_\(booking.id)_\(Int(Date().timeIntervalSince1970))"
            
            // 1. Generate Agora token from backend
            let tokenResponse = try await bookingService.generateAgoraToken(bookingId: booking.id, channelName: channelName, expireSeconds: 3600)
            
            guard let token = tokenResponse.token,
                  let channel = tokenResponse.channelName,
                  let uid = tokenResponse.uid else {
                throw NSError(domain: "Agora", code: -1, userInfo: [NSLocalizedDescriptionKey: tokenResponse.message ?? "Failed to generate token"])
            }
            
            // 2. Navigate to video call screen
            await MainActor.run {
                Router.shared.push(.videoCall(
                    booking: booking,
                    token: token,
                    channelName: channel,
                    uid: uid
                ))
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to join video call: \(error.localizedDescription)"
                showErrorToast = true
                isLoading = false
            }
        }
    }

    // MARK: - Notification Navigation

    /// Fetch booking details by ID and navigate to the appropriate detail screen
    public func navigateToBookingFromNotification(bookingId: Int, userRole: UserType?) async {
        isFetchingBookingDetail = true
        errorMessage = nil

        do {
            let response = try await bookingService.fetchBookingDetails(bookingId: String(bookingId))
            isFetchingBookingDetail = false

            if let booking = response.data {
                if userRole == .doctor {
                    Router.shared.push(.appointmentDetailForDoctor(booking: booking))
                } else {
                    Router.shared.push(.appointmentDetailForPatient(booking: booking))
                }
            } else {
                errorMessage = response.message ?? "Booking not found"
                showErrorToast = true
            }
        } catch {
            isFetchingBookingDetail = false
            errorMessage = error.localizedDescription
            showErrorToast = true
        }
    }
}
