//  AuthService.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 07/10/25.
//

import Foundation
import GoogleSignIn
import FacebookLogin
import AuthenticationServices
import SwiftUI

struct AppRootView: View {
    @StateObject private var authService = AuthService(
        httpClient: HTTPClient(),
        secureStore: SecureStore()
    )
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                // User is logged in - show appropriate home screen based on user type
                if let user = authService.currentUser {
                    switch user.userType {
                    case .patient:
                        PatientHomeView()
                    case .doctor:
                        DoctorHomeView()
                    }
                } else {
                    // Fallback in case user data is missing
                    WelcomeView()
                }
            } else {
                // User is not logged in - show welcome screen
                WelcomeView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authService.isAuthenticated)
        .onAppear {
            // Check authentication status when app appears
            Task {
                await authService.checkAuthenticationStatus()
            }
        }
    }
}

#Preview {
    AppRootView()
        .appTheme(AppTheme.default)
}


