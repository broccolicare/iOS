//
//  CureFromDrugView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 29/11/25.
//

import SwiftUI
import AlertToast

struct CureFromDrugView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel: CureFromDrugViewModel
    
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
    
    private let yearsOfAddiction: [String] = (1...30).map { String($0) }
    
    init(userService: UserServiceProtocol) {
        _viewModel = StateObject(wrappedValue: CureFromDrugViewModel(userService: userService))
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
                            .font(theme.typography.medium28)
                            .foregroundStyle(theme.colors.textPrimary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                        
                        // Form fields
                        VStack(spacing: 20) {
                            // Full Name field
                            VStack(alignment: .leading, spacing: 4) {
                                TextInputField(
                                    placeholder: "Full Name",
                                    text: $viewModel.fullName,
                                    keyboardType: .default,
                                    autocapitalization: .words,
                                    disableAutocorrection: false
                                )
                                if let error = viewModel.fieldErrors[.fullName] {
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
                            
                            // Drug of addiction dropdown
                            VStack(alignment: .leading, spacing: 4) {
                                DropdownField(
                                    selectedValue: $viewModel.selectedDrug,
                                    items: drugsOfAddiction,
                                    placeholder: "Drug of addiction",
                                    allowsSearch: true,
                                    showsChevron: true
                                )
                                if let error = viewModel.fieldErrors[.selectedDrug] {
                                    Text(error)
                                        .font(theme.typography.caption)
                                        .foregroundStyle(theme.colors.error)
                                }
                            }
                            
                            // Years of addiction dropdown
                            VStack(alignment: .leading, spacing: 4) {
                                DropdownField(
                                    selectedValue: $viewModel.selectedYears,
                                    items: yearsOfAddiction,
                                    placeholder: "Years of addiction",
                                    allowsSearch: false,
                                    showsChevron: true
                                )
                                if let error = viewModel.fieldErrors[.selectedYears] {
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
                            requestConsultant()
                        }) {
                            ZStack {
                                Text("Request a consultant")
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
    
    private func requestConsultant() {
        hideKeyboard()
        
        Task {
            await viewModel.submitEnquiry()
        }
    }
}

// MARK: - Preview
#Preview {
    CureFromDrugView(userService: UserService(httpClient: HTTPClient()))
        .environment(\.appTheme, AppTheme.default)
}
