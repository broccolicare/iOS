//
//  MedicalEnquiryView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 29/11/25.
//

import SwiftUI
import AlertToast

struct MedicalEnquiryView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel: MedicalEnquiryViewModel
    
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
    
    init(userService: UserServiceProtocol) {
        _viewModel = StateObject(wrappedValue: MedicalEnquiryViewModel(userService: userService))
    }
    
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
                            VStack(alignment: .leading, spacing: 4) {
                                TextInputField(
                                    placeholder: "Name",
                                    text: $viewModel.name,
                                    keyboardType: .default,
                                    autocapitalization: .words,
                                    disableAutocorrection: false
                                )
                                if let error = viewModel.fieldErrors[.name] {
                                    Text(error)
                                        .font(theme.typography.caption)
                                        .foregroundStyle(theme.colors.error)
                                }
                            }
                            
                            // Email field
                            VStack(alignment: .leading, spacing: 4) {
                                TextInputField(
                                    placeholder: "Email address",
                                    text: $viewModel.email,
                                    keyboardType: .emailAddress,
                                    autocapitalization: .never
                                )
                                if let error = viewModel.fieldErrors[.email] {
                                    Text(error)
                                        .font(theme.typography.caption)
                                        .foregroundStyle(theme.colors.error)
                                }
                            }
                            
                            // Phone number field
                            VStack(alignment: .leading, spacing: 4) {
                                CountryPhoneField(
                                    countryCode: $viewModel.countryCode,
                                    phone: $viewModel.phoneNumber
                                )
                                if let error = viewModel.fieldErrors[.phoneNumber] {
                                    Text(error)
                                        .font(theme.typography.caption)
                                        .foregroundStyle(theme.colors.error)
                                }
                            }
                            
                            // Password field
                            VStack(alignment: .leading, spacing: 4) {
                                TextInputField(
                                    placeholder: "Password",
                                    text: $viewModel.password,
                                    keyboardType: .default,
                                    isSecure: true,
                                    autocapitalization: .never,
                                    disableAutocorrection: true
                                )
                                if let error = viewModel.fieldErrors[.password] {
                                    Text(error)
                                        .font(theme.typography.caption)
                                        .foregroundStyle(theme.colors.error)
                                }
                            }
                            
                            // Desired Procedure dropdown
                            VStack(alignment: .leading, spacing: 4) {
                                DropdownField(
                                    selectedValue: $viewModel.selectedProcedure,
                                    items: procedures,
                                    placeholder: "Desired Procedure",
                                    allowsSearch: true,
                                    showsChevron: true
                                )
                                if let error = viewModel.fieldErrors[.procedure] {
                                    Text(error)
                                        .font(theme.typography.caption)
                                        .foregroundStyle(theme.colors.error)
                                }
                            }
                            
                            // Preferred Destination dropdown
                            VStack(alignment: .leading, spacing: 4) {
                                DropdownField(
                                    selectedValue: $viewModel.selectedDestination,
                                    items: destinations,
                                    placeholder: "Preferred Destination",
                                    allowsSearch: true,
                                    showsChevron: true
                                )
                                if let error = viewModel.fieldErrors[.destination] {
                                    Text(error)
                                        .font(theme.typography.caption)
                                        .foregroundStyle(theme.colors.error)
                                }
                            }
                            
                            // Additional Information textarea
                            VStack(alignment: .leading, spacing: 8) {
                                TextEditor(text: $viewModel.additionalInfo)
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
                                            if viewModel.additionalInfo.isEmpty {
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
                            ZStack {
                                Text("Submit Enquiry")
                                    .font(theme.typography.button)
                                    .foregroundColor(.white)
                                    .opacity(viewModel.isLoading ? 0 : 1)
                                
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(viewModel.isLoading ? theme.colors.primary.opacity(0.6) : theme.colors.primary)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isLoading)
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
        .toast(isPresenting: $viewModel.showSuccessToast) {
            AlertToast(
                displayMode: .hud,
                type: .complete(theme.colors.success),
                title: "Success!",
                subTitle: viewModel.successMessage
            )
        }
        .toast(isPresenting: $viewModel.showErrorToast) {
            AlertToast(
                displayMode: .hud,
                type: .error(theme.colors.error),
                title: "Error!",
                subTitle: viewModel.errorMessage
            )
        }
        .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func submitEnquiry() {
        hideKeyboard()
        
        Task {
            await viewModel.submitEnquiry()
        }
    }
}

// MARK: - Preview
#Preview {
    MedicalEnquiryView(userService: UserService(httpClient: HTTPClient()))
        .environment(\.appTheme, AppTheme.default)
}
