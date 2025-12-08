//
//  CureFromDrugView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 29/11/25.
//

import SwiftUI

struct CureFromDrugView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: Router
    
    // Form fields
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var countryCode: String = "+353"
    @State private var phoneNumber: String = ""
    @State private var selectedDrug: String? = nil
    @State private var selectedYears: String? = nil
    @State private var additionalInfo: String = ""
    
    // Sample data - will be replaced with actual data
    private let drugsOfAddiction = [
        "Alcohol",
        "Cannabis (Marijuana)",
        "Cocaine",
        "Heroin",
        "Methamphetamine",
        "Prescription Opioids",
        "Benzodiazepines",
        "Other"
    ]
    
    private let yearsOfAddiction = [
        "Less than 1 year",
        "1-2 years",
        "3-5 years",
        "6-10 years",
        "More than 10 years"
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
                    VStack(alignment: .leading, spacing: 24) {
                        // Title with icon background
                        Text("Your journey to recovery")
                            .font(theme.typography.medium30)
                            .foregroundStyle(theme.colors.textPrimary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                        
                        // Form fields
                        VStack(spacing: 20) {
                            // Full Name field
                            TextInputField(
                                placeholder: "Full Name",
                                text: $fullName,
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
                            
                            // Drug of addiction dropdown
                            DropdownField(
                                selectedValue: $selectedDrug,
                                items: drugsOfAddiction,
                                placeholder: "Drug of addiction",
                                allowsSearch: true,
                                showsChevron: true
                            )
                            
                            // Years of addiction dropdown
                            DropdownField(
                                selectedValue: $selectedYears,
                                items: yearsOfAddiction,
                                placeholder: "Years of",
                                allowsSearch: false,
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
                            requestConsultant()
                        }) {
                            Text("Request a consultant")
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
    
    private func requestConsultant() {
        hideKeyboard()
        
        // Validate form
        guard !fullName.isEmpty,
              !email.isEmpty,
              !phoneNumber.isEmpty,
              selectedDrug != nil,
              selectedYears != nil else {
            print("Please fill all required fields")
            return
        }
        
        // Handle form submission
        print("Requesting consultant...")
        print("Full Name: \(fullName)")
        print("Email: \(email)")
        print("Phone: \(phoneNumber)")
        print("Drug: \(selectedDrug ?? "")")
        print("Years: \(selectedYears ?? "")")
        print("Additional Info: \(additionalInfo)")
        
        // Navigate to success screen or show confirmation
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    CureFromDrugView()
        .environment(\.appTheme, AppTheme.default)
}
