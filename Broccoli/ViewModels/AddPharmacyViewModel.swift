//
//  AddPharmacyViewModel.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 23/12/25.
//

import Foundation
import Combine

@MainActor
final class AddPharmacyViewModel: ObservableObject {
    
    // Form fields
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
