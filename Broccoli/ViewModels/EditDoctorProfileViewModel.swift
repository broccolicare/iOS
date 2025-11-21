//
//  EditDoctorProfileViewModel.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 20/11/25.
//

import Foundation
import Combine

@MainActor
final class EditDoctorProfileViewModel: ObservableObject {
    
    // Form fields - Personal Information
    @Published var id: Int? = nil
    @Published var fullName: String = ""
    @Published var email: String = ""
    @Published var phoneCountryCode: String = "+353"
    @Published var phoneNumber: String = ""
    @Published var dateOfBirth: Date? = nil
    @Published var selectedSpecializations: [Specialization] = []
    @Published var licenseNumber: String = ""
    @Published var selectedGender: String = ""
    
    // Form fields - Address
    @Published var address: String = ""
    @Published var selectedCountry: String = ""
    @Published var postalCode: String = ""
    
    // Form fields - Available Time Slots
    @Published var selectedTimeSlots: Set<String> = []
    
    // Form fields - Pricing
    @Published var price: String = ""
    @Published var selectedDuration: String = ""
    
    // Validation errors
    @Published private(set) var fieldErrors: [Field: String] = [:]
    
    // UI state
    @Published var isLoading = false
    @Published var showSuccessToast = false
    @Published var showErrorToast = false
    @Published var errorMessage = ""
    
    enum Field: Hashable {
        case fullName
        case email
        case phoneNumber
        case dateOfBirth
        case specialization
        case licenseNumber
        case gender
        case address
        case country
        case postalCode
        case price
        case duration
    }
    
    // MARK: - Load Profile Data
    
    public func loadProfileData(from profileData: UserProfileData?, appViewModel: AppGlobalViewModel? = nil) {
        guard let profileData = profileData else {
            print("⚠️ No profile data available")
            return
        }
        
        print("📋 Loading doctor profile data for: \(profileData.name)")
        
        // Personal Information
        fullName = profileData.name
        email = profileData.email
        id = profileData.id
        
        if let profile = profileData.profile {
            phoneCountryCode = profile.phoneCode ?? "+353"
            phoneNumber = profile.phone ?? ""
            
            // Convert date string to Date
            if let dobString = profile.dateOfBirth {
                dateOfBirth = stringToDate(dobString)
            }
            
            selectedGender = profile.gender ?? ""
            address = profile.address ?? ""
            selectedCountry = profile.country ?? ""
            postalCode = profile.postalCode ?? ""
            licenseNumber = "Lic. No"//profile.medicalLicenseNumber ?? ""
        }
        
        // Load specializations
        if let specializationNames = profileData.specializations,
           let appVM = appViewModel {
            // Find the Specialization objects from the names
            selectedSpecializations = specializationNames.compactMap { name in
                appVM.specializations.first(where: { $0.name == name })
            }
        }
        
        // TODO: Load time slots and pricing from profile data when API provides them
        
        print("✅ Doctor profile data loaded successfully")
    }
    
    // MARK: - Validation
    
    public func validateProfileFields() -> Bool {
        fieldErrors = [:] // reset
        
        // Validate Full Name
        if fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fieldErrors[.fullName] = "Please enter your full name."
        }
        
        // Validate Email
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fieldErrors[.email] = "Please enter your email."
        } else if !Validator.isValidEmail(email) {
            fieldErrors[.email] = "Please enter a valid email address."
        }
        
        // Validate Phone Number
        let numericPhone = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        if !numericPhone.isEmpty {
            if numericPhone.range(of: "[A-Za-z]", options: .regularExpression) != nil {
                fieldErrors[.phoneNumber] = "Phone number should contain only digits."
            } else if numericPhone.filter({ $0.isWholeNumber }).count < 6 {
                fieldErrors[.phoneNumber] = "Please enter a valid mobile number."
            }
        }
        
        // Validate Date of Birth (optional but if provided, should be valid)
        if let dob = dateOfBirth {
            if dob > Date() {
                fieldErrors[.dateOfBirth] = "Date of birth cannot be in the future."
            }
        }
        
        // Validate Specialization
        if selectedSpecializations.isEmpty {
            fieldErrors[.specialization] = "Please select at least one specialization."
        }
        
        // Validate License Number
        if licenseNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fieldErrors[.licenseNumber] = "Please enter your license number."
        }
        
        // Validate Price
        if !price.isEmpty {
            if let priceValue = Double(price), priceValue <= 0 {
                fieldErrors[.price] = "Please enter a valid price."
            } else if Double(price) == nil {
                fieldErrors[.price] = "Please enter a valid price."
            }
        }
        
        return fieldErrors.isEmpty
    }
    
    // MARK: - Prepare Update Data
    
    public func prepareUpdateData() -> [String: Any] {
        var updateData: [String: Any] = [
            "name": fullName,
            "email": email,
            "id": id ?? 0
        ]
        
        // Profile data
        var profileData: [String: Any] = [
            "phone_code": phoneCountryCode,
            "phone": phoneNumber,
            "address": address,
            "country": selectedCountry,
            "postal_code": postalCode,
            "gender": selectedGender,
            "medical_license_number": licenseNumber
        ]
        
        if let dob = dateOfBirth {
            profileData["date_of_birth"] = dateToString(dob)
        }
        
        updateData["profile"] = profileData
        
        // Specializations - send array of IDs
        if !selectedSpecializations.isEmpty {
            updateData["specialization_ids"] = selectedSpecializations.map { $0.id }
        }
        
        // Time slots and pricing
        if !selectedTimeSlots.isEmpty {
            updateData["available_time_slots"] = Array(selectedTimeSlots)
        }
        
        if !price.isEmpty {
            updateData["consultation_fee"] = price
        }
        
        if !selectedDuration.isEmpty {
            // Convert duration string to minutes (e.g., "30 min" -> 30)
            let durationValue = selectedDuration.replacingOccurrences(of: " min", with: "")
            updateData["consultation_duration"] = Int(durationValue) ?? 30
        }
        
        return updateData
    }
    
    // MARK: - Helper Functions
    
    private func stringToDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
    
    private func dateToString(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
