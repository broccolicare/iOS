//
//  SignupViewModel.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 16/10/25.
//

import Foundation
import Combine

@MainActor
final class SignupViewModel: ObservableObject {
    
    
    @Published var name: String = ""
    @Published var username: String = ""
    @Published var email: String = ""
    @Published var gender: String = "Male"
    @Published var countryCode: String = "+353"
    @Published var phone: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    
    @Published var userType: UserType = .patient
    @Published var medicalLicense: String = ""
    @Published var specializations: [Specialization]? = nil
    @Published var description: String = ""
    
    @Published private(set) var fieldErrors: [Field: String] = [:]
    
    enum Field: Hashable {
        case name, username, email, gender, countryCode, phone,  password, confirmPassword, medicalLicense, specializations, description
    }
    
    
    
    //MARK: - Validation
    public func validateSignupFields() -> Bool {
        fieldErrors = [:] // reset
        
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fieldErrors[.name] = "Please enter your full name."
        }
        
        if username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fieldErrors[.username] = "Please enter your username."
        }
        
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fieldErrors[.email] = "Please enter your email."
        } else if !Validator.isValidEmail(email) {
            fieldErrors[.email] = "Please enter a valid email address."
        }
        
        let numericPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        if numericPhone.isEmpty {
            fieldErrors[.phone] = "Please enter your mobile number."
        } else if numericPhone.range(of: "[A-Za-z]", options: .regularExpression) != nil {
            fieldErrors[.phone] = "Phone number should contain only digits."
        } else if numericPhone.filter({ $0.isWholeNumber }).count < 6 {
            fieldErrors[.phone] = "Please enter a valid mobile number."
        }
        
        if password.count < 8 {
            fieldErrors[.password] = "Password must be at least 8 characters."
        }
        if password != confirmPassword {
            fieldErrors[.confirmPassword] = "Passwords do not match."
        }
        
        if userType == .doctor {
            if medicalLicense.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                fieldErrors[.medicalLicense] = "Please enter your medical license number."
            }
            if specializations?.isEmpty ?? true {
                fieldErrors[.specializations] = "Please select your specialization."
            }
        }
        
        return fieldErrors.isEmpty
    }
}
