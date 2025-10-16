import SwiftUI
import AlertToast

struct LoginView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var authVM: AuthGlobalViewModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var keepLoggedIn = true
    @State private var showError = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Top logo + spacing
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 118, height: 83)
                    .padding(.top, 40)
                
                // Title
                Text("Login to your account")
                    .font(theme.typography.title)
                    .foregroundStyle(theme.colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
            }
            .padding(.bottom, theme.spacing.xl)
            
            // Form container
            
            VStack(spacing: theme.spacing.lg) {
                VStack(spacing: theme.spacing.md) {
                    // Username / Email
                    TextField("Username/Email Address", text: $email)
                        .textFieldStyle(CustomTextFieldStyle(theme: theme))
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    // Password
                    SecureField("Password", text: $password)
                        .textFieldStyle(CustomTextFieldStyle(theme: theme))
                }
                
                // Keep me login + Forgot
                HStack {
                    CheckboxToggle(isOn: $keepLoggedIn, label: "Keep me login")
                    Spacer()
                    NavigationLink(destination: ForgotPasswordView()) {
                        Text("Forgot Password")
                            .font(theme.typography.callout)
                            .foregroundStyle(theme.colors.primary)
                    }
                }
                .padding(.horizontal, 2)
                
                // Login button
                PrimaryButton(action: login) {
                    if authVM.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Login")
                    }
                }
                .disabled(authVM.isLoading || email.isEmpty || password.isEmpty)
                .padding(.top, theme.spacing.sm)
                
                // "Or login with" text
                Text("Or login with")
                    .font(theme.typography.callout)
                    .foregroundStyle(theme.colors.textSecondary)
                    .padding(.top, theme.spacing.md)
                
                // Social buttons (Google / Facebook) horizontally then Apple full width
                HStack(spacing: theme.spacing.md) {
                    SocialButton(
                        title: "Google",
                        systemImageName: "google_icon",
                        background: theme.colors.surface,
                        foreground: theme.colors.textPrimary,
                        action: googleSignIn
                    )
                    
                    SocialButton(
                        title: "Facebook",
                        systemImageName: "facebook_icon",
                        background: Color(#colorLiteral(red: 0.176, green: 0.447, blue: 0.886, alpha: 1)), // facebook-blue
                        foreground: .white,
                        action: facebookSignIn
                    )
                }
                .frame(height: 48)
                
                SocialButton(
                    title: "Sign in with Apple",
                    systemImageName: "apple_icon",
                    background: .black,
                    foreground: .white,
                    action: appleSignIn
                )
                .frame(height: 48)
                
                // Bottom signup chips
                HStack(spacing: theme.spacing.md) {
                    Button {
                        Router.shared.push(.signup(origin: .login, userType: .patient))
                    } label: {
                        GrayOutlineButtonView(title:"Signup as User")
                    }.buttonStyle(PlainButtonStyle())
                    
                    Button {
                        Router.shared.push(.signup(origin: .login, userType: .doctor))
                    } label: {
                        GrayOutlineButtonView(title: "Signup as Doctor")
                    }.buttonStyle(PlainButtonStyle())
                }
                .padding(.bottom, bottomSafeAreaInset() + 10)
                .padding(.top, 100)
            }
            .padding(.top, theme.spacing.md)
        }
        .padding(.horizontal, theme.spacing.xl)
        .background(theme.colors.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true)
        .toast(isPresenting: $showError) {
            AlertToast(displayMode: .hud, type: .error(theme.colors.error), title: "Error!", subTitle:authVM.errorMessage)
        }
    }
    
    // MARK: - Actions
    
    private func login() {
        Task {
            await authVM.signIn(email: email, password: password)
        }
    }
    
    private func googleSignIn() {
        Task {
            await authVM.signInWithGoogle()
        }
    }
    
    private func facebookSignIn() {
        // implement facebook flow or call authService
        Task {
            await authVM.signInWithFacebook()
        }
    }
    
    private func appleSignIn() {
        Task {
            //await authVM.signInWithApple()
        }
    }
    
    // Safe area helpers
    private func topSafeAreaInset() -> CGFloat {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        return window?.safeAreaInsets.top ?? 20
    }
    
    private func bottomSafeAreaInset() -> CGFloat {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        return window?.safeAreaInsets.bottom ?? 0
    }
}

#Preview {
    NavigationView {
        LoginView()
    }
    .appTheme(AppTheme.default)
}
