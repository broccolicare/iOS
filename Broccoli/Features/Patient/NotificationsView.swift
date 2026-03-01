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
    @EnvironmentObject private var appVM: AppGlobalViewModel
    @EnvironmentObject private var bookingVM: BookingGlobalViewModel
    @EnvironmentObject private var authVM: AuthGlobalViewModel
    
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
                    
                    Button(action: {
                        Task { await appVM.markAllNotificationsAsRead() }
                    }) {
                        Image(systemName: "envelope.open")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(theme.colors.primary)
                    }
                    .disabled(appVM.notifications.allSatisfy { $0.isRead })
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white)
                
                if appVM.isLoadingNotifications {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if appVM.notifications.isEmpty {
                    Spacer()
                    Text("No notifications yet")
                        .font(theme.typography.regular16)
                        .foregroundColor(theme.colors.textSecondary)
                    Spacer()
                } else {
                    // Notifications List
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(appVM.notifications) { notification in
                                NotificationRow(
                                    notification: NotificationItem(
                                        id: "\(notification.id)",
                                        title: notification.title ?? "Notification",
                                        message: notification.message ?? "",
                                        time: formatNotificationDate(notification.createdAt),
                                        icon: iconName(for: notification.type),
                                        isRead: notification.isRead
                                    )
                                ) {
                                    handleNotificationTap(notification)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .task {
            await appVM.fetchNotifications()
        }
        .overlay {
            if bookingVM.isFetchingBookingDetail {
                ZStack {
                    Color.black.opacity(0.35).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.4)
                        Text("Loading appointment...")
                            .font(theme.typography.regular14)
                            .foregroundStyle(.white)
                    }
                }
            }
        }
    }

    private func handleNotificationTap(_ notification: AppNotification) {
        // Mark notification as read
        if !notification.isRead {
            Task { await appVM.markNotificationAsRead(notificationId: notification.id) }
        }

        guard let bookingId = notification.data?.bookingId else { return }

        let notificationType = notification.type?.lowercased() ?? ""

        // "new_booking" is a doctor-targeted notification
        if notificationType == "new_booking" {
            Task {
                await bookingVM.navigateToBookingFromNotification(
                    bookingId: bookingId,
                    userRole: .doctor
                )
            }
        } else if notificationType.contains("booking") || notificationType.contains("consultation") {
            // All other booking notifications — route based on logged-in user's role
            Task {
                await bookingVM.navigateToBookingFromNotification(
                    bookingId: bookingId,
                    userRole: authVM.currentUser?.primaryRole
                )
            }
        }
    }
    
    private func formatNotificationDate(_ isoString: String?) -> String {
        guard let isoString else { return "" }
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = parser.date(from: isoString) ?? ISO8601DateFormatter().date(from: isoString)
        guard let date else { return isoString }
        let formatter = DateFormatter()
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func iconName(for type: String?) -> String {
        switch type?.lowercased() {
        case let t where t?.contains("appointment") == true: return "calendar"
        case let t where t?.contains("message") == true,
             let t where t?.contains("chat") == true: return "message"
        case let t where t?.contains("payment") == true: return "creditcard"
        case let t where t?.contains("prescription") == true: return "pills"
        default: return "bell"
        }
    }
}

// MARK: - Notification Item Model
struct NotificationItem: Identifiable {
    let id: String
    let title: String
    let message: String
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
                        .fill(notification.isRead
                            ? Color(red: 0.93, green: 0.96, blue: 0.98)
                            : theme.colors.primary.opacity(0.12))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: notification.icon)
                        .font(.system(size: 24))
                        .foregroundStyle(theme.colors.primary)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.title)
                        .font(notification.isRead ? theme.typography.regular16 : theme.typography.medium16)
                        .foregroundStyle(theme.colors.textPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    if !notification.message.isEmpty {
                        Text(notification.message)
                            .font(theme.typography.regular14)
                            .foregroundStyle(theme.colors.textSecondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Text(notification.time)
                        .font(theme.typography.regular12)
                        .foregroundStyle(theme.colors.textSecondary.opacity(0.7))
                }
                
                Spacer()
                
                // Unread dot
                if !notification.isRead {
                    Circle()
                        .fill(theme.colors.primary)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(notification.isRead ? Color.white : theme.colors.primary.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        notification.isRead ? Color(red: 0.93, green: 0.93, blue: 0.93) : theme.colors.primary.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    NotificationsView()
        .environment(\.appTheme, AppTheme.default)
        .environmentObject(Router.shared)
        .environmentObject(AppGlobalViewModel(appService: AppService(httpClient: HTTPClient())))
        .environmentObject(BookingGlobalViewModel(bookingService: BookingService(httpClient: HTTPClient())))
        .environmentObject(AuthGlobalViewModel(authService: AuthService(httpClient: HTTPClient(), secureStore: SecureStore()), secureStore: SecureStore()))
}
