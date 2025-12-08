//
//  MedicalEnquiryView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 29/11/25.
//

import SwiftUI

struct MedicalEnquiryView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: Router
    
    // Form fields
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var countryCode: String = "+353"
    @State private var phoneNumber: String = ""
    @State private var password: String = ""
    @State private var selectedProcedure: String? = nil
    @State private var selectedDestination: String? = nil
    @State private var additionalInfo: String = ""
    
    // Sample data - will be replaced with actual data
    private let procedures = [
        "Cardiac Surgery",
        "Orthopedic Surgery",
        "Cosmetic Surgery",
        "Dental Procedures",
        "Eye Surgery",
        "Cancer Treatment",
        "Organ Transplant",
        "Fertility Treatment"
    ]
    
    private let destinations = [
        "India",
        "Thailand",
        "Singapore",
        "Turkey",
        "UAE",
        "Malaysia",
        "South Korea",
        "Mexico"
    ]
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { router.pop() }) {
                        Image("BackButton")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(theme.colors.primary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Title with icon background
                        Text("Medical Tourism")
                            .font(theme.typography.medium30)
                            .foregroundStyle(theme.colors.textPrimary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                        
                        // Form fields
                        VStack(spacing: 12) {
                            // Name field
                            TextInputField(
                                placeholder: "Name",
                                text: $name,
                                keyboardType: .default,
                                autocapitalization: .words,
                                disableAutocorrection: false
                            )
                            
                            // Email field
                            TextInputField(
                                placeholder: "Email address",
                                text: $email,
                                keyboardType: .emailAddress,
                                autocapitalization: .never
                            )
                            
                            // Phone number field
                            CountryPhoneField(
                                countryCode: $countryCode,
                                phone: $phoneNumber
                            )
                            
                            // Desired Procedure dropdown
                            DropdownField(
                                selectedValue: $selectedProcedure,
                                items: procedures,
                                placeholder: "Desired Procedure",
                                allowsSearch: true,
                                showsChevron: true
                            )
                            
                            // Preferred Destination dropdown
                            DropdownField(
                                selectedValue: $selectedDestination,
                                items: destinations,
                                placeholder: "Preferred Destination",
                                allowsSearch: true,
                                showsChevron: true
                            )
                            
                            // Additional Information textarea
                            VStack(alignment: .leading, spacing: 8) {
                                TextEditor(text: $additionalInfo)
                                    .font(theme.typography.callout)
                                    .foregroundStyle(theme.colors.textPrimary)
                                    .frame(height: 120)
                                    .padding(12)
                                    .background(theme.colors.surface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: theme.cornerRadius)
                                            .stroke(theme.colors.border, lineWidth: 1)
                                    )
                                    .cornerRadius(theme.cornerRadius)
                                    .overlay(
                                        Group {
                                            if additionalInfo.isEmpty {
                                                Text("Additional Information")
                                                    .font(theme.typography.callout)
                                                    .foregroundStyle(theme.colors.textSecondary)
                                                    .padding(.leading, 16)
                                                    .padding(.top, 20)
                                                    .allowsHitTesting(false)
                                            }
                                        },
                                        alignment: .topLeading
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Submit button
                        Button(action: {
                            submitEnquiry()
                        }) {
                            Text("Submit Enquiry")
                                .font(theme.typography.button)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(theme.colors.primary)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // Bottom spacing
                        Color.clear.frame(height: 40)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Helper Functions
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func submitEnquiry() {
        hideKeyboard()
        
        // Validate form
        guard !name.isEmpty,
              !email.isEmpty,
              !phoneNumber.isEmpty,
              !password.isEmpty,
              selectedProcedure != nil,
              selectedDestination != nil else {
            print("Please fill all required fields")
            return
        }
        
        // Handle form submission
        print("Submitting enquiry...")
        print("Name: \(name)")
        print("Email: \(email)")
        print("Phone: \(phoneNumber)")
        print("Procedure: \(selectedProcedure ?? "")")
        print("Destination: \(selectedDestination ?? "")")
        print("Additional Info: \(additionalInfo)")
        
        // Navigate to success screen or show confirmation
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    MedicalEnquiryView()
        .environment(\.appTheme, AppTheme.default)
}
