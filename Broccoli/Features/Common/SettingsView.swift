//
//  SettingsView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 27/12/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var router: Router
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    router.pop()
                }) {
                    Image("BackButton")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(theme.colors.primary)
                }
                
                Spacer()
                
                Text("Settings")
                    .font(theme.typography.medium22)
                    .foregroundStyle(theme.colors.textPrimary)
                
                Spacer()
                
                // Invisible spacer to center the title
                Circle()
                    .fill(Color.clear)
                    .frame(width: 44, height: 44)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Notifications Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notifications")
                            .font(theme.typography.bold18)
                            .foregroundStyle(theme.colors.textPrimary)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            SettingsItemRow(
                                icon: "bell",
                                iconColor: Color(red: 0.26, green: 0.65, blue: 0.58),
                                title: "Notifications",
                                subtitle: "Manage your notification preferences",
                                isLast: true,
                                action: {
                                    // Navigate to notifications settings
                                }
                            )
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                    
                    // Privacy Section
//                    VStack(alignment: .leading, spacing: 12) {
//                        Text("Privacy")
//                            .font(theme.typography.semiBold16)
//                            .foregroundStyle(theme.colors.textPrimary)
//                            .padding(.horizontal, 20)
//                        
//                        VStack(spacing: 0) {
//                            SettingsItemRow(
//                                icon: "shield",
//                                iconColor: Color(red: 0.26, green: 0.65, blue: 0.58),
//                                title: "Privacy",
//                                subtitle: "Manage your privacy settings",
//                                isLast: true,
//                                action: {
//                                    // Navigate to privacy settings
//                                }
//                            )
//                        }
//                        .background(Color.white)
//                        .cornerRadius(12)
//                        .padding(.horizontal, 20)
//                    }
                    
                    // App Preferences Section
//                    VStack(alignment: .leading, spacing: 12) {
//                        Text("App Preferences")
//                            .font(theme.typography.semiBold16)
//                            .foregroundStyle(theme.colors.textPrimary)
//                            .padding(.horizontal, 20)
//                        
//                        VStack(spacing: 0) {
//                            SettingsItemRow(
//                                icon: "gearshape",
//                                iconColor: Color(red: 0.26, green: 0.65, blue: 0.58),
//                                title: "App Preferences",
//                                subtitle: "Manage your app preferences",
//                                isLast: true,
//                                action: {
//                                    // Navigate to app preferences
//                                }
//                            )
//                        }
//                        .background(Color.white)
//                        .cornerRadius(12)
//                        .padding(.horizontal, 20)
//                    }
                    
                    // Support Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Support")
                            .font(theme.typography.semiBold16)
                            .foregroundStyle(theme.colors.textPrimary)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            SettingsItemRow(
                                icon: "envelope",
                                iconColor: Color(red: 0.26, green: 0.65, blue: 0.58),
                                title: "Contact Us",
                                subtitle: "Contact us for assistance",
                                isLast: true,
                                action: {
                                    // Navigate to contact us
                                }
                            )
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 20)
            }
            .background(Color(red: 0.96, green: 0.97, blue: 0.98))
        }
        .background(Color(red: 0.96, green: 0.97, blue: 0.98))
        .navigationBarHidden(true)
    }
}

// MARK: - Settings Item Row Component
struct SettingsItemRow: View {
    @Environment(\.appTheme) private var theme
    
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    var isLast: Bool = false
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: action) {
                HStack(spacing: 16) {
                    // Icon with background
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: icon)
                                .font(.system(size: 20))
                                .foregroundColor(iconColor)
                        )
                    
                    // Title and subtitle
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(theme.typography.medium18)
                            .foregroundStyle(theme.colors.textPrimary)
                        
                        Text(subtitle)
                            .font(theme.typography.regular14)
                            .foregroundStyle(theme.colors.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(red: 0.7, green: 0.7, blue: 0.7))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            
            if !isLast {
                Divider()
                    .padding(.leading, 84)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        SettingsView()
            .environment(\.appTheme, AppTheme.default)
    }
}
