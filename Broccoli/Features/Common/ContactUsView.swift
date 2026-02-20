//
//  ContactUsView.swift
//  Broccoli
//
//  Created by AI Assistant on 12/02/26.
//

import SwiftUI
import AlertToast

struct ContactUsView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var appVM: AppGlobalViewModel
    
    @StateObject private var vm = ContactUsViewModel()
    @State private var showSuccessToast = false
    @State private var showErrorToast = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            theme.colors.background.ignoresSafeArea()
            
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
                .padding(.bottom, 16)
                
                // Form Content
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("We're Here to Help")
                                .font(theme.typography.medium30)
                                .foregroundColor(theme.colors.textPrimary)
                            
                            Text("Have questions about your health or our services? Reach out to us anytime")
                                .font(theme.typography.regular14)
                                .foregroundColor(theme.colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        // Form Fields
                        VStack(spacing: 16) {
                            // Name
                            TextInputField(
                                placeholder: "Name",
                                text: $vm.name,
                                keyboardType: .default,
                                autocapitalization: .words,
                                disableAutocorrection: false,
                                errorText: vm.fieldErrors[.name]
                            )
                            
                            // Email
                            TextInputField(
                                placeholder: "Email address",
                                text: $vm.email,
                                keyboardType: .emailAddress,
                                autocapitalization: .never,
                                errorText: vm.fieldErrors[.email]
                            )
                            
                            // Subject
                            TextInputField(
                                placeholder: "Subject",
                                text: $vm.subject,
                                keyboardType: .default,
                                autocapitalization: .sentences,
                                disableAutocorrection: false,
                                errorText: vm.fieldErrors[.subject]
                            )
                            
                            // Message
                            VStack(alignment: .leading, spacing: 8) {
                                ZStack(alignment: .topLeading) {
                                    // Background
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(vm.fieldErrors[.message] != nil ? theme.colors.error : Color(red: 0.9, green: 0.9, blue: 0.9), lineWidth: 1)
                                        )
                                    
                                    // Text Editor
                                    TextEditor(text: $vm.message)
                                        .font(theme.typography.regular16)
                                        .foregroundColor(theme.colors.textPrimary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .frame(height: 180)
                                        .scrollContentBackground(.hidden)
                                        .background(Color.clear)
                                    
                                    // Placeholder
                                    if vm.message.isEmpty {
                                        Text("Message")
                                            .font(theme.typography.regular16)
                                            .foregroundColor(theme.colors.textSecondary.opacity(0.5))
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 22)
                                            .allowsHitTesting(false)
                                    }
                                }
                                .frame(height: 180)
                                
                                // Error Text
                                if let errorText = vm.fieldErrors[.message] {
                                    Text(errorText)
                                        .font(theme.typography.regular12)
                                        .foregroundColor(theme.colors.error)
                                        .padding(.leading, 4)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
                
                Spacer()
            }
            
            // Send Message Button (Fixed at bottom)
            VStack {
                Spacer()
                
                Button(action: {
                    sendMessage()
                }) {
                    if appVM.isSubmittingContact {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(theme.colors.primary)
                            .cornerRadius(12)
                    } else {
                        Text("Send Message")
                            .font(theme.typography.button)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(theme.colors.primary)
                            .cornerRadius(12)
                    }
                }
                .disabled(appVM.isSubmittingContact)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .background(
                    Color.white
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5)
                )
            }
        }
        .navigationBarHidden(true)
        .toast(isPresenting: $showSuccessToast) {
            AlertToast(
                displayMode: .hud,
                type: .complete(theme.colors.success),
                title: "Message sent successfully!"
            )
        }
        .toast(isPresenting: $showErrorToast) {
            AlertToast(
                displayMode: .alert,
                type: .error(theme.colors.error),
                title: "Error",
                subTitle: errorMessage
            )
        }
    }
    
    // MARK: - Helper Functions
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func sendMessage() {
        hideKeyboard()
        
        guard vm.validateContactFields() else { return }
        
        Task {
            let success = await appVM.submitContactForm(
                name: vm.name,
                email: vm.email,
                phone: nil,
                subject: vm.subject,
                message: vm.message
            )
            
            if success {
                showSuccessToast = true
                vm.resetForm()
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                router.pop()
            } else {
                errorMessage = appVM.errorMessage ?? "Something went wrong. Please try again."
                showErrorToast = true
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ContactUsView()
        .environment(\.appTheme, AppTheme.default)
        .environmentObject(Router.shared)
}
