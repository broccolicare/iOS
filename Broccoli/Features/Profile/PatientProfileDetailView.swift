import SwiftUI

struct PatientProfileDetailView: View {
    
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var userVM: UserGlobalViewModel
    
    var body: some View {
        ZStack(alignment: .top) {
            // Green gradient background - extends to top edge
            LinearGradient(
                gradient: Gradient(colors: [
                    theme.colors.gradientStart,
                    theme.colors.gradientEnd
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 160)
            .frame(maxWidth: .infinity)
            .ignoresSafeArea(edges: .top)
            
            VStack(spacing: 0) {
                // Header with gradient background
                ZStack(alignment: .top) {

                    VStack(spacing: 0) {
                        // Navigation buttons
                        HStack {
                            Button(action: { router.pop() }) {
                                Image("back-icon-white")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(theme.colors.primary)
                            }
                            
                            Spacer()
                            
                            Button(action: { router.push(.editPatientProfile) }) {
                                Image("edit-profile-icon")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(theme.colors.primary)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
                    }
                    .frame(height: 100)
                    
                    // Profile Image (overlapping the gradient)
                    VStack(spacing: 0) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 120, height: 120)
                            .overlay(
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 110, height: 110)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 50))
                                            .foregroundStyle(.gray)
                                    )
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                            )
                        
                        // Basic Plan Badge
                        Text("Basic Plan")
                            .font(theme.typography.regular12)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 4)
                            .background(theme.colors.primary)
                            .cornerRadius(20)
                            .offset(y: -20)
                        
                        // Name and Email
                        VStack(spacing: 4) {
                            Text(userVM.profileData?.name ?? "Guest User")
                                .font(theme.typography.semiBold30)
                                .foregroundStyle(theme.colors.textPrimary)
                            
                            Text(verbatim: userVM.profileData?.email ?? "email@example.com")
                                .font(theme.typography.regular16)
                                .foregroundStyle(theme.colors.profileDetailTextColor)
                        }
                        .offset(y: -16)
                    }
                    .padding(.top, 40)

                }
            
            
            
            ScrollView {
                // Content Sections
                VStack(spacing: 20) {
                    // Personal Information Section
                    ProfileSectionCard(
                        icon: "personal-info-icon",
                        title: "Personal Information",
                        content: {
                            VStack(spacing: 16) {
                                ProfileInfoRow(
                                    label: "Date of Birth",
                                    value: userVM.profileData?.profile?.dateOfBirth ?? "Not provided",
                                    valueColor: theme.colors.profileDetailTextColor,
                                )
                                
                                ProfileInfoRow(
                                    label: "Phone Number",
                                    value: formatPhoneNumber(
                                        code: userVM.profileData?.profile?.phoneCode,
                                        phone: userVM.profileData?.profile?.phone
                                    ),
                                    valueColor: theme.colors.profileDetailTextColor,
                                )
                                
                                ProfileInfoRow(
                                    label: "Address",
                                    value: formatAddress(
                                        address: userVM.profileData?.profile?.address,
                                        city: userVM.profileData?.profile?.city,
                                        state: userVM.profileData?.profile?.state,
                                        country: userVM.profileData?.profile?.country,
                                        postalCode: userVM.profileData?.profile?.postalCode
                                    ),
                                    valueColor: theme.colors.profileDetailTextColor,
                                )
                            }
                        }
                    )
                    
                    // Medical History Section
                    ProfileSectionCard(
                        icon: "medical-history-icon",
                        title: "Medical History",
                        content: {
                            VStack(spacing: 16) {
                                ProfileInfoRow(
                                    label: "Blood Type",
                                    value: userVM.profileData?.profile?.bloodGroup ?? "Not provided",
                                    valueColor: theme.colors.profileDetailTextColor,
                                )
                                
                                ProfileInfoRow(
                                    label: "Allergies",
                                    value: userVM.profileData?.medicalInfo?.allergies ?? "None",
                                    valueColor: theme.colors.profileDetailTextColor,
                                )
                                
                                ProfileInfoRow(
                                    label: "Chronic Conditions",
                                    value: userVM.profileData?.medicalInfo?.knownConditions ?? "None",
                                    valueColor: theme.colors.profileDetailTextColor,
                                )
                            }
                        }
                    )
                    
                    // Insurance Information Section
                    if let insurance = userVM.profileData?.insurances?.first {
                        ProfileSectionCard(
                            icon: "insurance-info-icon",
                            title: "Insurance Information",
                            content: {
                                VStack(spacing: 16) {
                                    ProfileInfoRow(
                                        label: "Provider",
                                        value: insurance.providerName,
                                        valueColor: theme.colors.profileDetailTextColor,
                                    )
                                    ProfileInfoRow(
                                        label: "Policy Number",
                                        value: insurance.policyNumber,
                                        valueColor: theme.colors.profileDetailTextColor,
                                    )
                                }
                            }
                        )
                    }
                    
                    // Emergency Contact
                    ProfileSectionCard(
                        icon: "insurance-info-icon",
                        title: "Emergency Contact",
                        content: {
                            VStack(spacing: 16) {
                                ProfileInfoRow(
                                    label: "Name",
                                    value: "Ethan Carter",
                                    valueColor: theme.colors.profileDetailTextColor,
                                )
                                
                                ProfileInfoRow(
                                    label: "Relationship",
                                    value: "Spouse",
                                    valueColor: theme.colors.profileDetailTextColor,
                                )
                                
                                ProfileInfoRow(
                                    label: "Phone Num",
                                    value: "+1 (555) 987-6543",
                                    valueColor: theme.colors.profileDetailTextColor,
                                )
                            }
                        }
                    )
                }
                .padding(.horizontal, 20)
                }
            }
        }
        .background(.white)
        .navigationBarHidden(true)
        .task {
            await userVM.fetchProfileDetail()
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatPhoneNumber(code: String?, phone: String?) -> String {
        guard let phone = phone, !phone.isEmpty else {
            return "Not provided"
        }
        if let code = code, !code.isEmpty {
            return "\(code) \(phone)"
        }
        return phone
    }
    
    private func formatAddress(address: String?, city: String?, state: String?, country: String?, postalCode: String?) -> String {
        var components: [String] = []
        
        if let address = address, !address.isEmpty {
            components.append(address)
        }
        
        if let city = city, !city.isEmpty {
            components.append(city)
        }
        
        if let state = state, !state.isEmpty {
            if let postalCode = postalCode, !postalCode.isEmpty {
                components.append("\(state) \(postalCode)")
            } else {
                components.append(state)
            }
        } else if let postalCode = postalCode, !postalCode.isEmpty {
            components.append(postalCode)
        }
        
        if let country = country, !country.isEmpty {
            components.append(country)
        }
        
        return components.isEmpty ? "Not provided" : components.joined(separator: ", ")
    }
    
    private func formatAllergies(_ allergies: [Allergy]?) -> String {
        guard let allergies = allergies, !allergies.isEmpty else {
            return "No known allergies"
        }
        return allergies.map { $0.name }.joined(separator: ", ")
    }
    
    private func formatHeartRate(_ heartRate: String?) -> String {
        guard let heartRate = heartRate, !heartRate.isEmpty else {
            return "Not recorded"
        }
        return "\(heartRate) bpm"
    }
    
    private func formatWeight(_ weight: String?) -> String {
        guard let weight = weight, !weight.isEmpty else {
            return "Not recorded"
        }
        return "\(weight) kg"
    }
    
    private func formatHeight(_ height: String?) -> String {
        guard let height = height, !height.isEmpty else {
            return "Not recorded"
        }
        return "\(height) cm"
    }
    
    private func formatCoverageAmount(_ amount: String?) -> String {
        guard let amount = amount, !amount.isEmpty else {
            return "Not provided"
        }
        // Format as currency
        if let doubleValue = Double(amount) {
            return "€\(String(format: "%.2f", doubleValue))"
        }
        return "€\(amount)"
    }
    
    private func formatCoveragePeriod(start: String?, end: String?) -> String {
        var period: [String] = []
        
        if let start = start, !start.isEmpty {
            period.append(formatDate(start))
        }
        
        if let end = end, !end.isEmpty {
            period.append(formatDate(end))
        }
        
        if period.isEmpty {
            return "Not provided"
        }
        
        return period.joined(separator: " - ")
    }
    
    private func formatDate(_ dateString: String) -> String {
        // Input format: "2024-12-09"
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMM dd, yyyy"
        
        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        
        return dateString
    }
}

#Preview {
    PatientProfileDetailView()
        .environment(\.appTheme, AppTheme.default)
    
}
