import SwiftUI
import AlertToast

struct SignUpView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var router: Router
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var authVM: AuthGlobalViewModel
    @EnvironmentObject private var appVM: AppGlobalViewModel
    
    @StateObject private var vm: SignupViewModel
    
    let origin: SignUpOrigin
    let selectedUserType: UserType
    
    init(origin: SignUpOrigin, selectedUserType: UserType) {
        self.origin = origin
        self.selectedUserType = selectedUserType
        _vm = StateObject(wrappedValue: SignupViewModel())
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.lg) {
                header()
                
                // Name
                TextInputField(
                    placeholder: "Enter Name",
                    text: $vm.name,
                    keyboardType: .default,
                    errorText: vm.fieldErrors[.name]
                )
                
                //Username
                TextInputField(
                    placeholder: "Enter username",
                    text: $vm.username,
                    keyboardType: .default,
                    errorText: vm.fieldErrors[.username]
                )
                
                // Email
                TextInputField(
                    placeholder: "Enter Email",
                    text: $vm.email,
                    keyboardType: .emailAddress,
                    errorText: vm.fieldErrors[.email]
                )
                
                // Gender segmented
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    GenderSegment(selected: $vm.gender, left: "Male", right: "Female")
                }
                
                CountryPhoneField(
                    countryCode: $vm.countryCode,
                    phone: $vm.phone,
                    countryCodes: appVM.phoneCodesOnly,
                    errorText: vm.fieldErrors[.phone]
                )
                
                if selectedUserType == .doctor {
                    // Medical License
                    TextInputField(
                        placeholder: "Medical License No",
                        text: $vm.medicalLicense,
                        keyboardType: .default,
                        errorText: vm.fieldErrors[.medicalLicense]
                    )
                    
                    DropdownField(
                        selectedValues: Binding(get: { vm.specializations ?? [] }, set: { vm.specializations = $0 }),
                        items: appVM.specializations,
                        placeholder: "Specialization",
                        title: nil,
                        allowsSearch: true,
                        errorText: vm.fieldErrors[.specializations]
                    )
                }
                
                VStack(spacing: theme.spacing.lg) {
                    formFields()
                }
                .padding(.horizontal, 0)
                
                if selectedUserType == .patient {
                    socialSection()
                }
                
                footer()
                
            }
            .padding(.horizontal, theme.spacing.lg)
            
        }
        .onChange(of: authVM.showOTP) { _, newValue in
            // When viewModel sets showOTP = true, push to OTP screen
            if newValue {
                let phone = authVM.otpPhoneDisplay ?? ""
                router.push(.otp(phoneDisplay: phone, from:.signup))
                // Optionally reset the flag if you don't want it re-triggered
                authVM.showOTP = false
            }
        }
        .background(theme.colors.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear{
            vm.userType = selectedUserType
            Task {
                await appVM.loadCountryCodes()
                await appVM.loadSpecializations()
            }
        }
        .toast(
            isPresenting: $authVM.showErrorToast,
            alert: {
                AlertToast(
                    displayMode: .hud,
                    type: .error(theme.colors.error),
                    title: "Error!",
                    subTitle: authVM.errorMessage
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

            // Passwords
            TextInputField(
                placeholder: "Password",
                text: $vm.password,
                keyboardType: .default,
                isSecure: true,
                errorText: vm.fieldErrors[.password]
            )
            
            TextInputField(
                placeholder: "Confirm Password",
                text: $vm.confirmPassword,
                keyboardType: .default,
                isSecure: true,
                errorText: vm.fieldErrors[.confirmPassword]
            )
            
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
                if authVM.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Create new account")
                }
            }
            .disabled(authVM.isLoading)
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
        
        guard vm.validateSignupFields() else { return }
        
        Task {
            // Extract specialization IDs from the selected Specialization objects
            let specializationIds = vm.specializations?.map { $0.id }
            
            let request = SignUpRequest(
                name: vm.name,
                username: vm.username,
                email: vm.email,
                gender: vm.gender,
                countryCode: vm.countryCode,
                phoneNumber: vm.phone,
                medicalLicenseNumber: vm.medicalLicense,
                specializations: specializationIds,
                description: vm.description,
                password: vm.password,
                confirmPassword: vm.confirmPassword,
                userType: vm.userType
            )
            
            await authVM.signUp(request: request)
        }
    }
    
    private func googleSignUp() {
        Task {
            await authVM.signInWithGoogle()
        }
    }
    private func facebookSignUp() {
        Task {
            await authVM.signInWithFacebook()
        }
    }
    private func appleSignUp() {
        Task {
            //await authVM.signInWithApple()
        }
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

//#Preview {
//    NavigationView {
//        SignUpView(origin: .welcome, selectedUserType: .doctor)
//    }
//    .environmentObject(Router.shared)
//    .appTheme(AppTheme.default)
//}
