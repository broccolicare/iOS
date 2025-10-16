//
//  OTPVerificationView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 16/10/25.
//
import SwiftUI
import AlertToast

struct OTPVerificationView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var authVM: AuthGlobalViewModel
    
    @StateObject private var vm: OTPViewModel
    @State private var activeText: String = ""
    @FocusState private var isFocused: Bool
    
    let phoneDisplay: String
    let onEditPhone: (() -> Void)?
    
    // Provide initializer so view constructs VM itself
    init(phoneDisplay: String,
         onEditPhone: (() -> Void)? = nil,
         digitsCount: Int = 6,
         countdown: Int = 60) {
        self.phoneDisplay = phoneDisplay
        self.onEditPhone = onEditPhone
        _vm = StateObject(wrappedValue: OTPViewModel(digitsCount: digitsCount, countdown: countdown))
    }
    
    var body: some View {
        VStack {
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image("BackButton")
                        .font(.system(size: 22))
                        .foregroundStyle(theme.colors.surface)
                        .padding(6)
                }
                Spacer()
            }
            .padding(.horizontal, theme.spacing.xl)
            
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    VStack(alignment: .leading, spacing: theme.spacing.sm) {
                        Text("Enter \(vm.digits.count) digit code")
                            .font(theme.typography.title)
                            .foregroundStyle(theme.colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("We have sent a verification code on your registered email.")
                            .font(theme.typography.callout)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                        
                    Spacer().frame(height: 16)
                    // phone display + edit
                    HStack(alignment: .center) {
                        Text(phoneDisplay)
                            .font(theme.typography.subtitle)
                            .foregroundStyle(theme.colors.textPrimary)
                            .bold()
                        
                        if let onEdit = onEditPhone {
                            Button("Edit") { onEdit() }
                                .font(theme.typography.callout)
                                .foregroundStyle(theme.colors.primary)
                                .buttonStyle(PlainButtonStyle())
                                .underline()
                        }
                        Spacer()
                    }
                    Spacer().frame(height: 16)
                    // OTP boxes
                    otpBoxes()
                    
                    // Hidden text field to capture input
                    TextField("", text: $activeText)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .accentColor(.clear)
                        .foregroundColor(.clear)
                        .disableAutocorrection(true)
                        .frame(width: 1, height: 1)
                        .opacity(0.01)
                        .onChange(of: activeText) { _, newValue in
                            handleInput(newValue)
                        }
                        .focused($isFocused)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                isFocused = true
                            }
                        }
                    
                    // Validate button - view implements action
                    Button(action: { validate() }) {
                        if authVM.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity, minHeight: 56)
                                .background(theme.colors.primary)
                                .cornerRadius(theme.cornerRadius)
                        } else {
                            Text("Validate")
                                .font(theme.typography.button)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(theme.colors.primary)
                                .cornerRadius(theme.cornerRadius)
                        }
                    }
                    .disabled(!vm.isValid || authVM.isLoading)
                    .buttonStyle(PlainButtonStyle())
                    
                    // Resend / countdown & link
                    HStack(spacing: 2) {
                        Text("You didn’t receive any code?")
                            .font(theme.typography.callout)
                            .foregroundStyle(theme.colors.textSecondary)
                        if vm.resendCountdown > 0 {
                            Text("Resend in \(vm.resendCountdown)s")
                                .font(theme.typography.callout)
                                .foregroundStyle(theme.colors.textSecondary)
                        } else {
                            Button(action: { resend() }) {
                                Text("Resend Now")
                                    .font(theme.typography.callout)
                                    .foregroundStyle(theme.colors.primary)
                                    .underline()
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.top, 6)
                    Spacer(minLength: 60)
                }
                .padding(.horizontal, theme.spacing.xl)
                .padding(.vertical, theme.spacing.xxl)
            } // ScrollView
        }
        .background(theme.colors.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .onChange(of: authVM.showOtpVerificationSuccess) { _, newValue in
            if newValue {
                router.push(.signupSuccess)
                authVM.showOtpVerificationSuccess = false
            }
        }
        .toast(isPresenting: $authVM.otpShowToast, duration: 3.0, tapToDismiss: true) {
            if authVM.otpToastIsError {
                return AlertToast(type: .error(.red), title: authVM.otpToastMessage)
            } else {
                return AlertToast(type: .complete(.green), title: authVM.otpToastMessage)
            }
        }
    }
    
    // MARK: - View action implementations
    
    private func validate() {
        guard vm.isValid else {
            vm.showUserError("Please enter a \(vm.digits.count)-digit code.")
            return
        }
        Task {
            await authVM.verifyOTP(code: vm.code)
        }
    }
    
    private func resend() {
        guard vm.resendCountdown <= 0 else { return }
        
        Task {
            await authVM.resendOTP()
        }
    }
    
    // MARK: - Helpers
    
    private func handleInput(_ newValue: String) {
        let digitsOnly = newValue.filter { $0.isWholeNumber }
        let chars = Array(digitsOnly)
        for i in 0..<vm.digits.count {
            vm.digits[i] = i < chars.count ? String(chars[i]) : ""
        }
        if digitsOnly.count >= vm.digits.count {
//            activeText = ""
            // Optionally auto-validate:
             validate()
        }
    }
    
    @ViewBuilder
    private func otpBoxes() -> some View {
        HStack(spacing: 12) {
            ForEach(0..<vm.digits.count, id: \.self) { idx in
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.colors.otpInputBox)
                        .frame(width: 48, height: 48)
                        .shadow(radius: 0.5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(theme.colors.otpInputBox, lineWidth: 1)
                        )
                    
                    Text(vm.digits[idx].isEmpty ? "" : vm.digits[idx])
                        .font(theme.typography.title)
                        .foregroundStyle(theme.colors.textPrimary)
                }
                .onTapGesture {
                    isFocused = true
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func safeTop() -> CGFloat {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        return window?.safeAreaInsets.top ?? 20
    }
}

//struct OTPVerificationView_Previews: PreviewProvider {
//    static var previews: some View {
//        OTPVerificationView(phoneDisplay: "jaigaurav17+p10@gmail.com", onEditPhone: {
//            print("Edit phone tapped")
//        })
//        .environment(\.appTheme, AppTheme.default)
//    }
//}
