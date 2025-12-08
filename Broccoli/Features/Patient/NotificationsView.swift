//
//  NotificationsView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 29/11/25.
//

import SwiftUI

struct NotificationsView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: Router
    
    // Sample data - will be replaced with actual data
    @State private var notifications: [NotificationItem] = [
        NotificationItem(
            id: "1",
            title: "Appointment with Dr. Emily Carter",
            time: "10:00 AM",
            icon: "calendar",
            isRead: false
        ),
        NotificationItem(
            id: "2",
            title: "Meeting with Sarah Bennett",
            time: "2:00 PM",
            icon: "calendar",
            isRead: false
        ),
        NotificationItem(
            id: "3",
            title: "Appointment with Dr. Michael Chen",
            time: "4:00 PM",
            icon: "calendar",
            isRead: false
        )
    ]
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { router.pop() }) {
                        Image("BackButton")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(theme.colors.primary)
                    }
                    
                    Spacer()
                    
                    Text("Notifications")
                        .font(theme.typography.medium22)
                        .foregroundStyle(theme.colors.textPrimary)
                    
                    Spacer()
                    
                    // Invisible spacer for centering
                    Circle()
                        .fill(.clear)
                        .frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white)
                
                // Notifications List
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(notifications) { notification in
                            NotificationRow(notification: notification) {
                                // Handle notification tap
                                print("Tapped notification: \(notification.title)")
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Notification Item Model
struct NotificationItem: Identifiable {
    let id: String
    let title: String
    let time: String
    let icon: String
    let isRead: Bool
}

// MARK: - Notification Row Component
struct NotificationRow: View {
    @Environment(\.appTheme) private var theme
    let notification: NotificationItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon container
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.93, green: 0.96, blue: 0.98))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: notification.icon)
                        .font(.system(size: 24))
                        .foregroundStyle(theme.colors.primary)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.title)
                        .font(theme.typography.medium16)
                        .foregroundStyle(theme.colors.textPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    Text(notification.time)
                        .font(theme.typography.regular14)
                        .foregroundStyle(theme.colors.textSecondary)
                }
                
                Spacer()
            }
            .background(Color.white)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    NotificationsView()
        .environment(\.appTheme, AppTheme.default)
}
