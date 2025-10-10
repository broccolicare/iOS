import SwiftUI
import AlertToast

enum SignUpOrigin {
    case welcome
    case login
}

struct SignUpView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var router: Router
    @Environment(\.presentationMode) var presentationMode
    let origin: SignUpOrigin
    
    @StateObject private var authService = AuthService(
        httpClient: HTTPClient(),
        secureStore: SecureStore()
    )
    
    // form state
    @State private var username = ""
    @State private var email = ""
    @State private var gender: String = "Male"
    @State private var countryCode = "+353"
    @State private var phone = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var agreeToTerms = false
    @State private var isLoading = false
    
    // country picker sheet
    @State private var showCountryPicker = false
    
    // AlertToast states
    @State private var showError = false
    @State private var errorMessage = ""
    
    // convenience
    private var isValid: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.isEmpty &&
        !phone.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword &&
        agreeToTerms
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.xl) {
                header()
                
                VStack(spacing: theme.spacing.lg) {
                    formFields()
                }
                .padding(.horizontal, 0)
                
                socialSection()
                
                footer()
                
            }
            .padding(.horizontal, theme.spacing.lg)
            
        }
        .background(theme.colors.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerView(selectedCode: $countryCode)
        }
        .toast(
            isPresenting: $showError,
            duration: 4.0,
            tapToDismiss: true,
            offsetY: -UIScreen.main.bounds.height / 3,
            alert: {
                AlertToast(
                    displayMode: .hud,
                    type: .error(theme.colors.error),
                    title: "",
                    subTitle: errorMessage
                )
            }
        )
    }
    
    // MARK: - Subviews (extracted to reduce body complexity)
    
    @ViewBuilder
    private func header() -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 118, height: 83)
                .padding(.top, 40)
            
            Text("Signup your account")
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private func formFields() -> some View {
        Group {
            // Username
            TextField("Username", text: $username)
                .textFieldStyle(CustomTextFieldStyle(theme: theme))
            
            // Email
            TextField("Email address", text: $email)
                .textFieldStyle(CustomTextFieldStyle(theme: theme))
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            
            // Gender segmented
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                GenderSegment(selected: $gender, left: "Male", right: "Female")
            }
            
            // Phone (country code + number)
            HStack(spacing: theme.spacing.md) {
                Button(action: { showCountryPicker.toggle() }) {
                    HStack {
                        Text(countryCode)
                            .font(theme.typography.callout)
                        Image(systemName: "chevron.down")
                            .imageScale(.small)
                    }
                    .padding(.vertical, 18)
                    .padding(.horizontal, 10)
                    .background(theme.colors.surface)
                    .overlay(RoundedRectangle(cornerRadius: theme.cornerRadius).stroke(theme.colors.border, lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
                
                TextField("Enter mobile no.", text: $phone)
                    .keyboardType(.phonePad)
                    .textFieldStyle(CustomTextFieldStyle(theme: theme))
            }
            
            // Passwords
            SecureField("Password", text: $password)
                .textFieldStyle(CustomTextFieldStyle(theme: theme))
            
            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(CustomTextFieldStyle(theme: theme))
            
            // Terms (split into smaller expression to help compiler)
            HStack(alignment: .top, spacing: 2) {
                Text("By continuing, you agree to our")
                    .font(theme.typography.callout)
                    .foregroundStyle(theme.colors.textSecondary)
                Button(action: { /* open TnC */ }) {
                    Text("TnC")
                        .font(theme.typography.callout)
                        .underline()
                        .foregroundStyle(theme.colors.primary)
                }
                .buttonStyle(PlainButtonStyle())
                Text("and")
                    .font(theme.typography.callout)
                    .foregroundStyle(theme.colors.textSecondary)
                Button(action: { /* open privacy */ }) {
                    Text("Privacy Policy")
                        .font(theme.typography.callout)
                        .underline()
                        .foregroundStyle(theme.colors.primary)
                }
                .buttonStyle(PlainButtonStyle())
                Spacer()
            }
            
            // Primary Sign Up Button
            PrimaryButton(action: signUp) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Create new account")
                }
            }
            .disabled(!isValid || isLoading)
        }
    }
    
    @ViewBuilder
    private func socialSection() -> some View {
        VStack(spacing: theme.spacing.md) {
            Text("Signup with")
                .font(theme.typography.callout)
                .foregroundStyle(theme.colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
            
            HStack(spacing: theme.spacing.md) {
                SocialButton(
                    title: "Google",
                    systemImageName: "google_icon",
                    background: theme.colors.surface,
                    foreground: theme.colors.textPrimary,
                    action: googleSignUp
                )
                
                SocialButton(
                    title: "Facebook",
                    systemImageName: "facebook_icon",
                    background: Color(#colorLiteral(red: 0.176, green: 0.447, blue: 0.886, alpha: 1)),
                    foreground: .white,
                    action: facebookSignUp
                )
            }
            .frame(height: 48)
            
            SocialButton(
                title: "Sign in with Apple",
                systemImageName: "apple_icon",
                background: .black,
                foreground: .white,
                action: appleSignUp
            )
            .frame(height: 48)
        }
    }
    
    @ViewBuilder
    private func footer() -> some View {
        HStack {
            Text("Already have an account?")
                .font(theme.typography.callout)
                .foregroundStyle(theme.colors.textSecondary)
            Button(action: {
                switch origin {
                case .login:
                    // we came from Login -> just dismiss back
                    Router.shared.pop()
                case .welcome:
                    // we came from the Welcome screen -> push Login
                    Router.shared.push(.login)
                }
            }) {
                Text("Login Now")
                    .font(theme.typography.callout)
                    .underline()
                    .foregroundStyle(theme.colors.primary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.bottom, safeBottom() + 8)
    }
    
    // MARK: - Actions
    
    private func signUp() {
        guard isValid else {
            errorMessage = "Please fill all fields correctly, ensure password is at least 6 characters and passwords match, and accept TnC."
            showError = true
            return
        }
        
        isLoading = true
        Task {
            do {
                try await authService.signUp(email: email, password: password, userType: userType(from: gender))
                await MainActor.run {
                    isLoading = false
                    // handle post-signup navigation (e.g., show verification)
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
    private func facebookSignUp() {
        Task {
            do {
                try await authService.signInWithFacebook()
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
    
    // helpers
    private func userType(from gender: String) -> UserType {
        return gender == "Male" ? .patient : .patient // adjust your logic
    }
    
    private func safeTop() -> CGFloat {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        return window?.safeAreaInsets.top ?? 20
    }
    private func safeBottom() -> CGFloat {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        return window?.safeAreaInsets.bottom ?? 0
    }
}

#Preview {
    NavigationView {
        SignUpView(origin: .welcome)
    }
    .appTheme(AppTheme.default)
}
