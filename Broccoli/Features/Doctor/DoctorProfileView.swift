//
//  DoctorProfileView.swift
//  Broccoli
//
//  Created by AI Assistant on 02/11/25.
//

import SwiftUI

struct DoctorProfileView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var authVM: AuthGlobalViewModel
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background with gradient
            VStack(alignment:.leading, spacing: 0) {
                LinearGradient(
                    gradient: Gradient(colors: [
                        theme.colors.gradientStart,
                        theme.colors.gradientEnd
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 320)
            }
            .ignoresSafeArea()
            
            VStack(alignment:.leading ,spacing: 0) {
                // Header with back button and settings
                HStack {
                    Button(action: { router.pop() }) {
                        Image("back-icon-white")
                            .frame(width: 30, height: 30)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Settings action
                        router.push(.settings)
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image("settings-icon")
                            )
                    }
                }
                .padding(.horizontal, 20)
                
                // Profile Card
                VStack(spacing: 0) {
                    Button(action: { router.push(.doctorProfileDetail) }) {
                        HStack(alignment: .top) {
                            // Profile Image
                            Rectangle()
                                .frame(width: 120, height: 144)
                                .cornerRadius(8)
                                .overlay(
                                    Image("doctor-square-placeholder")
                                )
                            
                            
                            VStack(alignment: .leading, spacing: 8) {
                                // Name
                                Text(authVM.currentUser?.name ?? "Doctor Name")
                                    .font(theme.typography.bold30)
                                    .foregroundStyle(.white)
                                
                                // Email
                                if let email = authVM.currentUser?.email {
                                    Text(email)
                                        .font(theme.typography.regular14)
                                        .foregroundColor(.white)
                                }
                                
                                // Specialization
                                if let specialization = authVM.currentUser?.specialization {
                                    Text(specialization.name)
                                        .font(theme.typography.bold20)
                                        .foregroundStyle(.white)
                                }
                                
                                // Rating and Price
                                HStack(spacing: 16) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .foregroundStyle(.white)
                                            .font(.system(size: 16))
                                        Text("4.5")
                                            .font(theme.typography.bold18)
                                            .foregroundStyle(.white)
                                    }
                                    Spacer()
                                    // HStack(spacing: 4) {
                                    //     Image("dollar-symbol")
                                    //     Text("€230")
                                    //         .font(theme.typography.semiBold18)
                                    // }
                                    // .padding(.horizontal, 12)
                                    // .padding(.vertical, 8)
                                    // .background(Color.white.opacity(0.2))
                                    // .cornerRadius(20)
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding(20)
                    }
                    
                    
                    // Stats Card
                    HStack(spacing: 0) {
                        StatItem(number: "12 Years", label: "Experience")
                        
                        Divider()
                            .frame(height: 40)
                            .background(Color.gray.opacity(0.3))
                        
                        StatItem(number: "1.5K", label: "Patients")
                        
                        Divider()
                            .frame(height: 40)
                            .background(Color.gray.opacity(0.3))
                        
                        StatItem(number: "1.3K", label: "Reviews")
                    }
                    .padding(.vertical, 20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                    
                    // Menu Items List
                    List {
                        // General Section
                        Section {
                            MenuItemRow(
                                icon: "my-reviews-icon",
                                title: "My Reviews",
                                action: {}
                            )
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .listRowBackground(theme.colors.background)
                            
                            MenuItemRow(
                                icon: "appointment-history-icon",
                                title: "Appointment History",
                                action: {}
                            )
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .listRowBackground(theme.colors.background)
                            
                            MenuItemRow(
                                icon: "about-icon",
                                title: "About Broccoli",
                                action: {},
                                isLast: true
                            )
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .listRowBackground(theme.colors.background)
                        } header: {
                            Text("General")
                                .font(theme.typography.medium16)
                                .foregroundStyle(theme.colors.textPrimary)
                                .textCase(nil)
                        }
                        .listRowSeparator(.hidden)
                        
                        // Support Section
                        Section {
                            MenuItemRow(
                                icon: "contact-us-icon",
                                title: "Contact Us",
                                action: {}
                            )
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .listRowBackground(theme.colors.background)
                            
                            MenuItemRow(
                                icon: "privacy-icon",
                                title: "Privacy Policy",
                                action: {}
                            )
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .listRowBackground(theme.colors.background)
                            
                            MenuItemRow(
                                icon: "terms-icon",
                                title: "Terms and Conditions",
                                action: {},
                                isLast: true
                            )
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .listRowBackground(theme.colors.background)
                        } header: {
                            Text("Support")
                                .font(theme.typography.medium16)
                                .foregroundStyle(theme.colors.textPrimary)
                                .textCase(nil)
                        }
                        .listRowSeparator(.hidden)
                        
                        // Support Section
                        Section {
                            MenuItemRow(
                                icon: "contact-us-icon",
                                title: "Log Out",
                                action: {signOut()}
                            )
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .listRowBackground(theme.colors.background)
                            
                        } header: {
                            Text("")
                                .font(theme.typography.medium16)
                                .foregroundStyle(theme.colors.textPrimary)
                                .textCase(nil)
                        }
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(Color.white)
                }
            }
        }
        .navigationBarHidden(true)
        .onChange(of: authVM.isAuthenticated) { _, isAuthenticated in
            if !isAuthenticated {
                // User signed out, dismiss the profile view
                dismiss()
            }
        }
    }
    
    private func signOut() {
        Task {
            await authVM.signOut()
        }
    }
}

#Preview {
    DoctorProfileView()
        .environment(\.appTheme, AppTheme.default)
}
