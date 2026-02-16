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
    @EnvironmentObject private var appGlobalViewModel: AppGlobalViewModel
    @StateObject private var viewModel: MedicalEnquiryViewModel
    
    // Computed properties for dropdown data
    private var procedures: [String] {
        appGlobalViewModel.medicalProcedures.map { $0.name }
    }
    
    private var destinations: [String] {
        appGlobalViewModel.medicalDestinations.map { $0.name }
    }
    
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
                            TextInputField(
                                placeholder: "Name",
                                text: $viewModel.name,
                                keyboardType: .default,
                                autocapitalization: .words,
                                disableAutocorrection: false,
                                errorText: viewModel.fieldErrors[.name]
                            )
                            
                            // Email field
                            TextInputField(
                                placeholder: "Email address",
                                text: $viewModel.email,
                                keyboardType: .emailAddress,
                                autocapitalization: .never,
                                errorText: viewModel.fieldErrors[.email]
                            )
                            
                            // Phone number field
                            CountryPhoneField(
                                countryCode: $viewModel.countryCode,
                                phone: $viewModel.phoneNumber,
                                errorText: viewModel.fieldErrors[.phoneNumber]
                            )
                            
                            // Desired Procedure dropdown
                            DropdownField(
                                selectedValue: $viewModel.selectedProcedure,
                                items: procedures,
                                placeholder: "Desired Procedure",
                                allowsSearch: true,
                                showsChevron: true,
                                errorText: viewModel.fieldErrors[.procedure]
                            )
                            .onChange(of: viewModel.selectedProcedure) { _, newValue in
                                if let procedureName = newValue {
                                    viewModel.selectedProcedureId = appGlobalViewModel.medicalProcedures.first { $0.name == procedureName }?.id
                                } else {
                                    viewModel.selectedProcedureId = nil
                                }
                            }
                            
                            // Preferred Destination dropdown
                            DropdownField(
                                selectedValue: $viewModel.selectedDestination,
                                items: destinations,
                                placeholder: "Preferred Destination",
                                allowsSearch: true,
                                showsChevron: true,
                                errorText: viewModel.fieldErrors[.destination]
                            )
                            .onChange(of: viewModel.selectedDestination) { _, newValue in
                                if let destinationName = newValue {
                                    viewModel.selectedDestinationId = appGlobalViewModel.medicalDestinations.first { $0.name == destinationName }?.id
                                } else {
                                    viewModel.selectedDestinationId = nil
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
        .task {
            await loadData()
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadData() async {
        await appGlobalViewModel.loadMedicalProcedures()
        await appGlobalViewModel.loadMedicalDestinations()
    }
    
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
