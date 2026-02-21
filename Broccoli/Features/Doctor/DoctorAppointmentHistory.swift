//
//  DoctorAppointmentHistory.swift
//  Broccoli
//
//  Created by AI Assistant on 14/02/26.
//

import SwiftUI

// MARK: - Appointment History Row

struct AppointmentHistoryRow: View {
    let booking: BookingData

    @Environment(\.appTheme) private var theme

    private var formattedTime: String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        guard let timeDate = timeFormatter.date(from: booking.time) else {
            return booking.time
        }
        timeFormatter.dateFormat = "hh:mm a"
        return timeFormatter.string(from: timeDate)
    }

    private var formattedAmount: String {
        guard let amount = booking.amount, !amount.isEmpty else { return "" }
        if amount.hasPrefix("€") || amount.hasPrefix("$") { return amount }
        // Strip trailing zeros: "49.00" → "€49"
        if let value = Double(amount) {
            let formatted = value.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(value))
                : String(format: "%.2f", value)
            return "€\(formatted)"
        }
        return "€\(amount)"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Profile placeholder
            Circle()
                .fill(theme.colors.surface)
                .frame(width: 52, height: 52)
                .overlay(
                    Image("doctor-square-placeholder")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipShape(Circle())
                )

            // Patient Info
            VStack(alignment: .leading, spacing: 4) {
                Text(booking.user?.name ?? "Patient")
                    .font(theme.typography.semiBold16)
                    .foregroundStyle(theme.colors.textPrimary)

                Text(formattedTime)
                    .font(theme.typography.regular14)
                    .foregroundStyle(theme.colors.textSecondary)

                if let serviceName = booking.service?.name {
                    Text(serviceName)
                        .font(theme.typography.regular12)
                        .foregroundStyle(theme.colors.textSecondary)
                }
            }

            Spacer()

            // Price
            if !formattedAmount.isEmpty {
                Text(formattedAmount)
                    .font(theme.typography.bold20)
                    .foregroundStyle(theme.colors.textPrimary)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Main View

struct DoctorAppointmentHistory: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var bookingViewModel: BookingGlobalViewModel

    // Bookings grouped by date, sorted newest first
    private var appointmentSections: [(date: String, formattedDate: String, appointments: [BookingData])] {
        let grouped = Dictionary(grouping: bookingViewModel.doctorBookingHistory) { $0.date }
        let sortedKeys = grouped.keys.sorted(by: >)

        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd MMM, yyyy"

        return sortedKeys.compactMap { key in
            guard let items = grouped[key], !items.isEmpty else { return nil }
            let label: String
            if let parsed = inputFormatter.date(from: key) {
                label = outputFormatter.string(from: parsed)
            } else {
                label = key
            }
            return (date: key, formattedDate: label, appointments: items)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 16) {
                Button(action: { router.pop() }) {
                    Image("BackButton")
                        .foregroundStyle(theme.colors.primary)
                }

                Text("Appointment History")
                    .font(theme.typography.bold20)
                    .foregroundStyle(theme.colors.textPrimary)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)

            // Content
            List {
                // Loading state (initial load only)
                if bookingViewModel.isLoadingDoctorHistory && bookingViewModel.doctorBookingHistory.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.white)

                // Empty state
                } else if bookingViewModel.doctorBookingHistory.isEmpty {
                    EmptyAppointmentsView(
                        title: "No Appointment History",
                        message: "You don't have any past appointments yet."
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.white)

                // Appointments grouped by date
                } else {
                    ForEach(appointmentSections, id: \.date) { section in
                        Section {
                            ForEach(section.appointments) { appointment in
                                AppointmentHistoryRow(booking: appointment)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        router.push(.appointmentDetailForDoctor(booking: appointment))
                                    }
                                    .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.white)
                            }
                        } header: {
                            Text(section.formattedDate)
                                .font(theme.typography.semiBold16)
                                .foregroundStyle(theme.colors.textPrimary)
                                .textCase(nil)
                                .padding(.top, 8)
                        }
                    }

                    // Pagination: load next page when this row appears
                    if bookingViewModel.doctorHistoryCurrentPage < bookingViewModel.doctorHistoryLastPage {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.white)
                        .onAppear {
                            Task {
                                await bookingViewModel.loadMoreDoctorBookingHistory()
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollIndicators(.hidden)
            .refreshable {
                await bookingViewModel.refreshDoctorBookingHistory()
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .task {
            if bookingViewModel.doctorBookingHistory.isEmpty {
                await bookingViewModel.fetchDoctorBookingHistory()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DoctorAppointmentHistory()
        .environment(\.appTheme, AppTheme.default)
        .environmentObject(Router.shared)
        .environmentObject(BookingGlobalViewModel(bookingService: BookingService(httpClient: HTTPClient())))
}
