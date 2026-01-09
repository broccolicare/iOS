//
//  AuthViewModel.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 13/10/25.
//


// GlobalViewModels/AuthGlobalViewModel.swift
import Foundation
import Combine

@MainActor
public final class AuthGlobalViewModel: ObservableObject {
    // Public UI state
    @Published public private(set) var isAuthenticated: Bool = false
    @Published public private(set) var currentUser: User? = nil
    
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    
    
    @Published var showErrorToast: Bool = false
    
    @Published var showOTP: Bool = false
    @Published var otpPhoneDisplay: String? = nil
    
    //OTP Verification
    @Published var otpShowToast: Bool = false
    @Published var otpToastMessage: String? = nil
    @Published var otpToastIsError: Bool = true
    @Published var showOtpVerificationSuccess: Bool = false
    
    
    var signupResponseObject: SignupResponse? = nil
    
    private let authService: AuthServiceProtocol
    private let secureStore: SecureStoreProtocol
    
    
    
    public init(authService: AuthServiceProtocol, secureStore: SecureStoreProtocol) {
        self.authService = authService
        self.secureStore = secureStore
    }
    
    // MARK: - Authentication operations (UI-facing wrappers)
    
    public func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let resp = try await authService.signIn(email: email, password: password)
            try await handleAuthResponse(resp)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            showErrorToast = true
        }
        isLoading = false
    }
    
    public func signUp(request: SignUpRequest) async {
        
        isLoading = true
        errorMessage = nil
        do {
            signupResponseObject = try await authService.signUp(request: request)
            
            let display = "\(request.email)"
            otpPhoneDisplay = display
            showOTP = true
            
        } catch let srvErr as ServiceError {
            // Show server-provided message
            errorMessage = srvErr.errorDescription ?? "Something went wrong"
            showErrorToast = true
        } catch {
            // generic fallback
            errorMessage = error.localizedDescription
            showErrorToast = true
            print("Signup error: \(error)")
        }
        isLoading = false
    }
    
    public func signOut() async {
        isLoading = true
        do {
            try await authService.signOut()
            await clearAuthState()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }
    
    /// Force logout without API call - used for handling 401 errors
    public func forceLogout() async {
        await clearAuthState()
    }
    
    public func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        do {
            let token = try await authService.signInWithGoogle()
            // Now call your backend to exchange token for app auth if needed
            // Example: await signInWithProvider(.google, token: token)
            // For demo, just set isAuthenticated true if token exists
            try await handleExternalToken(token)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }
    
    public func signInWithFacebook() async {
        isLoading = true
        errorMessage = nil
        do {
            let token = try await authService.signInWithFacebook()
            try await handleExternalToken(token)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }
    
    public func verifyEmail(code: String) async {
        isLoading = true
        otpToastMessage = nil
        do {
            let _ = try await authService.verifyEmail(userId: "\(signupResponseObject?.user?.id, default: "")", otp: code)
            showOtpVerificationSuccess = true
            otpToastMessage = "OTP verified successfully"
            otpShowToast = true
        } catch let srvErr as ServiceError {
            // Show server-provided message
            otpToastMessage = srvErr.errorDescription ?? "Something went wrong"
            otpToastIsError = true
            otpShowToast = true
        } catch {
            // generic fallback
            otpToastMessage = error.localizedDescription
            otpToastIsError = true
            otpShowToast = true
            print("verifyEmail error: \(error)")
        }
        isLoading = false
    }
    
    public func verifyOtp(email: String, code: String) async {
        isLoading = true
        otpToastMessage = nil
        do {
            let _ = try await authService.verifyOtp(email: email, otp: code)
            showOtpVerificationSuccess = true
            otpToastMessage = "OTP verified successfully"
            otpShowToast = true
        } catch let srvErr as ServiceError {
            // Show server-provided message
            otpToastMessage = srvErr.errorDescription ?? "Something went wrong"
            otpToastIsError = true
            otpShowToast = true
        } catch {
            // generic fallback
            otpToastMessage = error.localizedDescription
            otpToastIsError = true
            otpShowToast = true
            print("verifyEmail error: \(error)")
        }
        isLoading = false
    }
    
    public func resendOTP() async {
        isLoading = true
        otpToastMessage = nil
        do {
            let _ = try await authService.resendOtp(userId: "\(signupResponseObject?.user?.id, default: "")")
            otpToastIsError = false
            otpToastMessage = "OTP resent successfully"
            otpShowToast = true
        } catch let srvErr as ServiceError {
            // Show server-provided message
            otpToastMessage = srvErr.errorDescription ?? "Something went wrong"
            otpToastIsError = true
            otpShowToast = true
        } catch {
            // generic fallback
            otpToastMessage = error.localizedDescription
            otpToastIsError = true
            otpShowToast = true
            print("verifyOTP error: \(error)")
        }
        isLoading = false
    }
    
    public func forgotPassword(email: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let _ = try await authService.forgotPassword(email: email)
            // Success - the view will handle showing success message
        } catch let srvErr as ServiceError {
            errorMessage = srvErr.errorDescription ?? "Failed to send reset email"
        } catch {
            errorMessage = "Failed to send reset email. Please try again."
        }
        
        isLoading = false
    }
    
    public func resetPassword(email: String, otp: String, newPassword: String, confirmPassword: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let _ = try await authService.resetPassword(email: email, otp: otp, newPassword: newPassword, confirmPassword: confirmPassword)
            // Success - the view will handle showing success message
        } catch let srvErr as ServiceError {
            errorMessage = srvErr.errorDescription ?? "Failed to reset password"
        } catch {
            errorMessage = "Failed to reset password. Please try again."
        }
        
        isLoading = false
    }
    

    
    // MARK: - Helpers
    
    private func handleExternalToken(_ token: String) async throws {
        // Exchange provider token with backend (example)
        // let resp = try await authService.exchangeProviderToken(token)
        // try await handleAuthResponse(resp)
        
        // placeholder: mark authenticated if token non-empty
        if !token.isEmpty {
            isAuthenticated = true
        }
    }
    
    private func handleAuthResponse(_ resp: AuthResponse) async throws {
        // Store access token to secure store
        if let token = resp.token {
            try secureStore.store(token, for: SecureStore.Keys.accessToken)
        }
        
        // Store user data as JSON to secure store
        if let user = resp.user {
            let userData = try JSONEncoder().encode(user)
            let userDataString = String(data: userData, encoding: .utf8) ?? ""
            try secureStore.store(userDataString, for: SecureStore.Keys.userData)
        }
        
        // Update UI state
        isAuthenticated = true
        currentUser = resp.user
        
        // Clear any previous error messages
        errorMessage = nil
    }
    
    private func clearAuthState() async {
        // Clear stored access token and user data
        try? secureStore.delete(for: SecureStore.Keys.accessToken)
        try? secureStore.delete(for: SecureStore.Keys.userData)
        
        // Update UI state
        isAuthenticated = false
        currentUser = nil
        
        // Clear navigation stack
        await MainActor.run {
            Router.shared.popToRoot()
        }
    }
    
    // Re-check tokens / session (initialization step)
    public func checkAuthenticationStatus() async {
        print("🔍 Starting authentication check...")
        
        do {
            if let token: String = try secureStore.retrieve(for: SecureStore.Keys.accessToken),
               !token.isEmpty {
                print("✅ Found access token: \(token.prefix(20))...")
                
                // Token exists, now try to restore user data
                if let userDataString: String = try secureStore.retrieve(for: SecureStore.Keys.userData),
                   let userData = userDataString.data(using: .utf8) {
                    
                    print("📦 Found user data, attempting to decode...")
                    
                    // Decode user data from JSON
                    let user = try JSONDecoder().decode(User.self, from: userData)
                    
                    print("✅ Successfully decoded user: \(user.name), role: \(user.primaryRole?.rawValue ?? "unknown")")
                    
                    // Restore authentication state
                    isAuthenticated = true
                    currentUser = user
                    
                    print("✅ Authentication restored successfully")
                } else {
                    print("⚠️ Token exists but no user data - clearing authentication")
                    // Token exists but no user data - clear everything for safety
                    try? secureStore.delete(for: SecureStore.Keys.accessToken)
                    isAuthenticated = false
                    currentUser = nil
                }
            } else {
                print("ℹ️ No token found - user not authenticated")
                // No token found
                isAuthenticated = false
                currentUser = nil
            }
        } catch {
            print("❌ Error during auth check: \(error.localizedDescription)")
            // Error occurred - clear authentication state
            isAuthenticated = false
            currentUser = nil
            try? secureStore.delete(for: SecureStore.Keys.accessToken)
            try? secureStore.delete(for: SecureStore.Keys.userData)
        }
        
        print("🏁 Authentication check completed. isAuthenticated: \(isAuthenticated)")
    }
    
    
}
