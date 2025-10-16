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
                            EmptyView()
                        case .profile(userId: let userId):
                            EmptyView()
                        case .booking(id: let id):
                            EmptyView()
                        case .staticPage(type: let type):
                            StaticPageView(pageType: type)
                        case .otp(phoneDisplay: let phoneDisplay):
                            OTPVerificationView(phoneDisplay: phoneDisplay)
                        case .signupSuccess:
                            SignUpSuccessView()
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
