import SwiftUI

struct PatientHomeView: View {
    @Environment(\.appTheme) private var theme
    @StateObject private var authService = AuthService(
        httpClient: HTTPClient(),
        secureStore: SecureStore()
    )
    
    var body: some View {
        NavigationView {
            VStack(spacing: theme.spacing.lg) {
                // Header
                VStack(spacing: theme.spacing.md) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Good morning,")
                                .font(theme.typography.body)
                                .foregroundStyle(theme.colors.textSecondary)
                            
                            if let user = authService.currentUser {
                                Text("\(user.firstName) \(user.lastName)")
                                    .font(theme.typography.title)
                                    .foregroundStyle(theme.colors.textPrimary)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: signOut) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.title2)
                                .foregroundStyle(theme.colors.textSecondary)
                        }
                    }
                    .padding(.horizontal, theme.spacing.lg)
                }
                
                ScrollView {
                    VStack(spacing: theme.spacing.lg) {
                        // Quick Actions
                        VStack(alignment: .leading, spacing: theme.spacing.md) {
                            Text("Quick Actions")
                                .font(theme.typography.subtitle)
                                .foregroundStyle(theme.colors.textPrimary)
                                .padding(.horizontal, theme.spacing.lg)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: theme.spacing.md) {
                                QuickActionCard(
                                    icon: "calendar.badge.plus",
                                    title: "Book Appointment",
                                    subtitle: "Schedule a consultation",
                                    theme: theme
                                ) {
                                    // Navigate to booking
                                }
                                
                                QuickActionCard(
                                    icon: "message.circle",
                                    title: "Chat with Doctor",
                                    subtitle: "Start a conversation",
                                    theme: theme
                                ) {
                                    // Navigate to chat
                                }
                                
                                QuickActionCard(
                                    icon: "doc.text",
                                    title: "Medical Records",
                                    subtitle: "View your history",
                                    theme: theme
                                ) {
                                    // Navigate to records
                                }
                                
                                QuickActionCard(
                                    icon: "pills",
                                    title: "Medications",
                                    subtitle: "Manage prescriptions",
                                    theme: theme
                                ) {
                                    // Navigate to medications
                                }
                            }
                            .padding(.horizontal, theme.spacing.lg)
                        }
                        
                        // Upcoming Appointments
                        VStack(alignment: .leading, spacing: theme.spacing.md) {
                            Text("Upcoming Appointments")
                                .font(theme.typography.subtitle)
                                .foregroundStyle(theme.colors.textPrimary)
                                .padding(.horizontal, theme.spacing.lg)
                            
                            // Placeholder for appointments
                            VStack {
                                Image(systemName: "calendar")
                                    .font(.system(size: 48))
                                    .foregroundStyle(theme.colors.textSecondary)
                                
                                Text("No upcoming appointments")
                                    .font(theme.typography.body)
                                    .foregroundStyle(theme.colors.textSecondary)
                                
                                Text("Book your first consultation")
                                    .font(theme.typography.callout)
                                    .foregroundStyle(theme.colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(theme.spacing.xl)
                            .background(theme.colors.surface)
                            .cornerRadius(theme.cornerRadius)
                            .padding(.horizontal, theme.spacing.lg)
                        }
                    }
                }
            }
            .background(theme.colors.background)
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func signOut() {
        Task {
            try? await authService.signOut()
        }
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let theme: AppThemeProtocol
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: theme.spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(theme.colors.primary)
                
                VStack(spacing: theme.spacing.xs) {
                    Text(title)
                        .font(theme.typography.callout)
                        .foregroundStyle(theme.colors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(theme.spacing.lg)
            .background(theme.colors.surface)
            .cornerRadius(theme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(theme.colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PatientHomeView()
        .appTheme(AppTheme.default)
}
