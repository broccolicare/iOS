//
//  ContactUsViewModel.swift
//  Broccoli
//
//  Created by AI Assistant on 12/02/26.
//

import Foundation
import Combine

@MainActor
final class ContactUsViewModel: ObservableObject {
    
    // Form fields
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var subject: String = ""
    @Published var message: String = ""
    
    @Published private(set) var fieldErrors: [Field: String] = [:]
    @Published var isLoading: Bool = false
    
    enum Field: Hashable {
        case name, email, subject, message
    }
    
    // MARK: - Validation
    
    public func validateContactFields() -> Bool {
        fieldErrors = [:] // Reset errors
        
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fieldErrors[.name] = "Please enter your name."
        }
        
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fieldErrors[.email] = "Please enter email address."
        } else if !Validator.isValidEmail(email) {
            fieldErrors[.email] = "Please enter a valid email address."
        }
        
        if subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fieldErrors[.subject] = "Please enter a subject."
        }
        
        if message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fieldErrors[.message] = "Please enter your message."
        } else if message.trimmingCharacters(in: .whitespacesAndNewlines).count < 10 {
            fieldErrors[.message] = "Message must be at least 10 characters."
        }
        
        return fieldErrors.isEmpty
    }
    
    // MARK: - Reset Form
    
    public func resetForm() {
        name = ""
        email = ""
        subject = ""
        message = ""
        fieldErrors = [:]
    }
}
