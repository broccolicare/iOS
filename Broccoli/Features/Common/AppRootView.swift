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
    @EnvironmentObject private var authVM: AuthGlobalViewModel
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        Group {
            if authVM.isAuthenticated {
                // User is logged in - show appropriate home screen based on user type
                if let user = authVM.currentUser {
                    switch user.role {
                    case .patient:
                        PatientHomeView()
                    case .doctor:
                        DoctorHomeView()
                    case .none:
                        PatientRootTabView()
                    }
                } else {
                    // Fallback in case user data is missing
                    PatientRootTabView()
                }
            } else {
                // User is not logged in - show welcome screen
                WelcomeView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authVM.isAuthenticated)
        .onAppear {
            // Check authentication status when app appears
            Task {
                await authVM.checkAuthenticationStatus()
            }
        }
    }
}

#Preview {
    AppRootView()
        .appTheme(AppTheme.default)
}


