//
//  EditPharmacyViewModel.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 24/12/25.
//

import Foundation
import Combine

@MainActor
final class EditPharmacyViewModel: ObservableObject {
    
    // Form fields
    @Published var pharmacyId: Int
    @Published var pharmacyName: String = ""
    @Published var licenseNumber: String = ""
    @Published var email: String = ""
    @Published var countryCode: String = "+353"
    @Published var phoneNumber: String = ""
    @Published var streetAddress: String = ""
    @Published var city: String = ""
    @Published var state: String = ""
    @Published var postalCode: String = ""
    @Published var selectedCountryISO: String = ""
    
    @Published private(set) var fieldErrors: [Field: String] = [:]
    
    enum Field: Hashable {
        case pharmacyName, licenseNumber, email, phone, streetAddress, city, state, postalCode, selectedCountry
    }
    
    // MARK: - Initialization
    
    init(pharmacy: Pharmacy) {
        self.pharmacyId = pharmacy.id
        self.pharmacyName = pharmacy.name
        self.licenseNumber = pharmacy.licenseNumber ?? ""
        self.email = pharmacy.email ?? ""
        self.streetAddress = pharmacy.address ?? ""
        self.city = pharmacy.city ?? ""
        self.state = pharmacy.state ?? ""
        self.postalCode = pharmacy.postalCode ?? ""
        self.selectedCountryISO = pharmacy.country ?? ""
        
        // Extract country code and phone number from full phone
        if let phone = pharmacy.phone {
            extractPhoneComponents(from: phone)
        }
    }
    
    // MARK: - Helper Methods
    
    private func extractPhoneComponents(from fullPhone: String) {
        // Try to extract country code (assumes format like "+353123456789")
        if fullPhone.hasPrefix("+") {
            // Find where the country code ends (typically 1-3 digits after +)
            let digits = fullPhone.dropFirst().prefix(while: { $0.isNumber })
            if digits.count <= 4 { // Reasonable country code length
                self.countryCode = "+\(digits)"
                let remainingIndex = fullPhone.index(fullPhone.startIndex, offsetBy: digits.count + 1)
                self.phoneNumber = String(fullPhone[remainingIndex...])
            } else {
                // Fallback: use default country code
                self.phoneNumber = String(fullPhone.dropFirst())
            }
        } else {
            // No + prefix, use as-is
            self.phoneNumber = fullPhone
        }
    }
    
    // MARK: - Validation
    
    public func validatePharmacyFields() -> Bool {
        fieldErrors = [:] // Reset errors
        
        if pharmacyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fieldErrors[.pharmacyName] = "Please enter pharmacy name."
        }
        
        if licenseNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fieldErrors[.licenseNumber] = "Please enter license number."
        }
        
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fieldErrors[.email] = "Please enter email address."
        } else if !Validator.isValidEmail(email) {
            fieldErrors[.email] = "Please enter a valid email address."
        }
        
        let numericPhone = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        if numericPhone.isEmpty {
            fieldErrors[.phone] = "Please enter phone number."
        } else if numericPhone.range(of: "[A-Za-z]", options: .regularExpression) != nil {
            fieldErrors[.phone] = "Phone number should contain only digits."
        } else if numericPhone.filter({ $0.isWholeNumber }).count < 6 {
            fieldErrors[.phone] = "Please enter a valid phone number."
        }
        
        if streetAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fieldErrors[.streetAddress] = "Please enter street address."
        }
        
        if city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fieldErrors[.city] = "Please enter city."
        }
        
        if state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fieldErrors[.state] = "Please enter state."
        }
        
        if postalCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fieldErrors[.postalCode] = "Please enter postal code."
        }
        
        if selectedCountryISO.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fieldErrors[.selectedCountry] = "Please select a country."
        }
        
        return fieldErrors.isEmpty
    }
}
