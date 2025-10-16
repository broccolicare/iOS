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
    
    public func verifyOTP(code: String) async {
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
            print("verifyOTP error: \(error)")
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
        // save tokens to secure store (adapt to your AuthResponse fields)
//        if let access = resp.accessToken {
//            try authService.secureStore.store(access, for: SecureStore.Keys.accessToken)
//        }
//        if let refresh = resp.refreshToken {
//            try authService.secureStore.store(refresh, for: SecureStore.Keys.refreshToken)
//        }
        
        // update UI state
        isAuthenticated = true
        currentUser = resp.user
    }
    
    private func clearAuthState() async {
        isAuthenticated = false
        currentUser = nil
    }
    
    // Re-check tokens / session (initialization step)
    public func checkAuthenticationStatus() async {
        do {
            if let token: String = try secureStore.retrieve(for: SecureStore.Keys.accessToken) {
                isAuthenticated = !token.isEmpty
                // Optionally fetch user profile here
            } else {
                isAuthenticated = false
            }
        } catch {
            isAuthenticated = false
        }
    }
}
