import SwiftUI

struct SignUpView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var authService = AuthService(
        httpClient: HTTPClient(),
        secureStore: SecureStore()
    )
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var userType: UserType = .patient
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var agreeToTerms = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.xl) {
                // Header
                VStack(spacing: theme.spacing.md) {
                    Text("Create Account")
                        .font(theme.typography.titleXL)
                        .foregroundStyle(theme.colors.textPrimary)
                    
                    Text("Join Broccoli for better healthcare")
                        .font(theme.typography.body)
                        .foregroundStyle(theme.colors.textSecondary)
                }
                .padding(.top, theme.spacing.lg)
                
                // Sign Up Form
                VStack(spacing: theme.spacing.lg) {
                    // User Type Selection
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        Text("I am a")
                            .font(theme.typography.callout)
                            .foregroundStyle(theme.colors.textPrimary)
                        
                        HStack(spacing: theme.spacing.md) {
                            UserTypeButton(
                                title: "Patient",
                                isSelected: userType == .patient,
                                theme: theme
                            ) {
                                userType = .patient
                            }
                            
                            UserTypeButton(
                                title: "Doctor",
                                isSelected: userType == .doctor,
                                theme: theme
                            ) {
                                userType = .doctor
                            }
                        }
                    }
                    
                    // Name Fields
                    HStack(spacing: theme.spacing.md) {
                        VStack(alignment: .leading, spacing: theme.spacing.xs) {
                            Text("First Name")
                                .font(theme.typography.callout)
                                .foregroundStyle(theme.colors.textPrimary)
                            
                            TextField("First name", text: $firstName)
                                .textFieldStyle(CustomTextFieldStyle(theme: theme))
                        }
                        
                        VStack(alignment: .leading, spacing: theme.spacing.xs) {
                            Text("Last Name")
                                .font(theme.typography.callout)
                                .foregroundStyle(theme.colors.textPrimary)
                            
                            TextField("Last name", text: $lastName)
                                .textFieldStyle(CustomTextFieldStyle(theme: theme))
                        }
                    }
                    
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
                    
                    // Password Fields
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        Text("Password")
                            .font(theme.typography.callout)
                            .foregroundStyle(theme.colors.textPrimary)
                        
                        SecureField("Enter your password", text: $password)
                            .textFieldStyle(CustomTextFieldStyle(theme: theme))
                    }
                    
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        Text("Confirm Password")
                            .font(theme.typography.callout)
                            .foregroundStyle(theme.colors.textPrimary)
                        
                        SecureField("Confirm your password", text: $confirmPassword)
                            .textFieldStyle(CustomTextFieldStyle(theme: theme))
                    }
                    
                    // Terms and Conditions
                    HStack(alignment: .top, spacing: theme.spacing.sm) {
                        Button(action: { agreeToTerms.toggle() }) {
                            Image(systemName: agreeToTerms ? "checkmark.square.fill" : "square")
                                .foregroundStyle(agreeToTerms ? theme.colors.primary : theme.colors.border)
                        }
                        
                        Text("I agree to the Terms of Service and Privacy Policy")
                            .font(theme.typography.callout)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                    
                    // Sign Up Button
                    Button(action: signUp) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Create Account")
                                .font(theme.typography.button)
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(isSignUpValid ? theme.colors.primary : theme.colors.border)
                    .cornerRadius(theme.cornerRadius)
                    .disabled(!isSignUpValid || isLoading)
                    
                    // Social Sign Up
                    VStack(spacing: theme.spacing.md) {
                        Text("Or continue with")
                            .font(theme.typography.callout)
                            .foregroundStyle(theme.colors.textSecondary)
                        
                        HStack(spacing: theme.spacing.md) {
                            // Google Sign In
                            Button(action: googleSignUp) {
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
                            Button(action: appleSignUp) {
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
                
                // Login Link
                HStack {
                    Text("Already have an account?")
                        .font(theme.typography.callout)
                        .foregroundStyle(theme.colors.textSecondary)
                    
                    NavigationLink(destination: LoginView()) {
                        Text("Login")
                            .font(theme.typography.callout)
                            .foregroundStyle(theme.colors.primary)
                    }
                }
                .padding(.bottom, theme.spacing.lg)
            }
        }
        .padding(.horizontal, theme.spacing.lg)
        .background(theme.colors.background)
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var isSignUpValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        password.count >= 6 &&
        agreeToTerms
    }
    
    private func signUp() {
        isLoading = true
        
        Task {
            do {
                try await authService.signUp(
                    email: email,
                    password: password,
                    userType: userType
                )
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
    
    private func googleSignUp() {
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
    
    private func appleSignUp() {
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

struct UserTypeButton: View {
    let title: String
    let isSelected: Bool
    let theme: AppThemeProtocol
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(theme.typography.callout)
                .foregroundStyle(isSelected ? .white : theme.colors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(isSelected ? theme.colors.primary : theme.colors.surface)
                .cornerRadius(theme.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadius)
                        .stroke(isSelected ? theme.colors.primary : theme.colors.border, lineWidth: 1)
                )
        }
    }
}

#Preview {
    NavigationView {
        SignUpView()
    }
    .appTheme(AppTheme.default)
}
