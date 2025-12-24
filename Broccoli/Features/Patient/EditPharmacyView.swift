//
//  EditPharmacyView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 24/12/25.
//

import SwiftUI
import AlertToast

struct EditPharmacyView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var pharmacyViewModel: PharmacyGlobalViewModel
    @EnvironmentObject private var appVM: AppGlobalViewModel
    
    @StateObject private var vm: EditPharmacyViewModel
    @State private var showDeleteConfirmation = false
    
    init(pharmacy: Pharmacy) {
        _vm = StateObject(wrappedValue: EditPharmacyViewModel(pharmacy: pharmacy))
    }
    
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
                    
                    Button(action: { showDeleteConfirmation = true }) {
                        Image(systemName: "trash")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                    }
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
                            placeholder: "Pharmacy Name",
                            text: $vm.pharmacyName,
                            keyboardType: .default,
                            autocapitalization: .words,
                            disableAutocorrection: false,
                            errorText: vm.fieldErrors[.pharmacyName]
                        )
                        
                        // License Number
                        TextInputField(
                            placeholder: "License Number",
                            text: $vm.licenseNumber,
                            keyboardType: .default,
                            autocapitalization: .characters,
                            errorText: vm.fieldErrors[.licenseNumber]
                        )
                        
                        // Email
                        TextInputField(
                            placeholder: "Email Address",
                            text: $vm.email,
                            keyboardType: .emailAddress,
                            autocapitalization: .never,
                            errorText: vm.fieldErrors[.email]
                        )
                        
                        // Phone Number
                        CountryPhoneField(
                            countryCode: $vm.countryCode,
                            phone: $vm.phoneNumber,
                            errorText: vm.fieldErrors[.phone]
                        )
                        
                        Text("Contact Information")
                            .font(theme.typography.semiBold18)
                            .foregroundColor(theme.colors.textPrimary)
                        
                        // Street Address
                        TextInputField(
                            placeholder: "Street Address",
                            text: $vm.streetAddress,
                            keyboardType: .default,
                            autocapitalization: .words,
                            disableAutocorrection: false,
                            errorText: vm.fieldErrors[.streetAddress]
                        )
                        
                        // City and State in same row
                        HStack(spacing: 12) {
                            TextInputField(
                                placeholder: "City",
                                text: $vm.city,
                                keyboardType: .default,
                                autocapitalization: .words,
                                disableAutocorrection: false,
                                errorText: vm.fieldErrors[.city]
                            )
                            
                            TextInputField(
                                placeholder: "State",
                                text: $vm.state,
                                keyboardType: .default,
                                autocapitalization: .words,
                                disableAutocorrection: false,
                                errorText: vm.fieldErrors[.state]
                            )
                        }
                        
                        // Postal Code and Country in same row
                        HStack(spacing: 12) {
                            TextInputField(
                                placeholder: "Postal Code",
                                text: $vm.postalCode,
                                keyboardType: .default,
                                autocapitalization: .characters,
                                errorText: vm.fieldErrors[.postalCode]
                            )
                            
                            DropdownField(
                                selectedValue: Binding(
                                    get: {
                                        // Find country by ISO and return its name for display
                                        appVM.countryCodes.first(where: { $0.iso == vm.selectedCountryISO })?.nicename
                                    },
                                    set: { selectedName in
                                        // Find country by name and store its ISO code
                                        if let country = appVM.countryCodes.first(where: { $0.nicename == selectedName }) {
                                            vm.selectedCountryISO = country.iso
                                        }
                                    }
                                ),
                                items: appVM.countryNamesOnly,
                                errorText: vm.fieldErrors[.selectedCountry]
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 40)
                    .padding(.bottom, 160)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
                
                Spacer()
            }
            
            // Update and Make Default Buttons (Fixed at bottom)
            VStack {
                Spacer()
                
                VStack(spacing: 12) {
                    // Update Button
                    Button(action: {
                        updatePharmacy()
                    }) {
                        if pharmacyViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        } else {
                            Text("Update")
                                .font(theme.typography.button)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        }
                    }
                    .background(theme.colors.primary)
                    .cornerRadius(12)
                    .disabled(pharmacyViewModel.isLoading)
                    
                    // Make Default Button
                    Button(action: {
                        makeDefaultPharmacy()
                    }) {
                        if pharmacyViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: theme.colors.primary))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        } else {
                            Text("Make Default")
                                .font(theme.typography.button)
                                .foregroundColor(theme.colors.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        }
                    }
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(theme.colors.primary, lineWidth: 2)
                    )
                    .cornerRadius(12)
                    .disabled(pharmacyViewModel.isLoading)
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
        .toast(isPresenting: $pharmacyViewModel.showSuccessToast) {
            AlertToast(
                displayMode: .hud,
                type: .complete(theme.colors.primary),
                title: "Pharmacy updated successfully!"
            )
        }
        .toast(isPresenting: $pharmacyViewModel.showErrorToast) {
            AlertToast(
                displayMode: .alert,
                type: .error(theme.colors.error),
                title: "Error",
                subTitle: pharmacyViewModel.errorMessage
            )
        }
        .alert("Delete Pharmacy", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deletePharmacy()
            }
        } message: {
            Text("Are you sure you want to delete this pharmacy? This action cannot be undone.")
        }
        .onAppear {
            Task {
                await appVM.loadCountryCodes()
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func updatePharmacy() {
        hideKeyboard()
        
        // Validate form using view model
        guard vm.validatePharmacyFields() else { return }
        
        // Combine country code and phone number
        let fullPhoneNumber = "\(vm.countryCode)\(vm.phoneNumber)"
        
        // Call global view model to update pharmacy
        Task {
            let success = await pharmacyViewModel.updatePharmacy(
                pharmacyId: "\(vm.pharmacyId)",
                name: vm.pharmacyName.trimmingCharacters(in: .whitespacesAndNewlines),
                licenseNumber: vm.licenseNumber.trimmingCharacters(in: .whitespacesAndNewlines),
                address: vm.streetAddress.trimmingCharacters(in: .whitespacesAndNewlines),
                city: vm.city.trimmingCharacters(in: .whitespacesAndNewlines),
                state: vm.state.trimmingCharacters(in: .whitespacesAndNewlines),
                postalCode: vm.postalCode.trimmingCharacters(in: .whitespacesAndNewlines),
                country: vm.selectedCountryISO.trimmingCharacters(in: .whitespacesAndNewlines),
                phone: fullPhoneNumber,
                email: vm.email.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            if success {
                // Small delay to show the success toast
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                
                // Navigate back on success
                router.pop()
            }
        }
    }
    
    private func deletePharmacy() {
        hideKeyboard()
        
        Task {
            let success = await pharmacyViewModel.deletePharmacy(pharmacyId: "\(vm.pharmacyId)")
            
            if success {
                // Small delay to show the success toast
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                
                // Navigate back on success
                router.pop()
            }
        }
    }
    
    private func makeDefaultPharmacy() {
        hideKeyboard()
        
        Task {
            let success = await pharmacyViewModel.setDefaultPharmacy(pharmacyId: "\(vm.pharmacyId)")
            
            if success {
                // Small delay to show the success toast
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                
                // Navigate back on success
                router.pop()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    EditPharmacyView(pharmacy: Pharmacy(
        id: 1,
        name: "Test Pharmacy",
        address: "123 Main St",
        city: "Dublin",
        state: "Leinster",
        postalCode: "D01 A123",
        country: "IE",
        phone: "+353123456789",
        email: "test@pharmacy.com",
        licenseNumber: "LIC123",
        isActive: true,
        isVerified: true,
        isAdminManaged: false,
        operatingHours: nil,
        createdAt: nil,
        updatedAt: nil
    ))
    .environment(\.appTheme, AppTheme.default)
}
