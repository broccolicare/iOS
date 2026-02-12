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
    @EnvironmentObject private var bookingViewModel: BookingGlobalViewModel
    
    @State private var selectedTab: AppointmentTab = .upcoming
    @State private var isRefreshing: Bool = false
    
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
                List {
                    if selectedTab == .upcoming {
                        // Loading state
                        if bookingViewModel.isLoadingAppointments && bookingViewModel.upcomingAppointments.isEmpty {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                        // Empty state
                        else if bookingViewModel.upcomingAppointments.isEmpty && !bookingViewModel.isLoadingAppointments {
                            EmptyAppointmentsView(
                                title: "No Upcoming Appointments",
                                message: "You don't have any upcoming appointments scheduled."
                            )
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                        // Appointments list
                        else {
                            ForEach(bookingViewModel.upcomingAppointments) { appointment in
                                AppointmentListRow(
                                    booking: appointment,
                                    showStatus: false
                                )
                                .onTapGesture {
                                    router.push(.appointmentDetailForPatient(booking: appointment))
                                }
                                .listRowSeparator(.visible)
                                .listRowBackground(Color.clear)
                            }
                            
                            // Load more indicator
                            if bookingViewModel.currentPage < bookingViewModel.lastPage {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                    Spacer()
                                }
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .onAppear {
                                    Task {
                                        await bookingViewModel.loadMoreAppointments()
                                    }
                                }
                            }
                        }
                    } else {
                        // History tab
                        // Loading state
                        if bookingViewModel.isLoadingPastAppointments && bookingViewModel.pastAppointments.isEmpty {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                        // Empty state
                        else if bookingViewModel.pastAppointments.isEmpty && !bookingViewModel.isLoadingPastAppointments {
                            EmptyAppointmentsView(
                                title: "No Past Appointments",
                                message: "You don't have any past appointments yet."
                            )
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                        // Past appointments list
                        else {
                            ForEach(bookingViewModel.pastAppointments) { appointment in
                                AppointmentListRow(
                                    booking: appointment,
                                    showStatus: true
                                )
                                .onTapGesture {
                                    router.push(.appointmentDetailForPatient(booking: appointment))
                                }
                                .listRowSeparator(.visible)
                                .listRowBackground(Color.clear)
                            }
                            
                            // Load more indicator
                            if bookingViewModel.pastCurrentPage < bookingViewModel.pastLastPage {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                    Spacer()
                                }
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .onAppear {
                                    Task {
                                        await bookingViewModel.loadMorePastAppointments()
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .refreshable {
                    await handleRefresh()
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .task {
            // Load appointments when view appears
            if bookingViewModel.upcomingAppointments.isEmpty {
                await bookingViewModel.fetchUpcomingConfirmedAppointments()
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            // Load past appointments when history tab is selected
            if newTab == .history && bookingViewModel.pastAppointments.isEmpty {
                Task {
                    await bookingViewModel.fetchPastBookings()
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func handleRefresh() async {
        isRefreshing = true
        if selectedTab == .upcoming {
            await bookingViewModel.refreshAppointments()
        } else {
            await bookingViewModel.refreshPastAppointments()
        }
        isRefreshing = false
    }
}

// MARK: - Models
enum AppointmentTab {
    case upcoming
    case history
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
    let booking: BookingData
    let showStatus: Bool
    
    private var formattedDate: String {
        let date = booking.date
        let time = booking.time
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let appointmentDate = dateFormatter.date(from: date) else {
            return "\(date) \(time)"
        }
        
        // Output format
        dateFormatter.dateFormat = "dd MMM yy"
        let formattedDateStr = dateFormatter.string(from: appointmentDate)
        
        // Format time
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        guard let timeDate = timeFormatter.date(from: time) else {
            return "\(formattedDateStr), \(time)"
        }
        
        timeFormatter.dateFormat = "hh:mm a"
        let formattedTime = timeFormatter.string(from: timeDate)
        
        return "\(formattedDateStr), \(formattedTime)"
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon container
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.colors.profileDetailSectionBackground)
                    .frame(width: 56, height: 56)
                
                Image("calendar-icon-appointment")
                    .font(.system(size: 24))
                    .foregroundStyle(theme.colors.primary)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 2) {
                // Row 1: Service name
                Text(booking.service?.name ?? "Appointment")
                    .font(theme.typography.semiBold18)
                    .foregroundStyle(theme.colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Row 2: Doctor name and Status
                HStack {
                    if let doctor = booking.assignedDoctor {
                        Text("Dr. \(doctor.name)")
                            .font(theme.typography.regular14)
                            .foregroundStyle(theme.colors.profileDetailTextColor)
                    } else {
                        Text(booking.department?.name ?? "General")
                            .font(theme.typography.regular14)
                            .foregroundStyle(theme.colors.profileDetailTextColor)
                    }
                    
                    Spacer()
                    
                    if showStatus {
                        StatusBadge(status: booking.status, theme: theme)
                    }
                }
                
                // Row 3: Date and time
                Text(formattedDate)
                    .font(theme.typography.regular14)
                    .foregroundStyle(theme.colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color.white)
    }
}

// MARK: - Status Badge Component
struct StatusBadge: View {
    let status: String
    let theme: AppThemeProtocol
    
    var statusText: String {
        switch status.lowercased() {
        case "completed":
            return "Completed"
        case "cancelled":
            return "Cancelled"
        case "pending":
            return "Pending"
        case "scheduled":
            return "Upcoming"
        default:
            return status.capitalized
        }
    }
    
    var statusColor: Color {
        switch status.lowercased() {
        case "completed":
            return Color(red: 0.8, green: 0.72, blue: 0.32) // Yellow/Gold
        case "cancelled":
            return theme.colors.error
        case "pending":
            return theme.colors.primary
        case "scheduled":
            return theme.colors.primary
        default:
            return theme.colors.textSecondary
        }
    }
    
    var body: some View {
        Text(statusText)
            .font(theme.typography.regular12)
            .foregroundStyle(statusColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 2)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(statusColor, lineWidth: 1)
            )
    }
}

// MARK: - Empty State Component
struct EmptyAppointmentsView: View {
    @Environment(\.appTheme) private var theme
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundStyle(theme.colors.textSecondary.opacity(0.5))
                .padding(.top, 60)
            
            Text(title)
                .font(theme.typography.semiBold18)
                .foregroundStyle(theme.colors.textPrimary)
            
            Text(message)
                .font(theme.typography.regular14)
                .foregroundStyle(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Preview
#Preview {
    MyAppointmentsView()
        .environment(\.appTheme, AppTheme.default)
        .environmentObject(Router.shared)
        .environmentObject(BookingGlobalViewModel(bookingService: BookingService(httpClient: HTTPClient())))
}
