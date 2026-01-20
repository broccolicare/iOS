//
//  CureFromDrugViewModel.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 12/01/26.
//

import Foundation
import Combine

@MainActor
final class CureFromDrugViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    // Form fields
    @Published var fullName: String = ""
    @Published var email: String = ""
    @Published var countryCode: String = "+353"
    @Published var phoneNumber: String = ""
    @Published var selectedDrug: String? = nil
    @Published var selectedYears: String? = nil
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
        case fullName
        case email
        case phoneNumber
        case selectedDrug
        case selectedYears
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
        
        // Full name validation - required, max 255 characters
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            fieldErrors[.fullName] = "Please enter your full name."
        } else if trimmedName.count > 255 {
            fieldErrors[.fullName] = "Name must not exceed 255 characters."
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
        
        // Drug validation - required, max 255 characters
        if selectedDrug == nil || selectedDrug?.isEmpty == true {
            fieldErrors[.selectedDrug] = "Please select a drug of addiction."
        } else if let drug = selectedDrug, drug.count > 255 {
            fieldErrors[.selectedDrug] = "Drug must not exceed 255 characters."
        }
        
        // Years validation - required, max 255 characters
        if selectedYears == nil || selectedYears?.isEmpty == true {
            fieldErrors[.selectedYears] = "Please select years of addiction."
        } else if let years = selectedYears, years.count > 255 {
            fieldErrors[.selectedYears] = "Years must not exceed 255 characters."
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
        let request = RecoveryJourneyEnquiryRequest(
            name: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: fullPhoneNumber,
            drug: selectedDrug ?? "",
            years: selectedYears ?? "1",
            additionalInformation: additionalInfo.isEmpty ? nil : additionalInfo.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        do {
            let response = try await userService.submitRecoveryJourneyEnquiry(request: request)
            
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
        fullName = ""
        email = ""
        countryCode = "+353"
        phoneNumber = ""
        selectedDrug = nil
        selectedYears = nil
        additionalInfo = ""
        fieldErrors = [:]
    }
    
    // M
    public func clearError(for field: Field) {
        fieldErrors[field] = nil
    }
    
    public func clearAllErrors() {
        fieldErrors = [:]
    }
}
