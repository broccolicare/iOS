import SwiftUI
import AlertToast

struct ResetPasswordView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var authVM: AuthGlobalViewModel
    
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showSuccessToast = false
    @State private var showErrorToast = false
    @State private var errorMessage = ""
    
    let email: String
    let otp: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Custom Navigation Bar
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(theme.colors.textPrimary)
                }
                Spacer()
            }
            .padding(.horizontal, theme.spacing.lg)
            .padding(.top, theme.spacing.md)
            .padding(.bottom, theme.spacing.xl)
            
            VStack(alignment: .leading, spacing: theme.spacing.xl) {
                // Title and Description
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    Text("Reset Password")
                        .font(theme.typography.title)
                        .foregroundStyle(theme.colors.textPrimary)
                    
                    Text("Please enter your new password and confirm it to reset your password.")
                        .font(theme.typography.callout)
                        .foregroundStyle(theme.colors.textSecondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                VStack(spacing: theme.spacing.lg) {
                    // New Password Field
                    TextInputField(
                        placeholder: "New Password",
                        text: $newPassword,
                        keyboardType: .default,
                        isSecure: true,
                        errorText: newPasswordError
                    )
                    
                    // Confirm Password Field
                    TextInputField(
                        placeholder: "Confirm Password",
                        text: $confirmPassword,
                        keyboardType: .default,
                        isSecure: true,
                        errorText: confirmPasswordError
                    )
                }
                
                PrimaryButton(action: resetPassword) {
                    if authVM.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Submit")
                    }
                }
                .disabled(authVM.isLoading || !isValidForm)
                .padding(.top, theme.spacing.sm)
                
                Spacer()
            }
            .padding(.horizontal, theme.spacing.lg)
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .toast(
            isPresenting: $showSuccessToast,
            alert: {
                AlertToast(
                    displayMode: .hud,
                    type: .complete(theme.colors.success),
                    title: "Success!",
                    subTitle: "Your password has been reset successfully."
                )
            }
        )
        .toast(
            isPresenting: $showErrorToast,
            alert: {
                AlertToast(
                    displayMode: .hud,
                    type: .error(theme.colors.error),
                    title: "Error!",
                    subTitle: errorMessage
                )
            }
        )
    }
    
    // MARK: - Computed Properties
    
    private var newPasswordError: String? {
        if newPassword.isEmpty { return nil }
        return Validator.isValidPassword(newPassword) ? nil : "Password must be at least 8 characters long"
    }
    
    private var confirmPasswordError: String? {
        if confirmPassword.isEmpty { return nil }
        return newPassword == confirmPassword ? nil : "Passwords do not match"
    }
    
    private var isValidForm: Bool {
        return Validator.isValidPassword(newPassword) &&
               newPassword == confirmPassword &&
               !newPassword.isEmpty &&
               !confirmPassword.isEmpty
    }
    
    // MARK: - Actions
    
    private func resetPassword() {
        Task {
            await authVM.resetPassword(email: email, otp: otp, newPassword: newPassword, confirmPassword: confirmPassword)
            
            // Check if there was an error
            if let error = authVM.errorMessage {
                errorMessage = error
                showErrorToast = true
            } else {
                // Success - show success toast and navigate back to login
                showSuccessToast = true
                
                // Navigate back to login screen after showing success toast
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    router.setStack([.login])
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        ResetPasswordView(email: "test@gmail.com", otp: "123456")
    }
    .appTheme(AppTheme.default)
}
