//
//  BroccoliApp.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 07/10/25.
//

import SwiftUI

@main
struct BroccoliApp: App {
    
    private let httpClient: any HTTPClientProtocol = HTTPClient()
    private let secureStore: any SecureStoreProtocol = SecureStore()
    let authService: AuthService
    @StateObject private var router = Router.shared

    
    init() {
        self.authService = AuthService(httpClient: httpClient, secureStore: secureStore)
    }
    
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
                        case .signup(let origin):
                            SignUpView(origin: origin)
                        case .home:
                            EmptyView()
                        case .profile(userId: let userId):
                            EmptyView()
                        case .booking(id: let id):
                            EmptyView()
                        }
                    }
            }
            .environmentObject(router)
            .environment(\.appTheme, AppTheme.default)
        }
    }
}
