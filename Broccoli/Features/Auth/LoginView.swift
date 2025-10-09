import SwiftUI

struct LoginView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var authService = AuthService(
        httpClient: HTTPClient(),
        secureStore: SecureStore()
    )
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: theme.spacing.xl) {
            // Header
            VStack(spacing: theme.spacing.md) {
                Text("Welcome Back")
                    .font(theme.typography.titleXL)
                    .foregroundStyle(theme.colors.textPrimary)
                
                Text("Sign in to your account")
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textSecondary)
            }
            .padding(.top, theme.spacing.xxl)
            
            // Login Form
            VStack(spacing: theme.spacing.lg) {
                VStack(spacing: theme.spacing.md) {
                    // Email Field
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        Text("Email")
                            .font(theme.typography.callout)
                            .foregroundStyle(theme.colors.textPrimary)
                        
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(CustomTextFieldStyle(theme: theme))
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        Text("Password")
                            .font(theme.typography.callout)
                            .foregroundStyle(theme.colors.textPrimary)
                        
                        SecureField("Enter your password", text: $password)
                            .textFieldStyle(CustomTextFieldStyle(theme: theme))
                    }
                }
                
                // Forgot Password Link
                HStack {
                    Spacer()
                    NavigationLink(destination: ForgotPasswordView()) {
                        Text("Forgot Password?")
                            .font(theme.typography.callout)
                            .foregroundStyle(theme.colors.primary)
                    }
                }
                
                // Login Button
                Button(action: login) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Login")
                            .font(theme.typography.button)
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(theme.colors.primary)
                .cornerRadius(theme.cornerRadius)
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                
                // Social Login
                VStack(spacing: theme.spacing.md) {
                    Text("Or continue with")
                        .font(theme.typography.callout)
                        .foregroundStyle(theme.colors.textSecondary)
                    
                    HStack(spacing: theme.spacing.md) {
                        // Google Sign In
                        Button(action: googleSignIn) {
                            HStack {
                                Image(systemName: "globe")
                                Text("Google")
                            }
                            .font(theme.typography.callout)
                            .foregroundStyle(theme.colors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(theme.colors.surface)
                            .cornerRadius(theme.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: theme.cornerRadius)
                                    .stroke(theme.colors.border, lineWidth: 1)
                            )
                        }
                        
                        // Apple Sign In
                        Button(action: appleSignIn) {
                            HStack {
                                Image(systemName: "apple.logo")
                                Text("Apple")
                            }
                            .font(theme.typography.callout)
                            .foregroundStyle(theme.colors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(theme.colors.surface)
                            .cornerRadius(theme.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: theme.cornerRadius)
                                    .stroke(theme.colors.border, lineWidth: 1)
                            )
                        }
                    }
                }
            }
            
            Spacer()
            
            // Sign Up Link
            HStack {
                Text("Don't have an account?")
                    .font(theme.typography.callout)
                    .foregroundStyle(theme.colors.textSecondary)
                
                NavigationLink(destination: SignUpView()) {
                    Text("Sign Up")
                        .font(theme.typography.callout)
                        .foregroundStyle(theme.colors.primary)
                }
            }
        }
        .padding(.horizontal, theme.spacing.lg)
        .background(theme.colors.background)
        .navigationTitle("Login")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func login() {
        isLoading = true
        
        Task {
            do {
                try await authService.signIn(email: email, password: password)
                await MainActor.run {
                    isLoading = false
                    // Navigation will be handled by the main app based on auth state
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func googleSignIn() {
        Task {
            do {
                try await authService.signInWithGoogle()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func appleSignIn() {
        Task {
            do {
                try await authService.signInWithApple()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    let theme: AppThemeProtocol
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(theme.colors.surface)
            .cornerRadius(theme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(theme.colors.border, lineWidth: 1)
            )
    }
}

#Preview {
    NavigationView {
        LoginView()
    }
    .appTheme(AppTheme.default)
}
