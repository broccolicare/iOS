import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var authService = AuthService(
        httpClient: HTTPClient(),
        secureStore: SecureStore()
    )
    
    @State private var email = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: theme.spacing.xl) {
            Spacer()
            
            // Header
            VStack(spacing: theme.spacing.md) {
                Image(systemName: "lock.rotation")
                    .font(.system(size: 64))
                    .foregroundStyle(theme.colors.primary)
                
                Text("Forgot Password?")
                    .font(theme.typography.titleXL)
                    .foregroundStyle(theme.colors.textPrimary)
                
                Text("Don't worry! Enter your email address and we'll send you a link to reset your password.")
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, theme.spacing.lg)
            }
            
            Spacer()
            
            // Reset Form
            VStack(spacing: theme.spacing.lg) {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text("Email")
                        .font(theme.typography.callout)
                        .foregroundStyle(theme.colors.textPrimary)
                    
                    TextField("Enter your email", text: $email)
                        .textFieldStyle(CustomTextFieldStyle(theme: theme))
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Button(action: resetPassword) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Send Reset Link")
                            .font(theme.typography.button)
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(email.isEmpty ? theme.colors.border : theme.colors.primary)
                .cornerRadius(theme.cornerRadius)
                .disabled(email.isEmpty || isLoading)
            }
            
            Spacer()
            
            // Back to Login
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                HStack {
                    Image(systemName: "arrow.left")
                    Text("Back to Login")
                }
                .font(theme.typography.callout)
                .foregroundStyle(theme.colors.primary)
            }
        }
        .padding(.horizontal, theme.spacing.lg)
        .background(theme.colors.background)
        .navigationTitle("Reset Password")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Success", isPresented: $showSuccess) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Password reset link has been sent to your email address.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func resetPassword() {
        isLoading = true
        
//        Task {
//            do {
//                try await authService.resetPassword(email: email)
//                await MainActor.run {
//                    isLoading = false
//                    showSuccess = true
//                }
//            } catch {
//                await MainActor.run {
//                    isLoading = false
//                    errorMessage = error.localizedDescription
//                    showError = true
//                }
//            }
//        }
    }
}

#Preview {
    NavigationView {
        ForgotPasswordView()
    }
    .appTheme(AppTheme.default)
}
