//
//  RescheduleBookingView.swift
//  Broccoli
//
//  Created by AI Assistant on 18/09/26.
//

import SwiftUI

/// Lets a patient move an existing booking to a new date/time. Reuses the same
/// calendar/time-slot building blocks as the booking-creation flow (`DayCell`,
/// `TimeSlotButton`) but keeps its own local slot state rather than touching
/// `BookingGlobalViewModel`'s shared `selectedDate`/`morningSlots` etc., since those
/// belong to the create-booking flow and this screen can be pushed while a booking
/// is already in progress elsewhere in the stack.
struct RescheduleBookingView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var bookingVM: BookingGlobalViewModel
    @FocusState private var isReasonFocused: Bool

    let booking: BookingData

    @State private var selectedDate: Date? = Date()
    @State private var currentMonth: Date = Date()
    @State private var selectedTime: String? = nil
    @State private var selectedPeriod: String? = nil
    @State private var reason: String = ""

    @State private var morningSlots: [TimeSlot] = []
    @State private var afternoonSlots: [TimeSlot] = []
    @State private var eveningSlots: [TimeSlot] = []
    @State private var isLoadingSlots = false
    @State private var slotsErrorMessage: String? = nil

    @State private var isSubmitting = false
    @State private var showResultAlert = false
    @State private var resultSucceeded = false
    @State private var resultMessage = ""

    private var allSlots: [TimeSlot] { morningSlots + afternoonSlots + eveningSlots }

    private var isGP: String { booking.departmentId == nil ? "1" : "0" }
    private var departmentIdString: String? { booking.departmentId.map { "\($0)" } }
    private var serviceIdString: String? { booking.serviceId.map { "\($0)" } }

    private var canSubmit: Bool {
        selectedDate != nil
            && selectedTime != nil
            && !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isSubmitting
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        calendarSection
                        slotsSection
                        if selectedTime != nil {
                            reasonSection
                        }
                        Color.clear.frame(height: selectedTime != nil ? 80 : 20)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { hideKeyboard() }
                }
            }

            if selectedTime != nil {
                VStack {
                    Spacer()
                    submitButton
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            if let date = selectedDate {
                await fetchSlots(for: date)
            }
        }
        .alert(resultSucceeded ? "Booking Rescheduled" : "Reschedule Failed", isPresented: $showResultAlert) {
            Button("OK", role: .cancel) {
                if resultSucceeded {
                    router.popTo(.myAppointments)
                }
            }
        } message: {
            Text(resultMessage)
        }
        .alert("Error", isPresented: Binding(
            get: { slotsErrorMessage != nil },
            set: { if !$0 { slotsErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { slotsErrorMessage = nil }
        } message: {
            Text(slotsErrorMessage ?? "")
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack {
            Button(action: { router.pop() }) {
                Image("back-icon-white")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.colors.primary)
            }
            Spacer()
            Text("Reschedule Booking")
                .font(theme.typography.medium24)
                .foregroundStyle(.white)
            Spacer()
            Image("BackButton")
                .font(.system(size: 16, weight: .semibold))
                .opacity(0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(theme.colors.gradientStart)
    }

    private var calendarSection: some View {
        VStack(spacing: 16) {
            VStack {
                HStack {
                    Button(action: { previousMonth() }) {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                    }
                    Spacer()
                    Text(monthYearString(from: currentMonth))
                        .font(theme.typography.semiBold18)
                        .foregroundStyle(.white)
                    Spacer()
                    Button(action: { nextMonth() }) {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                    }
                }
                .padding(.vertical, 4)
                .background(theme.colors.monthSwitcherBackgroundColor)
                .cornerRadius(4)
            }
            .padding(.horizontal, 20)

            VStack(spacing: 12) {
                HStack(spacing: 0) {
                    ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { _, day in
                        Text(day)
                            .font(theme.typography.medium14)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)

                let days = generateCalendarDays(for: currentMonth)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                    ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                        if let date = date {
                            DayCell(
                                date: date,
                                isSelected: selectedDate?.isSameDay(as: date) ?? false,
                                isCurrentMonth: Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month)
                            ) {
                                selectedDate = date
                                selectedTime = nil
                                selectedPeriod = nil
                                Task { await fetchSlots(for: date) }
                            }
                        } else {
                            Color.clear.frame(height: 40)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 20)
        .background(
            LinearGradient(
                colors: [theme.colors.gradientStart, theme.colors.gradientEnd],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    @ViewBuilder
    private var slotsSection: some View {
        if selectedDate != nil {
            VStack(alignment: .leading, spacing: 16) {
                Text("Available Slots")
                    .font(theme.typography.semiBold18)
                    .foregroundStyle(theme.colors.textPrimary)
                    .padding(.horizontal, 20)

                if isLoadingSlots {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                } else if allSlots.isEmpty {
                    Text("No available slots for this date")
                        .font(theme.typography.regular14)
                        .foregroundStyle(theme.colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .padding(.horizontal, 20)
                } else {
                    VStack(alignment: .leading, spacing: 20) {
                        slotGroup(title: "Morning", slots: morningSlots, period: "morning")
                        slotGroup(title: "Afternoon", slots: afternoonSlots, period: "afternoon")
                        slotGroup(title: "Evening", slots: eveningSlots, period: "evening")
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    @ViewBuilder
    private func slotGroup(title: String, slots: [TimeSlot], period: String) -> some View {
        if !slots.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(theme.typography.semiBold16)
                    .foregroundStyle(theme.colors.textPrimary)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(slots) { slot in
                        TimeSlotButton(
                            time: slot.displayTime,
                            price: "",
                            isSelected: selectedTime == slot.time,
                            showPrice: false
                        ) {
                            selectedTime = slot.time
                            selectedPeriod = period
                        }
                    }
                }
            }
        }
    }

    private var reasonSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reason for Rescheduling")
                .font(theme.typography.semiBold16)
                .foregroundStyle(theme.colors.textPrimary)

            TextEditor(text: $reason)
                .font(theme.typography.regular14)
                .foregroundStyle(theme.colors.textPrimary)
                .frame(height: 100)
                .padding(12)
                .focused($isReasonFocused)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(12)
        }
        .padding(.horizontal, 20)
    }

    private var submitButton: some View {
        Button(action: {
            hideKeyboard()
            Task { await submit() }
        }) {
            if isSubmitting {
                ProgressView().tint(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
            } else {
                Text("Confirm Reschedule")
                    .font(theme.typography.button)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
            }
        }
        .background(canSubmit ? theme.colors.primary : theme.colors.primary.opacity(0.4))
        .cornerRadius(12)
        .disabled(!canSubmit)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(Color.white)
    }

    // MARK: - Actions

    private func fetchSlots(for date: Date) async {
        isLoadingSlots = true
        slotsErrorMessage = nil
        do {
            let response = try await bookingVM.bookingService.fetchAvailableTimeSlots(
                date: date,
                isGP: isGP,
                departmentId: departmentIdString,
                serviceId: serviceIdString
            )
            if response.success {
                morningSlots = response.slots?.morning ?? []
                afternoonSlots = response.slots?.afternoon ?? []
                eveningSlots = response.slots?.evening ?? []
            } else {
                morningSlots = []
                afternoonSlots = []
                eveningSlots = []
                slotsErrorMessage = response.message ?? "Failed to fetch available time slots"
            }
        } catch {
            morningSlots = []
            afternoonSlots = []
            eveningSlots = []
            slotsErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoadingSlots = false
    }

    private func submit() async {
        guard let date = selectedDate, let time = selectedTime, let period = selectedPeriod else { return }
        isSubmitting = true
        let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        let success = await bookingVM.rescheduleBooking(bookingId: booking.id, date: date, timeSlot: period, time: time, reason: trimmedReason)
        isSubmitting = false
        resultSucceeded = success
        resultMessage = success
            ? "Your appointment has been rescheduled successfully."
            : (bookingVM.errorMessage ?? "Failed to reschedule booking. Please try again.")
        if success {
            await bookingVM.refreshAppointments()
        }
        showResultAlert = true
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func previousMonth() {
        if let newMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    private func nextMonth() {
        if let newMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func generateCalendarDays(for month: Date) -> [Date?] {
        var days: [Date?] = []
        let calendar = Calendar.current

        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
              let monthRange = calendar.range(of: .day, in: .month, for: month) else {
            return days
        }

        let firstWeekday = calendar.component(.weekday, from: monthStart) - 1
        for _ in 0..<firstWeekday {
            days.append(nil)
        }
        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                days.append(date)
            }
        }
        while days.count % 7 != 0 {
            days.append(nil)
        }
        return days
    }
}
