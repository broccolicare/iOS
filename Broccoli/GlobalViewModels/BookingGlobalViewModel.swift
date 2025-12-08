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
    @Published public var selectedSpeciality: String? = nil
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
    
    // Booking history
    @Published public var currentBookingId: String? = nil
    
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
        selectedSpeciality = nil
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
        currentBookingId = nil
        errorMessage = nil
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
                departmentId: selectedDepartmentId
            )
            
            if response.success {
                // Store slots by period
                morningSlots = response.slots?.morning ?? []
                afternoonSlots = response.slots?.afternoon ?? []
                eveningSlots = response.slots?.evening ?? []
                
                // Combine all available slots for backward compatibility
                let allSlots = (morningSlots + afternoonSlots + eveningSlots).filter { $0.available }
                availableTimeSlots = allSlots.map { $0.displayTime }
                
                // Store pricing info
                pricingInfo = response.pricing
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
        
        // Optional: service_id
        paymentData["service_id"] = 1
        
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
        
        // Optional: service_id
        confirmData["service_id"] = 1
        
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
        guard let paymentIntent = response.paymentIntent else {
            errorMessage = "Invalid payment response from server"
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
        
        // If customer info is provided, add it to configuration
        if let customer = response.customer,
           let ephemeralKey = response.ephemeralKey {
            configuration.customer = .init(
                id: customer.id,
                ephemeralKeySecret: ephemeralKey.secret
            )
        }
        
        // Store payment intent ID for later use
        self.currentPaymentIntentId = paymentIntent.id
        
        // Initialize PaymentSheet with the payment intent client secret
        self.paymentSheet = PaymentSheet(
            paymentIntentClientSecret: paymentIntent.clientSecret,
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
            errorMessage = "Payment failed: \\(error.localizedDescription)"
            showErrorToast = true
            return nil
            
        case .canceled:
            errorMessage = "Payment was canceled"
            showErrorToast = true
            return nil
        }
    }
}
