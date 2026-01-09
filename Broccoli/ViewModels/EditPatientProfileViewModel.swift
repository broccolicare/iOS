//
//  EditPatientProfileViewModel.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 20/11/25.
//

import Foundation
import Combine

@MainActor
final class EditPatientProfileViewModel: ObservableObject {
    
    // Form fields - Personal Information
    @Published var id: Int? = nil
    @Published var fullName: String = ""
    @Published var email: String = ""
    @Published var phoneCountryCode: String = "+353"
    @Published var phoneNumber: String = ""
    @Published var dateOfBirth: Date? = nil
    @Published var selectedGender: String = ""
    @Published var address: String = ""
    @Published var selectedCountry: String = ""
    @Published var postalCode: String = ""
    
    // Form fields - Medical History
    @Published var selectedBloodType: Int? = nil
    @Published var allergies: String = ""
    @Published var chronicConditions: String = ""
    
    // Form fields - Insurance Information
    @Published var insurances: [InsuranceFormData] = [InsuranceFormData()]
    
    // Form fields - Emergency Contact
    @Published var emergencyContactName: String = ""
    @Published var emergencyRelationship: String = ""
    @Published var emergencyCountryCode: String = "+353"
    @Published var emergencyPhoneNumber: String = ""
    
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
        case gender
        case address
        case country
        case postalCode
        case bloodType
        case emergencyContactName
        case emergencyPhoneNumber
        case emergencyRelationship
    }
    
    // MARK: - Load Profile Data
    
    public func loadProfileData(from profileData: UserProfileData?, appViewModel: AppGlobalViewModel? = nil) {
        guard let profileData = profileData else {
            print("⚠️ No profile data available")
            return
        }
        
        print("📋 Loading profile data for: \(profileData.name)")
        
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
            
            // Blood Type - prioritize bloodGroupId, fallback to finding ID from name
            if let bloodGroupId = profile.bloodGroupId {
                selectedBloodType = bloodGroupId
            } else if let bloodGroupName = profile.bloodGroup, let appVM = appViewModel {
                // Find the ID from the name using the blood groups array
                if let bloodGroup = appVM.bloodGroups.first(where: { $0.name == bloodGroupName }) {
                    selectedBloodType = bloodGroup.id
                }
            }
        }
        
        // Emergency Contact - Load from top-level emergencyContact object
        if let emergencyContact = profileData.emergencyContact {
            emergencyContactName = emergencyContact.name ?? ""
            emergencyRelationship = emergencyContact.relationship ?? ""
            
            // Parse emergency contact phone to split country code and phone number
            if let emergencyPhone = emergencyContact.phone, !emergencyPhone.isEmpty {
                // Emergency phone comes as full number like "+35312345678"
                // Extract country code and phone number
                if emergencyPhone.hasPrefix("+") {
                    // Try to find matching country code from available codes
                    if let appVM = appViewModel {
                        // Find the longest matching country code
                        let matchingCode = appVM.phoneCodesOnly
                            .filter { emergencyPhone.hasPrefix($0) }
                            .max(by: { $0.count < $1.count })
                        
                        if let code = matchingCode {
                            emergencyCountryCode = code
                            emergencyPhoneNumber = String(emergencyPhone.dropFirst(code.count))
                        } else {
                            // Fallback: assume +XXX format for country code
                            let endIndex = emergencyPhone.index(emergencyPhone.startIndex, offsetBy: min(4, emergencyPhone.count))
                            emergencyCountryCode = String(emergencyPhone[..<endIndex])
                            emergencyPhoneNumber = String(emergencyPhone[endIndex...])
                        }
                    } else {
                        // No app view model, use default parsing
                        let endIndex = emergencyPhone.index(emergencyPhone.startIndex, offsetBy: min(4, emergencyPhone.count))
                        emergencyCountryCode = String(emergencyPhone[..<endIndex])
                        emergencyPhoneNumber = String(emergencyPhone[endIndex...])
                    }
                } else {
                    // No country code prefix
                    emergencyCountryCode = "+353"
                    emergencyPhoneNumber = emergencyPhone
                }
            }
        }
        
        
        // Chronic Conditions
        if let medicalInfo = profileData.medicalInfo {
            chronicConditions = medicalInfo.knownConditions ?? ""
            
            // Medical History - Allergies
            allergies = medicalInfo.allergies ?? ""
        }
        
        // Insurance Information
        if let insurancesArray = profileData.insurances, !insurancesArray.isEmpty {
            insurances = insurancesArray.map { insurance in
                InsuranceFormData(
                    providerName: insurance.providerName,
                    policyNumber: insurance.policyNumber
                )
            }
        }
        
        print("✅ Profile data loaded successfully")
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
        
        // Validate Emergency Contact Phone (if name is provided)
        if !emergencyContactName.isEmpty {
            let emergencyPhone = emergencyPhoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            if emergencyPhone.isEmpty {
                fieldErrors[.emergencyPhoneNumber] = "Please enter emergency contact phone number."
            } else if emergencyPhone.range(of: "[A-Za-z]", options: .regularExpression) != nil {
                fieldErrors[.emergencyPhoneNumber] = "Phone number should contain only digits."
            } else if emergencyPhone.filter({ $0.isWholeNumber }).count < 6 {
                fieldErrors[.emergencyPhoneNumber] = "Please enter a valid emergency contact number."
            }
            
            if emergencyRelationship.isEmpty {
                fieldErrors[.emergencyRelationship] = "Please select relationship."
            }
        }
        
        return fieldErrors.isEmpty
    }
    
    // MARK: - Prepare Update Data
    
    public func prepareUpdateData() -> [String: Any] {
        var updateData: [String: Any] = [
            "name": fullName,
            "email": email
        ]
        
        // Profile data - Patient-specific fields
        var profileData: [String: Any] = [
            "phone_code": phoneCountryCode,
            "phone": phoneNumber,
            "gender": selectedGender.lowercased()
        ]
        
        // Add optional address fields if not empty
        if !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            profileData["address"] = address
        }
        
        if !selectedCountry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            profileData["country"] = selectedCountry
        }
        
        if !postalCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            profileData["postal_code"] = postalCode
        }
        
        // Add date of birth if provided
        if let dob = dateOfBirth {
            profileData["date_of_birth"] = dateToString(dob)
        }
        
        // Add blood group if selected
        if let bloodType = selectedBloodType {
            profileData["blood_group_id"] = bloodType
        }
        
        // Add emergency contact fields to profile if provided
        if !emergencyContactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            profileData["emergency_contact_name"] = emergencyContactName
            profileData["emergency_contact_relationship"] = emergencyRelationship
            
            // Combine country code and phone number for emergency contact
            let fullEmergencyPhone = emergencyCountryCode + emergencyPhoneNumber
            profileData["emergency_contact_phone"] = fullEmergencyPhone
        }
        
        updateData["profile"] = profileData
        
        // Medical info - Patient-specific
        var medicalInfo: [String: Any] = [:]
        var hasMedicalInfo = false
        
        if !allergies.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            medicalInfo["allergies"] = allergies
            hasMedicalInfo = true
        }
        
        if !chronicConditions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            medicalInfo["known_conditions"] = chronicConditions
            hasMedicalInfo = true
        }
        
        if hasMedicalInfo {
            updateData["medical_info"] = medicalInfo
        }
        
        // Insurance info - Patient-specific
        let validInsurances = insurances.filter { 
            !$0.providerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
            !$0.policyNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
        }
        
        if !validInsurances.isEmpty {
            updateData["insurances"] = validInsurances.map { insurance in
                [
                    "provider_name": insurance.providerName,
                    "policy_number": insurance.policyNumber
                ]
            }
            updateData["replace_insurances"] = true
        } else {
            updateData["replace_insurances"] = false
        }
        
        // Set replace_allergies flag
        updateData["replace_allergies"] = !allergies.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
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
