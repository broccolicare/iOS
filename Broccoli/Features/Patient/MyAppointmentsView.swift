//
//  MyAppointmentsView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 29/11/25.
//

import SwiftUI

struct MyAppointmentsView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: Router
    
    @State private var selectedTab: AppointmentTab = .upcoming
    
    // Sample data - will be replaced with actual data
    @State private var upcomingAppointments: [AppointmentItemData] = [
        AppointmentItemData(
            id: "1",
            specialty: "Oncologist",
            doctorName: "Dr. Emily Carter",
            dateTime: "Tomorrow, 10:00 AM",
            status: nil
        ),
        AppointmentItemData(
            id: "2",
            specialty: "Orthopedist",
            doctorName: "Dr. Michael Chen",
            dateTime: "Next Week, 2:00 PM",
            status: nil
        ),
        AppointmentItemData(
            id: "3",
            specialty: "ENT",
            doctorName: "Dr. Olivia Reed",
            dateTime: "In 2 Weeks, 11:30 AM",
            status: nil
        )
    ]
    
    @State private var historyAppointments: [AppointmentItemData] = [
        AppointmentItemData(
            id: "4",
            specialty: "Oncologist",
            doctorName: "Dr. Emily Carter",
            dateTime: "12 Jun 25, 10:00 AM",
            status: .completed
        ),
        AppointmentItemData(
            id: "5",
            specialty: "Orthopedist",
            doctorName: "Dr. Michael Chen",
            dateTime: "06 Feb 25, 02:00 PM",
            status: .completed
        ),
        AppointmentItemData(
            id: "6",
            specialty: "ENT",
            doctorName: "Dr. Olivia Reed",
            dateTime: "26 Dec 24, 04:30 PM",
            status: .cancelled
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
                    
                    Text("Appointments")
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
                
                // Tab Selector - Segmented Control Style
                SegmentedControl(
                    selectedTab: $selectedTab,
                    theme: theme
                )
                .padding(.horizontal, 20)
                
                // Content based on selected tab
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        if selectedTab == .upcoming {
                            ForEach(upcomingAppointments) { appointment in
                                AppointmentListRow(
                                    appointment: appointment,
                                    showStatus: false
                                ) {
                                    print("Tapped appointment: \(appointment.specialty)")
                                }
                            }
                        } else {
                            ForEach(historyAppointments) { appointment in
                                AppointmentListRow(
                                    appointment: appointment,
                                    showStatus: true
                                ) {
                                    print("Tapped appointment: \(appointment.specialty)")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Models
enum AppointmentTab {
    case upcoming
    case history
}

struct AppointmentItemData: Identifiable {
    let id: String
    let specialty: String
    let doctorName: String
    let dateTime: String
    let status: AppointmentStatus?
}

// MARK: - Segmented Control Component
struct SegmentedControl: View {
    @Binding var selectedTab: AppointmentTab
    let theme: AppThemeProtocol
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 0) {
            // Upcoming Tab
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = .upcoming
                }
            }) {
                Text("Upcoming")
                    .font(theme.typography.medium14)
                    .foregroundStyle(selectedTab == .upcoming ? .white : theme.colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        ZStack {
                            if selectedTab == .upcoming {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(theme.colors.primary)
                                    .matchedGeometryEffect(id: "TAB", in: animation)
                            }
                        }
                    )
            }
            .buttonStyle(PlainButtonStyle())
            
            // History Tab
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = .history
                }
            }) {
                Text("History")
                    .font(theme.typography.medium14)
                    .foregroundStyle(selectedTab == .history ? .white : theme.colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        ZStack {
                            if selectedTab == .history {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(theme.colors.primary)
                                    .matchedGeometryEffect(id: "TAB", in: animation)
                            }
                        }
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(4)
        .background(Color(red: 0.95, green: 0.97, blue: 0.98))
        .cornerRadius(10)
    }
}

// MARK: - Appointment List Row Component
struct AppointmentListRow: View {
    @Environment(\.appTheme) private var theme
    let appointment: AppointmentItemData
    let showStatus: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon container
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.93, green: 0.96, blue: 0.98))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "calendar")
                        .font(.system(size: 24))
                        .foregroundStyle(theme.colors.primary)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    HStack{
                        Text(appointment.specialty)
                            .font(theme.typography.semiBold18)
                            .foregroundStyle(theme.colors.textPrimary)
                        Spacer()
                        Text(appointment.dateTime)
                            .font(theme.typography.regular14)
                            .foregroundStyle(theme.colors.textSecondary)
                            .multilineTextAlignment(.trailing)
                        
                    }
                    HStack{
                        Text(appointment.doctorName)
                            .font(theme.typography.regular14)
                            .foregroundStyle(theme.colors.textPrimary)
                        Spacer()
                        
                        if showStatus, let status = appointment.status {
                            StatusBadge(status: status, theme: theme)
                        }
                    }
                }
            }
            .background(Color.white)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Status Badge Component
struct StatusBadge: View {
    let status: AppointmentStatus
    let theme: AppThemeProtocol
    
    var statusText: String {
        switch status {
        case .completed:
            return "Completed"
        case .cancelled:
            return "Cancelled"
        case .pending:
            return "Pending"
        case .scheduled:
            return "Upcoming"
        }
    }
    
    var statusColor: Color {
        switch status {
        case .completed:
            return Color(red: 0.8, green: 0.72, blue: 0.32) // Yellow/Gold
        case .cancelled:
            return theme.colors.error
        case .pending:
            return theme.colors.primary
        case .scheduled:
            return theme.colors.primary
        }
    }
    
    var body: some View {
        Text(statusText)
            .font(theme.typography.regular12)
            .foregroundStyle(statusColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(statusColor, lineWidth: 1)
            )
    }
}

// MARK: - Preview
#Preview {
    MyAppointmentsView()
        .environment(\.appTheme, AppTheme.default)
}
