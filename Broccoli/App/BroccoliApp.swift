//
//  BroccoliApp.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 07/10/25.
//

import SwiftUI

@main
struct BroccoliApp: App {
    
    // Dependencies are created within the StateObject closures to avoid capturing self during App init
    
    @StateObject private var router = Router.shared
    
    @StateObject private var authViewModel: AuthGlobalViewModel = {
        let httpClient = HTTPClient() as any HTTPClientProtocol
        let secureStore = SecureStore() as any SecureStoreProtocol
        let authService = AuthService(httpClient: httpClient, secureStore: secureStore)
        return AuthGlobalViewModel(authService: authService, secureStore: secureStore)
    }()
    
    @StateObject private var appViewModel: AppGlobalViewModel = {
        let httpClient = HTTPClient() as any HTTPClientProtocol
        let appService = AppService(httpClient: httpClient)
        return AppGlobalViewModel(appService: appService)
    }()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path){
                AppRootView()
                    .navigationDestination(for: Route.self) { route in
                        switch route {
                        case .welcome:
                            WelcomeView()
                        case .login:
                            LoginView()
                        case .signup(let origin, let userType):
                            SignUpView(origin: origin, selectedUserType: userType)
                        case .home:
                            // Route to appropriate home screen based on user type
                            if let user = authViewModel.currentUser {
                                switch user.role {
                                case .patient:
                                    PatientHomeView()
                                case .doctor:
                                    DoctorHomeView()
                                case .none:
                                    WelcomeView()
                                }
                            } else {
                                WelcomeView()
                            }
                        case .profile(userId: let userId):
                            EmptyView()
                        case .booking(id: let id):
                            EmptyView()
                        case .staticPage(type: let type):
                            StaticPageView(pageType: type)
                        case .otp(phoneDisplay: let phoneDisplay, from: let otpSource):
                            OTPVerificationView(phoneDisplay: phoneDisplay, from: otpSource)
                        case .signupSuccess:
                            SignUpSuccessView()
                        case .resetPassword(email: let email, otp: let otp):
                            ResetPasswordView(email: email, otp: otp)
                        }
                    }
            }
            .environmentObject(router)
            .environmentObject(authViewModel)
            .environmentObject(appViewModel)
            .environment(\.appTheme, AppTheme.default)
        }
    }
}
