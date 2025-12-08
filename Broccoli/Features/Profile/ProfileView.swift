import SwiftUI

struct ProfileView: View {
    
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var authVM: AuthGlobalViewModel
    
    var body: some View {
        
        VStack(spacing: 0) {
            // Header with settings and notification
            HStack {
                Button(action: {
                    // Settings action
                }) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image("settings-icon")
                        )
                        .overlay(
                            Circle()
                                .stroke(theme.colors.border, lineWidth: 1)
                        )
                }
                
                Spacer()
                
                Button(action: {}) {
                    ZStack {
                        Circle()
                            .fill(theme.colors.primary.opacity(0.1))
                            .frame(width: 44, height: 44)
                        
                        Image("notification-icon").frame(width: 40, height: 40)
                        
                        // Notification badge
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .offset(x: 10, y: -10)
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Profile Card
            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    // Profile Image
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image("patient-placeholder")
                                .font(.system(size: 30))
                                .foregroundStyle(.gray)
                        )
                    
                    Button(action: {
                        router.push(.patientProfileDetail)
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            // Name
                            Text(authVM.currentUser?.name ?? "James Hudson")
                                .font(theme.typography.semiBold22)
                                .foregroundStyle(.white)
                            
                            // Email with arrow
                            HStack(spacing: 8) {
                                Text(verbatim: authVM.currentUser?.email ?? "")
                                    .font(theme.typography.regular14)
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.white)
                                    .frame(width: 24, height: 24)
                            }
                            
                            // Basic Plan Badge
                            Text("Basic Plan")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(theme.colors.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white)
                                .cornerRadius(16)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
                .padding(16)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        theme.colors.gradientStart,
                        theme.colors.gradientEnd
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(16)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
            
            // Menu Items List
            List {
                // General Section
                Section {
                    MenuItemRow(
                        icon: "my-reviews-icon",
                        title: "My Medications",
                        action: {}
                    )
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(Color.white)
                    
                    MenuItemRow(
                        icon: "appointment-history-icon",
                        title: "My Appointments",
                        action: {
                            router.push(.myAppointments)
                        }
                    )
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(Color.white)
                    
                    MenuItemRow(
                        icon: "my-pharmacies",
                        title: "My Pharmacies",
                        action: {
                            router.push(.myPharmacies)
                        },
                        isLast: true
                    )
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(Color.white)
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
                        icon: "about-icon",
                        title: "About Broccoli",
                        action: {}
                    )
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(Color.white)
                    
                    MenuItemRow(
                        icon: "contact-us-icon",
                        title: "Contact Us",
                        action: {}
                    )
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(Color.white)
                    
                    MenuItemRow(
                        icon: "privacy-icon",
                        title: "Privacy Policy",
                        action: {}
                    )
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(Color.white)
                    
                    MenuItemRow(
                        icon: "terms-icon",
                        title: "Terms and Conditions",
                        action: {},
                        isLast: true
                    )
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(Color.white)
                } header: {
                    Text("Support")
                        .font(theme.typography.medium16)
                        .foregroundStyle(theme.colors.textPrimary)
                        .textCase(nil)
                }
                .listRowSeparator(.hidden)
                
                // Log Out Section
                Section {
                    MenuItemRow(
                        icon: "terms-icon",
                        title: "Log Out",
                        action: { signOut() },
                        isLast: true
                    )
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(Color.white)
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
            .background(Color(red: 0.96, green: 0.97, blue: 0.98))
            .padding(.top, 20)
        }
        .padding(.bottom, 80)
        .navigationBarHidden(true)
        
        
        
    }
    
    private func signOut() {
        Task {
            await authVM.signOut()
        }
    }
}

#Preview {
    ProfileView()
}
