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
    
    @State private var isCheckingAuth = true
    
    var body: some View {
        ZStack {
            if isCheckingAuth {
                // Show loading view while checking authentication
                theme.colors.background.ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(theme.colors.primary)
                    Text("Loading...")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
            } else if authVM.isAuthenticated {
                // User is logged in - show appropriate home screen based on user type
                if let user = authVM.currentUser, let role = user.primaryRole {
                    switch role {
                    case .patient:
                        PatientRootTabView()
                            .onAppear {
                                print("✅ PatientRootTabView appeared for role: patient")
                            }
                    case .doctor:
                        DoctorHomeView()
                            .onAppear {
                                print("✅ DoctorHomeView appeared for role: doctor")
                            }
                    }
                } else {
                    WelcomeView()
                        .onAppear {
                            print("⚠️ Authenticated but no user data - showing welcome")
                        }
                }
            } else {
                WelcomeView()
                    .onAppear {
                        print("👋 User not authenticated - showing welcome")
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authVM.isAuthenticated)
        .task {
            print("🚀 AppRootView: Starting auth check...")
            await authVM.checkAuthenticationStatus()
            print("✅ AppRootView: Auth check completed")
            await MainActor.run {
                isCheckingAuth = false
            }
        }
    }
}

#Preview {
    AppRootView()
        .appTheme(AppTheme.default)
}
