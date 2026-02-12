//
//  MedicalEnquiryViewModel.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 09/01/26.
//

import Foundation
import Combine

@MainActor
final class MedicalEnquiryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    // Form fields
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var countryCode: String = "+353"
    @Published var phoneNumber: String = ""
    @Published var password: String = ""
    @Published var selectedProcedure: String? = nil
    @Published var selectedProcedureId: Int? = nil
    @Published var selectedDestination: String? = nil
    @Published var selectedDestinationId: Int? = nil
    @Published var additionalInfo: String = ""
    
    // Validation errors
    @Published private(set) var fieldErrors: [Field: String] = [:]
    
    // UI state
    @Published var isLoading = false
    @Published var showSuccessToast = false
    @Published var showErrorToast = false
    @Published var errorMessage = ""
    @Published var successMessage = ""
    @Published var shouldDismiss = false
    
    enum Field: Hashable {
        case name
        case email
        case phoneNumber
        case password
        case procedure
        case destination
    }
    
    // MARK: - Dependencies
    
    private let userService: UserServiceProtocol
    
    // MARK: - Initialization
    
    init(userService: UserServiceProtocol) {
        self.userService = userService
    }
    
    // MARK: - Validation
    
    public func validateFields() -> Bool {
        fieldErrors = [:] // reset
        
        // Name validation - required, max 255 characters
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            fieldErrors[.name] = "Please enter your name."
        } else if trimmedName.count > 255 {
            fieldErrors[.name] = "Name must not exceed 255 characters."
        }
        
        // Email validation - required, valid email, max 255 characters
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedEmail.isEmpty {
            fieldErrors[.email] = "Please enter your email."
        } else if !Validator.isValidEmail(trimmedEmail) {
            fieldErrors[.email] = "Please enter a valid email address."
        } else if trimmedEmail.count > 255 {
            fieldErrors[.email] = "Email must not exceed 255 characters."
        }
        
        // Phone number validation - required, max 20 characters
        let trimmedPhone = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedPhone.isEmpty {
            fieldErrors[.phoneNumber] = "Please enter your phone number."
        } else if trimmedPhone.count > 20 {
            fieldErrors[.phoneNumber] = "Phone number must not exceed 20 characters."
        }
        
        // Password validation - required, min 8 characters
        if password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fieldErrors[.password] = "Please enter a password."
        } else if password.count < 8 {
            fieldErrors[.password] = "Password must be at least 8 characters."
        }
        
        // Procedure validation - required, max 255 characters
        if selectedProcedure == nil || selectedProcedure?.isEmpty == true {
            fieldErrors[.procedure] = "Please select a procedure."
        } else if selectedProcedureId == nil {
            fieldErrors[.procedure] = "Invalid procedure selection."
        }
        
        // Destination validation - required
        if selectedDestination == nil || selectedDestination?.isEmpty == true {
            fieldErrors[.destination] = "Please select a destination."
        } else if selectedDestinationId == nil {
            fieldErrors[.destination] = "Invalid destination selection."
        }
        
        return fieldErrors.isEmpty
    }
    
    // MARK: - API Call
    
    public func submitEnquiry() async {
        // Validate fields first
        guard validateFields() else {
            errorMessage = "Please fill all required fields correctly."
            showErrorToast = true
            return
        }
        
        isLoading = true
        showErrorToast = false
        showSuccessToast = false
        
        // Combine country code and phone number
        let fullPhoneNumber = countryCode + phoneNumber
        
        // Create request object
        let request = MedicalTourismEnquiryRequest(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: fullPhoneNumber,
            password: password,
            medicalProcedureId: selectedProcedureId ?? 0,
            medicalDestinationId: selectedDestinationId ?? 0,
            additionalInformation: additionalInfo.isEmpty ? nil : additionalInfo.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        do {
            let response = try await userService.submitMedicalTourismEnquiry(request: request)
            
            isLoading = false
            
            // API always returns success if no error is thrown
            successMessage = response.message
            showSuccessToast = true
            
            // Reset form after successful submission
            resetForm()
            
            // Dismiss view after a short delay
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            shouldDismiss = true
        } catch let error as ServiceError {
            isLoading = false
            handleServiceError(error)
        } catch {
            isLoading = false
            errorMessage = "An unexpected error occurred. Please try again."
            showErrorToast = true
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleServiceError(_ error: ServiceError) {
        switch error {
        case .server(let message):
            errorMessage = message
        case .unauthorized(let message):
            errorMessage = message
        case .validation(let message):
            errorMessage = message
        case .unknown(let message):
            errorMessage = message.isEmpty ? "An error occurred. Please try again." : message
        }
        showErrorToast = true
    }
    
    private func resetForm() {
        name = ""
        email = ""
        countryCode = "+353"
        phoneNumber = ""
        password = ""
        selectedProcedure = nil
        selectedProcedureId = nil
        selectedDestination = nil
        selectedDestinationId = nil
        additionalInfo = ""
        fieldErrors = [:]
    }
    
    // MARK: - Public Methods
    
    public func clearError(for field: Field) {
        fieldErrors[field] = nil
    }
    
    public func clearAllErrors() {
        fieldErrors = [:]
    }
}
