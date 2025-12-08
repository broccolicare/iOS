//
//  AddPharmacyView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 29/11/25.
//

import SwiftUI

struct AddPharmacyView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: Router
    
    // Form fields
    @State private var pharmacyName: String = ""
    @State private var email: String = ""
    @State private var countryCode: String = "+353"
    @State private var phoneNumber: String = ""
    @State private var streetAddress: String = ""
    @State private var city: String = ""
    @State private var postalCode: String = ""
    @State private var country: String = ""
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background with gradient header
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [theme.colors.gradientStart, theme.colors.gradientEnd],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 160)
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { router.pop() }) {
                        Image("back-icon-white")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(theme.colors.primary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                
                // Pharmacy Icon
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 120, height: 120)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: "cross.case.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(theme.colors.primary)
                }
                
                // Form Content
                ScrollView(showsIndicators: false) {
                    VStack(alignment:.leading,spacing: 16) {
                        Text("Basic Information")
                            .font(theme.typography.semiBold18)
                            .foregroundColor(theme.colors.textPrimary)
                        // Pharmacy Name
                        TextInputField(
                            placeholder: "Aerie Pharmaceuticals Ireland Limited",
                            text: $pharmacyName,
                            keyboardType: .default,
                            autocapitalization: .words,
                            disableAutocorrection: false
                        )
                        
                        // Email
                        TextInputField(
                            placeholder: "james.hudson010@gmail.com",
                            text: $email,
                            keyboardType: .emailAddress,
                            autocapitalization: .never
                        )
                        
                        // Phone Number
                        CountryPhoneField(
                            countryCode: $countryCode,
                            phone: $phoneNumber
                        )
                        
                        Text("Contact Information")
                            .font(theme.typography.semiBold18)
                            .foregroundColor(theme.colors.textPrimary)
                        // Street Address
                        TextInputField(
                            placeholder: "IDA Technology Park, Garrycastle, Athlone",
                            text: $streetAddress,
                            keyboardType: .default,
                            autocapitalization: .words,
                            disableAutocorrection: false
                        )
                        
                        // City and Postal Code in same row
                        HStack(spacing: 12) {
                            TextInputField(
                                placeholder: "Westmeath",
                                text: $city,
                                keyboardType: .default,
                                autocapitalization: .words,
                                disableAutocorrection: false
                            )
                            
                            TextInputField(
                                placeholder: "DW40",
                                text: $postalCode,
                                keyboardType: .default,
                                autocapitalization: .characters
                            )
                        }
                        
                        // Country
                        TextInputField(
                            placeholder: "Ireland",
                            text: $country,
                            keyboardType: .default,
                            autocapitalization: .words,
                            disableAutocorrection: false
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 40)
                    .padding(.bottom, 100)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
                
                Spacer()
            }
            
            // Save Button (Fixed at bottom)
            VStack {
                Spacer()
                
                Button(action: {
                    savePharmacy()
                }) {
                    Text("Save")
                        .font(theme.typography.button)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(theme.colors.primary)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .background(
                    Color.white
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5)
                )
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Helper Functions
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func savePharmacy() {
        hideKeyboard()
        
        // Validate form
        guard !pharmacyName.isEmpty,
              !email.isEmpty,
              !phoneNumber.isEmpty,
              !streetAddress.isEmpty,
              !city.isEmpty,
              !postalCode.isEmpty,
              !country.isEmpty else {
            print("Please fill all required fields")
            return
        }
        
        // Handle form submission
        print("Saving pharmacy...")
        print("Pharmacy Name: \(pharmacyName)")
        print("Email: \(email)")
        print("Phone: \(phoneNumber)")
        print("Address: \(streetAddress), \(city), \(postalCode), \(country)")
        
        // Navigate back after saving
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    AddPharmacyView()
        .environment(\.appTheme, AppTheme.default)
}
