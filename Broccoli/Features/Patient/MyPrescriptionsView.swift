//
//  MyPrescriptionsView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 11/02/26.
//

import SwiftUI

struct MyPrescriptionsView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var bookingViewModel: BookingGlobalViewModel
    
    @State private var selectedTab: PrescriptionTab = .active
    @Namespace private var animation
    
    enum PrescriptionTab {
        case active
        case history
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color.white.ignoresSafeArea()
            
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
                    
                    Text("Prescription")
                        .font(theme.typography.medium20)
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
                
                // Custom Tab Bar
                HStack(spacing: 0) {
                    // Active Prescriptions Tab
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = .active
                        }
                    }) {
                        Text("Active Prescriptions")
                            .font(theme.typography.medium14)
                            .foregroundStyle(selectedTab == .active ? .white : theme.colors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                ZStack {
                                    if selectedTab == .active {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(theme.colors.primary)
                                            .matchedGeometryEffect(id: "PRESCRIPTION_TAB", in: animation)
                                    }
                                }
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Prescriptions History Tab
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = .history
                        }
                    }) {
                        Text("Prescriptions History")
                            .font(theme.typography.medium14)
                            .foregroundStyle(selectedTab == .history ? .white : theme.colors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                ZStack {
                                    if selectedTab == .history {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(theme.colors.primary)
                                            .matchedGeometryEffect(id: "PRESCRIPTION_TAB", in: animation)
                                    }
                                }
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(4)
                .background(Color(red: 0.95, green: 0.97, blue: 0.98))
                .cornerRadius(10)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // Content based on selected tab
                if selectedTab == .active {
                    // Active Prescriptions List
                    let activePrescriptions = bookingViewModel.prescriptions.filter { prescription in
                        prescription.status.lowercased() == "pending" ||
                        prescription.status.lowercased() == "approved" ||
                        prescription.status.lowercased() == "assigned"
                    }
                    
                    // Loading state - only show when list is empty
                    if bookingViewModel.isLoadingPrescriptions && bookingViewModel.prescriptions.isEmpty {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading prescriptions...")
                                .font(theme.typography.regular14)
                                .foregroundStyle(theme.colors.textSecondary)
                                .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white)
                    }
                    // Empty state
                    else if activePrescriptions.isEmpty && !bookingViewModel.isLoadingPrescriptions {
                        EmptyPrescriptionsView(message: "No active prescriptions")
                    }
                    // Prescriptions list
                    else {
                        PrescriptionListAPIView(prescriptions: activePrescriptions)
                    }
                } else {
                    // Prescription History List
                    // Loading state - only show when list is empty
                    if bookingViewModel.isLoadingPrescriptionHistory && bookingViewModel.prescriptionHistory.isEmpty {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading prescription history...")
                                .font(theme.typography.regular14)
                                .foregroundStyle(theme.colors.textSecondary)
                                .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white)
                    }
                    // Empty state
                    else if bookingViewModel.prescriptionHistory.isEmpty && !bookingViewModel.isLoadingPrescriptionHistory {
                        EmptyPrescriptionsView(message: "No prescription history")
                    }
                    // Prescription history list
                    else {
                        PrescriptionHistoryListView(prescriptions: bookingViewModel.prescriptionHistory)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            // Fetch prescriptions when view appears
            if bookingViewModel.prescriptions.isEmpty {
                await bookingViewModel.fetchPrescriptions()
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            // Load prescription history when history tab is selected
            if newTab == .history && bookingViewModel.prescriptionHistory.isEmpty {
                Task {
                    await bookingViewModel.fetchPrescriptionHistory()
                }
            }
        }
        .refreshable {
            // Pull to refresh based on selected tab
            if selectedTab == .active {
                await bookingViewModel.refreshPrescriptions()
            } else {
                await bookingViewModel.refreshPrescriptionHistory()
            }
        }
    }
}

// MARK: - Prescription List View (API Data)
struct PrescriptionListAPIView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var bookingViewModel: BookingGlobalViewModel
    let prescriptions: [PrescriptionOrder]
    
    var body: some View {
        List {
            ForEach(prescriptions) { prescription in
                PrescriptionRowAPIView(prescription: prescription)
                    .listRowInsets(.init())
                    .listRowSeparator(.visible)
                    .listRowBackground(Color.clear)
            }
            
            // Load more indicator
            if bookingViewModel.prescriptionsHasMore && !bookingViewModel.isLoadingPrescriptions {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowInsets(.init())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .onAppear {
                    Task {
                        await bookingViewModel.loadMorePrescriptions()
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.white)
    }
}

// MARK: - Prescription History List View
struct PrescriptionHistoryListView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var bookingViewModel: BookingGlobalViewModel
    let prescriptions: [PrescriptionOrder]
    
    var body: some View {
        List {
            ForEach(prescriptions) { prescription in
                PrescriptionRowAPIView(prescription: prescription)
                    .listRowInsets(.init())
                    .listRowSeparator(.visible)
                    .listRowBackground(Color.clear)
            }
            
            // Load more indicator
            if bookingViewModel.prescriptionHistoryHasMore && !bookingViewModel.isLoadingPrescriptionHistory {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowInsets(.init())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .onAppear {
                    Task {
                        await bookingViewModel.loadMorePrescriptionHistory()
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.white)
    }
}

// MARK: - Prescription Row View (API Data)
struct PrescriptionRowAPIView: View {
    @Environment(\.appTheme) private var theme
    let prescription: PrescriptionOrder
    
    var body: some View {
        HStack(spacing: 16) {
            // Pill Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.colors.profileDetailSectionBackground)
                    .frame(width: 56, height: 56)
                
                Image("capsule-icon")
                    .font(.system(size: 24))
                    .foregroundStyle(theme.colors.primary)
            }
            
            // Prescription Details
            VStack(alignment: .leading, spacing: 4) {
                Text(prescription.treatment.name)
                    .font(theme.typography.semiBold18)
                    .foregroundStyle(theme.colors.textPrimary)
                
                Text("Submitted \(formatDate(prescription.createdAt))")
                    .font(theme.typography.regular14)
                    .foregroundStyle(theme.colors.profileDetailTextColor)
                
                if let pharmacy = prescription.pharmacy {
                    Label(pharmacy.name, systemImage: "mappin.circle")
                        .font(theme.typography.regular12)
                        .foregroundStyle(theme.colors.textSecondary)
                }
                
                PrescriptionStatusBadge(status: prescription.status, theme: theme)
                    .padding(.top, 2)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        if let date = inputFormatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "MM/dd/yyyy"
            return outputFormatter.string(from: date)
        }
        return dateString
    }
}

// MARK: - Prescription Status Badge
struct PrescriptionStatusBadge: View {
    let status: String
    let theme: AppThemeProtocol
    
    var displayText: String {
        switch status.lowercased() {
        case "pending":    return "Pending"
        case "approved":   return "Approved"
        case "assigned":   return "Assigned"
        case "sent":       return "Sent"
        case "completed":  return "Completed"
        case "rejected":   return "Rejected"
        case "cancelled":  return "Cancelled"
        default:           return status.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    
    var badgeColor: Color {
        switch status.lowercased() {
        case "pending":    return theme.colors.primary
        case "approved":   return Color(red: 0.18, green: 0.68, blue: 0.45)  // green
        case "assigned":   return Color(red: 0.00, green: 0.60, blue: 0.60)  // teal
        case "sent":       return Color(red: 0.90, green: 0.55, blue: 0.10)  // orange
        case "completed":  return Color(red: 0.80, green: 0.72, blue: 0.32)  // gold
        case "rejected",
             "cancelled":  return theme.colors.error
        default:           return theme.colors.textSecondary
        }
    }
    
    var body: some View {
        Text(displayText)
            .font(theme.typography.regular12)
            .foregroundStyle(badgeColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(badgeColor.opacity(0.10))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(badgeColor, lineWidth: 1)
            )
            .cornerRadius(4)
    }
}

// MARK: - Prescription List View (Sample Data - Kept for compatibility)
struct PrescriptionListView: View {
    @Environment(\.appTheme) private var theme
    let prescriptions: [PrescriptionHistoryItem]
    
    var body: some View {
        List {
            ForEach(prescriptions) { prescription in
                PrescriptionRowView(prescription: prescription)
                    .listRowSeparator(.visible)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.white)
    }
}

// MARK: - Prescription Row View
struct PrescriptionRowView: View {
    @Environment(\.appTheme) private var theme
    let prescription: PrescriptionHistoryItem
    
    var body: some View {
        HStack(spacing: 16) {
            // Pill Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.colors.profileDetailSectionBackground)
                    .frame(width: 56, height: 56)
                
                Image(systemName: "pill.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(theme.colors.primary)
            }
            
            // Prescription Details
            VStack(alignment: .leading, spacing: 4) {
                Text(prescription.name)
                    .font(theme.typography.semiBold18)
                    .foregroundStyle(theme.colors.textPrimary)
                
                Text("Filled on \(prescription.filledDate)")
                    .font(theme.typography.regular12)
                    .foregroundStyle(theme.colors.profileDetailTextColor)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white)
    }
}

// MARK: - Empty Prescriptions View
struct EmptyPrescriptionsView: View {
    @Environment(\.appTheme) private var theme
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "pills.circle")
                .font(.system(size: 64))
                .foregroundStyle(theme.colors.textSecondary.opacity(0.5))
            
            Text(message)
                .font(theme.typography.regular16)
                .foregroundStyle(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

// MARK: - Prescription History Item Model
struct PrescriptionHistoryItem: Identifiable {
    let id: Int
    let name: String
    let filledDate: String
    let status: PrescriptionStatus
    
    enum PrescriptionStatus {
        case active
        case completed
        case expired
    }
}

// MARK: - Preview
#Preview {
    MyPrescriptionsView()
        .environmentObject(Router.shared)
        .environmentObject(BookingGlobalViewModel(bookingService: BookingService(httpClient: HTTPClient())))
        .environment(\.appTheme, AppTheme.default)
}
