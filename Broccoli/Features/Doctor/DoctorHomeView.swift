import SwiftUI

struct DoctorHomeView: View {
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
                            Text("Welcome back,")
                                .font(theme.typography.body)
                                .foregroundStyle(theme.colors.textSecondary)
                            
                            if let user = authService.currentUser {
                                Text("Dr. \(user.firstName) \(user.lastName)")
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
                        // Today's Stats
                        VStack(alignment: .leading, spacing: theme.spacing.md) {
                            Text("Today's Overview")
                                .font(theme.typography.subtitle)
                                .foregroundStyle(theme.colors.textPrimary)
                                .padding(.horizontal, theme.spacing.lg)
                            
                            HStack(spacing: theme.spacing.md) {
                                StatCard(
                                    number: "8",
                                    label: "Appointments",
                                    icon: "calendar",
                                    theme: theme
                                )
                                
                                StatCard(
                                    number: "3",
                                    label: "Pending",
                                    icon: "clock",
                                    theme: theme
                                )
                                
                                StatCard(
                                    number: "12",
                                    label: "Messages",
                                    icon: "message",
                                    theme: theme
                                )
                            }
                            .padding(.horizontal, theme.spacing.lg)
                        }
                        
                        // Quick Actions
                        VStack(alignment: .leading, spacing: theme.spacing.md) {
                            Text("Quick Actions")
                                .font(theme.typography.subtitle)
                                .foregroundStyle(theme.colors.textPrimary)
                                .padding(.horizontal, theme.spacing.lg)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: theme.spacing.md) {
                                QuickActionCard(
                                    icon: "calendar.badge.clock",
                                    title: "Today's Schedule",
                                    subtitle: "View appointments",
                                    theme: theme
                                ) {
                                    // Navigate to schedule
                                }
                                
                                QuickActionCard(
                                    icon: "person.3",
                                    title: "My Patients",
                                    subtitle: "Manage patient list",
                                    theme: theme
                                ) {
                                    // Navigate to patients
                                }
                                
                                QuickActionCard(
                                    icon: "stethoscope",
                                    title: "Consultations",
                                    subtitle: "Start video call",
                                    theme: theme
                                ) {
                                    // Navigate to consultations
                                }
                                
                                QuickActionCard(
                                    icon: "doc.text.fill",
                                    title: "Prescriptions",
                                    subtitle: "Create prescription",
                                    theme: theme
                                ) {
                                    // Navigate to prescriptions
                                }
                            }
                            .padding(.horizontal, theme.spacing.lg)
                        }
                        
                        // Next Appointment
                        VStack(alignment: .leading, spacing: theme.spacing.md) {
                            Text("Next Appointment")
                                .font(theme.typography.subtitle)
                                .foregroundStyle(theme.colors.textPrimary)
                                .padding(.horizontal, theme.spacing.lg)
                            
                            // Placeholder for next appointment
                            HStack(spacing: theme.spacing.md) {
                                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                                    Text("10:30 AM")
                                        .font(theme.typography.subtitle)
                                        .foregroundStyle(theme.colors.textPrimary)
                                    
                                    Text("Video Consultation")
                                        .font(theme.typography.callout)
                                        .foregroundStyle(theme.colors.textSecondary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: theme.spacing.xs) {
                                    Text("John Smith")
                                        .font(theme.typography.callout)
                                        .foregroundStyle(theme.colors.textPrimary)
                                    
                                    Text("Age 45")
                                        .font(theme.typography.caption)
                                        .foregroundStyle(theme.colors.textSecondary)
                                }
                                
                                Button(action: {}) {
                                    Image(systemName: "video")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                        .frame(width: 48, height: 48)
                                        .background(theme.colors.primary)
                                        .cornerRadius(theme.cornerRadius)
                                }
                            }
                            .padding(theme.spacing.lg)
                            .background(theme.colors.surface)
                            .cornerRadius(theme.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: theme.cornerRadius)
                                    .stroke(theme.colors.border, lineWidth: 1)
                            )
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

struct StatCard: View {
    let number: String
    let label: String
    let icon: String
    let theme: AppThemeProtocol
    
    var body: some View {
        VStack(spacing: theme.spacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(theme.colors.primary)
            
            Text(number)
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.textPrimary)
            
            Text(label)
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.textSecondary)
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
}

#Preview {
    DoctorHomeView()
        .appTheme(AppTheme.default)
}
