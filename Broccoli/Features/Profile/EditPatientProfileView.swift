import SwiftUI
import AlertToast

// Insurance Form Data Model
struct InsuranceFormData: Identifiable {
    let id = UUID()
    var providerName: String = ""
    var policyNumber: String = ""
}

struct EditPatientProfileView: View {
    
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appVM: AppGlobalViewModel
    @EnvironmentObject private var userVM: UserGlobalViewModel
    @EnvironmentObject private var router: Router
    
    @StateObject private var vm = EditPatientProfileViewModel()
    
    // Dropdown options
    private let relationships = ["Spouse", "Parent", "Sibling", "Child", "Friend", "Other"]
    
    
    var body: some View {
        ZStack(alignment: .top) {
            // White background
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
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
                                    Image("patient-placeholder").resizable().frame(width: 100, height: 100)
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
                                    title: "Gender"
                                )
                                
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
                                    title: "Country"
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
                        
                        // Medical History Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Medical History")
                                .font(theme.typography.semiBold18)
                                .foregroundStyle(theme.colors.textPrimary)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 16) {
                                // Blood Type Dropdown
                                DropdownField(
                                    selectedValue: Binding(
                                        get: { appVM.bloodGroups.first(where: { $0.id == vm.selectedBloodType })?.name },
                                        set: {
                                            if let selectedName = $0,
                                               let bloodGroup = appVM.bloodGroups.first(where: { $0.name == selectedName }) {
                                                vm.selectedBloodType = bloodGroup.id
                                            }
                                        }
                                    ),
                                    items: appVM.bloodGroups.map { $0.name },
                                    title: "Blood Type"
                                )
                                
                                // Allergies
                                TextInputField(
                                    placeholder: "Allergies (e.g., Peanuts, Dust)",
                                    text: $vm.allergies,
                                    keyboardType: .default
                                )
                                
                                // Chronic Conditions
                                TextInputField(
                                    placeholder: "Chronic Conditions (e.g., Asthma, Diabetes)",
                                    text: $vm.chronicConditions,
                                    keyboardType: .default
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Insurance Information Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Insurance Information")
                                    .font(theme.typography.semiBold18)
                                    .foregroundStyle(theme.colors.textPrimary)
                                
                                Spacer()
                                
                            }
                            .padding(.horizontal, 20)
                            
                            ForEach(Array(vm.insurances.enumerated()), id: \.element.id) { index, insurance in
                                VStack(alignment: .leading, spacing: 16) {
                                    // Header with delete button (only show if more than one insurance)
                                    if vm.insurances.count > 1 {
                                        HStack {
                                            Text("Policy #\(index + 1)")
                                                .font(theme.typography.medium16)
                                                .foregroundStyle(theme.colors.textSecondary)
                                            
                                            Spacer()
                                            
                                            Button(action: {
                                                removeInsurance(at: index)
                                            }) {
                                                Image(systemName: "trash")
                                                    .font(.system(size: 16))
                                                    .foregroundStyle(.red)
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                    
                                    VStack(spacing: 16) {
                                        // Provider Name
                                        TextInputField(
                                            placeholder: "Provider Name",
                                            text: Binding(
                                                get: { vm.insurances[index].providerName },
                                                set: { vm.insurances[index].providerName = $0 }
                                            ),
                                            keyboardType: .default
                                        )
                                        
                                        // Policy Number
                                        TextInputField(
                                            placeholder: "Policy Number",
                                            text: Binding(
                                                get: { vm.insurances[index].policyNumber },
                                                set: { vm.insurances[index].policyNumber = $0 }
                                            ),
                                            keyboardType: .default
                                        )
                                    }
                                    .padding(.horizontal, 20)
                                    
                                    // Divider between insurance entries (except for last one)
                                    if index < vm.insurances.count - 1 {
                                        Divider()
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 8)
                                    }
                                }
                            }
                            
                            HStack {
                                
                                Spacer()
                                
                                Button(action: {
                                    addNewInsurance()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 16))
                                        Text("Add New Policy")
                                            .font(theme.typography.callout)
                                    }
                                    .foregroundStyle(theme.colors.primary)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Emergency Contact Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Emergency Contact")
                                .font(theme.typography.semiBold18)
                                .foregroundStyle(theme.colors.textPrimary)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 16) {
                                // Emergency Contact Name
                                TextInputField(
                                    placeholder: "Emergency Contact Name",
                                    text: $vm.emergencyContactName,
                                    keyboardType: .default,
                                    errorText: vm.fieldErrors[.emergencyContactName]
                                )
                                
                                // Relationship Dropdown
                                DropdownField(
                                    selectedValue: Binding(
                                        get: { relationships.first(where: { $0 == vm.emergencyRelationship }) },
                                        set: { vm.emergencyRelationship = $0 ?? "" }
                                    ),
                                    items: relationships,
                                    title: "Relationship",
                                    errorText: vm.fieldErrors[.emergencyRelationship]
                                )
                                
                                // Emergency Phone Number with Country Code
                                CountryPhoneField(
                                    countryCode: $vm.emergencyCountryCode,
                                    phone: $vm.emergencyPhoneNumber,
                                    countryCodes: appVM.phoneCodesOnly,
                                    errorText: vm.fieldErrors[.emergencyPhoneNumber]
                                )
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
            
            // Load metadata (blood groups, etc.) if not already loaded
            if !appVM.isMetadataLoaded {
                await appVM.loadMetadata()
            }
            
            // Fetch profile data from API
            await userVM.fetchProfileDetail()
            
            // Load profile data into form fields
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
    
    private func addNewInsurance() {
        vm.insurances.append(InsuranceFormData())
    }
    
    private func removeInsurance(at index: Int) {
        guard vm.insurances.count > 1 else { return }
        vm.insurances.remove(at: index)
    }
    
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

#Preview {
    EditPatientProfileView()
        .environment(\.appTheme, AppTheme.default)
        .environmentObject(AppGlobalViewModel(appService: AppService(httpClient: HTTPClient())))
//        .environmentObject(UserGlobalViewModel(userService: UserService(httpClient: HTTPClient())))
}
