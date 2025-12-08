//
//  EditDoctorProfileView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 20/11/25.
//

import SwiftUI
import AlertToast

struct EditDoctorProfileView: View {
    
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appVM: AppGlobalViewModel
    @EnvironmentObject private var userVM: UserGlobalViewModel
    @EnvironmentObject private var router: Router
    
    @StateObject private var vm = EditDoctorProfileViewModel()
    
    // Available time slots
    private let timeSlots = [
        "9:00 AM", "10:00 AM", "11:00 AM",
        "12:00 PM", "01:00 PM", "02:00 PM",
        "03:00 PM", "04:00 PM", "05:00 PM",
        "06:00 PM", "07:00 PM", "08:00 PM"
    ]
    
    // Duration options
    private let durations = ["15 min", "30 min", "45 min", "60 min"]
    
    var body: some View {
        ZStack(alignment: .top) {
            // White background
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
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Image Section
                        ZStack(alignment: .bottomTrailing) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Image("doctor-square-placeholder")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                )
                                .overlay(
                                    Circle()
                                        .stroke(theme.colors.primary.opacity(0.3), lineWidth: 1)
                                )
                            
                            // Camera button overlay
                            Circle()
                                .fill(Color.white)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(theme.colors.primary)
                                )
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        
                        // Personal Information Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Personal Information")
                                .font(theme.typography.semiBold18)
                                .foregroundStyle(theme.colors.textPrimary)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 16) {
                                // Full Name
                                TextInputField(
                                    placeholder: "Full Name",
                                    text: $vm.fullName,
                                    keyboardType: .default,
                                    errorText: vm.fieldErrors[.fullName]
                                )
                                
                                // Email
                                TextInputField(
                                    placeholder: "Email Address",
                                    text: $vm.email,
                                    keyboardType: .emailAddress,
                                    errorText: vm.fieldErrors[.email]
                                )
                                
                                // Phone Number with Country Code
                                CountryPhoneField(
                                    countryCode: $vm.phoneCountryCode,
                                    phone: $vm.phoneNumber,
                                    countryCodes: appVM.phoneCodesOnly,
                                    errorText: vm.fieldErrors[.phoneNumber]
                                )
                                
                                // Date of Birth
                                DatePickerField(
                                    selectedDate: $vm.dateOfBirth,
                                    placeholder: "Date of Birth (YYYY-MM-DD)",
                                    dateFormat: "yyyy-MM-dd",
                                    maximumDate: Date()
                                )
                                
                                // Specialization Dropdown
                                DropdownField(
                                    selectedValues: Binding(
                                        get: { vm.selectedSpecializations },
                                        set: { vm.selectedSpecializations = $0 }
                                    ),
                                    items: appVM.specializations,
                                    placeholder: "Specialization",
                                    title: nil,
                                    allowsSearch: true,
                                    errorText: vm.fieldErrors[.specialization]
                                )
                                
                                // License Number
                                TextInputField(
                                    placeholder: "License Number",
                                    text: $vm.licenseNumber,
                                    keyboardType: .default,
                                    errorText: vm.fieldErrors[.licenseNumber]
                                )
                                
                                // Gender Dropdown
                                DropdownField(
                                    selectedValue: Binding(
                                        get: { appVM.genders.first(where: { $0.value == vm.selectedGender })?.label },
                                        set: {
                                            if let selectedLabel = $0,
                                               let gender = appVM.genders.first(where: { $0.label == selectedLabel }) {
                                                vm.selectedGender = gender.value
                                            }
                                        }
                                    ),
                                    items: appVM.genders.map { $0.label },
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Address Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Address")
                                .font(theme.typography.semiBold18)
                                .foregroundStyle(theme.colors.textPrimary)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 16) {
                                // Address
                                TextInputField(
                                    placeholder: "Address",
                                    text: $vm.address,
                                    keyboardType: .default
                                )
                                
                                // Country Dropdown
                                DropdownField(
                                    selectedValue: Binding(
                                        get: { appVM.countryNamesOnly.first(where: { $0 == vm.selectedCountry }) },
                                        set: { vm.selectedCountry = $0 ?? "" }
                                    ),
                                    items: appVM.countryNamesOnly,
                                )
                                
                                // Postal Code
                                TextInputField(
                                    placeholder: "Postal Code",
                                    text: $vm.postalCode,
                                    keyboardType: .default
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Available Time Slots Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Available Time Slots")
                                .font(theme.typography.semiBold18)
                                .foregroundStyle(theme.colors.textPrimary)
                                .padding(.horizontal, 20)
                            
                            // Time Slots Grid
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(timeSlots, id: \.self) { slot in
                                    TimeSlotChip(
                                        timeSlot: slot,
                                        isSelected: vm.selectedTimeSlots.contains(slot),
                                        action: {
                                            toggleTimeSlot(slot)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Pricing Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Pricing")
                                .font(theme.typography.semiBold18)
                                .foregroundStyle(theme.colors.textPrimary)
                                .padding(.horizontal, 20)
                            
                            HStack(spacing: 12) {
                                // Price Field
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "eurosign")
                                            .font(.system(size: 16))
                                            .foregroundStyle(theme.colors.textSecondary)
                                        
                                        TextField("49", text: $vm.price)
                                            .font(theme.typography.regular16)
                                            .keyboardType(.numberPad)
                                    }
                                    .padding(16)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(vm.fieldErrors[.price] != nil ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    
                                    if let errorText = vm.fieldErrors[.price] {
                                        Text(errorText)
                                            .font(theme.typography.caption)
                                            .foregroundStyle(.red)
                                            .padding(.leading, 4)
                                    }
                                }
                                
                                // Duration Dropdown
                                Menu {
                                    ForEach(durations, id: \.self) { duration in
                                        Button(action: {
                                            vm.selectedDuration = duration
                                        }) {
                                            HStack {
                                                Text(duration)
                                                if vm.selectedDuration == duration {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "clock")
                                            .font(.system(size: 16))
                                            .foregroundStyle(theme.colors.textSecondary)
                                        
                                        Text(vm.selectedDuration.isEmpty ? "30 min" : vm.selectedDuration)
                                            .font(theme.typography.regular16)
                                            .foregroundStyle(theme.colors.textPrimary)
                                        
                                        Spacer()
                                    }
                                    .padding(16)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
                
                // Update Details Button
                Button(action: {
                    Task {
                        await updateProfile()
                    }
                }) {
                    ZStack {
                        Text("Update Details")
                            .font(theme.typography.button)
                            .foregroundColor(.white)
                        
                        if userVM.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(theme.colors.primary)
                    .cornerRadius(theme.cornerRadius)
                }
                .disabled(userVM.isLoading)
                .opacity(userVM.isLoading ? 0.7 : 1.0)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
        .task {
            // Load country codes if not already loaded
            if appVM.countryCodes.isEmpty {
                await appVM.loadCountryCodes()
            }
            
            // Load metadata (specializations, genders, etc.) if not already loaded
            if !appVM.isMetadataLoaded {
                await appVM.loadMetadata()
            }

            if appVM.specializations.isEmpty {
                await appVM.loadSpecializations()
            }
            
            // Load profile data after specializations are loaded
            vm.loadProfileData(from: userVM.profileData, appViewModel: appVM)
        }
        .toast(
            isPresenting: $vm.showSuccessToast,
            alert: {
                AlertToast(
                    displayMode: .hud,
                    type: .complete(theme.colors.primary),
                    title: "Success!",
                    subTitle: "Profile updated successfully."
                )
            }
        )
        .toast(
            isPresenting: $vm.showErrorToast,
            alert: {
                AlertToast(
                    displayMode: .hud,
                    type: .error(theme.colors.error),
                    title: "Error!",
                    subTitle: vm.errorMessage
                )
            }
        )
    }
    
    // MARK: - Helper Functions
    
    private func toggleTimeSlot(_ slot: String) {
        if vm.selectedTimeSlots.contains(slot) {
            vm.selectedTimeSlots.remove(slot)
        } else {
            vm.selectedTimeSlots.insert(slot)
        }
    }
    
    private func updateProfile() async {
        // Validate fields using ViewModel
        guard vm.validateProfileFields() else {
            return
        }
        
        // Prepare update data using ViewModel
        let updateData = vm.prepareUpdateData()
        
        // Call the update API
        await userVM.updateProfile(data: updateData)
        
        // Check if there was an error
        if userVM.errorMessage != nil {
            vm.showErrorToast = true
            vm.errorMessage = userVM.errorMessage ?? "Failed to update profile"
        } else {
            vm.showSuccessToast = true
            
            // Dismiss after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                router.pop()
            }
        }
    }
}

// MARK: - Time Slot Chip Component
struct TimeSlotChip: View {
    @Environment(\.appTheme) private var theme
    
    let timeSlot: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(timeSlot)
                .font(theme.typography.regular14)
                .foregroundStyle(isSelected ? .white : theme.colors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isSelected ? theme.colors.primary : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? theme.colors.primary : Color.gray.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(8)
        }
    }
}

#Preview {
    EditDoctorProfileView()
        .environment(\.appTheme, AppTheme.default)
        .environmentObject(AppGlobalViewModel(appService: AppService(httpClient: HTTPClient())))
        .environmentObject(UserGlobalViewModel(userService: UserService(httpClient: HTTPClient())))
}
