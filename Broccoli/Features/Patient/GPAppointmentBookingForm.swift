//
//  GPAppointmentBookingForm.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 21/11/25.
//

import SwiftUI

struct GPAppointmentBookingForm: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var bookingViewModel: BookingGlobalViewModel
    @FocusState private var isTextEditorFocused: Bool
    
    // State variables
    @State private var selectedDate: Date? = Date()
    @State private var additionalDescription: String = ""
    @State private var currentMonth: Date = Date()
    
    // Computed property for selected time slot from view model
    private var selectedTimeSlot: String? {
        bookingViewModel.selectedTimeSlot
    }
    
    // Get all available slots combined
    private var allAvailableSlots: [TimeSlot] {
        bookingViewModel.morningSlots + bookingViewModel.afternoonSlots + bookingViewModel.eveningSlots
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { router.pop() }) {
                        Image("back-icon-white")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(theme.colors.primary)
                    }
                    
                    Spacer()
                    
                    Text("Select Date")
                        .font(theme.typography.medium24)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    // Invisible spacer for centering
                    Image("BackButton")
                        .font(.system(size: 16, weight: .semibold))
                        .opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(theme.colors.gradientStart)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Calendar Section
                        VStack(spacing: 16) {
                            // Month Navigation
                            VStack{
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
                            
                            // Calendar Grid
                            VStack(spacing: 12) {
                                // Weekday headers
                                HStack(spacing: 0) {
                                    ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                                        Text(day)
                                            .font(theme.typography.medium14)
                                            .foregroundStyle(.white)
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                                .padding(.horizontal, 20)
                                
                                // Calendar days
                                let days = generateCalendarDays(for: currentMonth)
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                                    ForEach(days, id: \.self) { date in
                                        if let date = date {
                                            DayCell(
                                                date: date,
                                                isSelected: selectedDate?.isSameDay(as: date) ?? false,
                                                isCurrentMonth: Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month)
                                            ) {
                                                selectedDate = date
                                                bookingViewModel.selectedTimeSlot = nil // Reset time slot when date changes
                                                bookingViewModel.selectedDate = date
                                                
                                                // Fetch time slots for the new date
                                                Task {
                                                    await bookingViewModel.fetchAvailableTimeSlots()
                                                }
                                            }
                                        } else {
                                            Color.clear
                                                .frame(height: 40)
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
                        
                        // Available Slots Section
                        if selectedDate != nil {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Available Slots")
                                    .font(theme.typography.semiBold18)
                                    .foregroundStyle(theme.colors.textPrimary)
                                    .padding(.horizontal, 20)
                                
                                if bookingViewModel.isLoading {
                                    // Loading state
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 100)
                                } else if allAvailableSlots.isEmpty {
                                    // No slots available
                                    Text("No available slots for this date")
                                        .font(theme.typography.regular14)
                                        .foregroundStyle(theme.colors.textSecondary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 100)
                                        .padding(.horizontal, 20)
                                } else {
                                    VStack(alignment: .leading, spacing: 20) {
                                        // Morning Slots
                                        if !bookingViewModel.morningSlots.isEmpty {
                                            VStack(alignment: .leading, spacing: 12) {
                                                Text("Morning")
                                                    .font(theme.typography.semiBold16)
                                                    .foregroundStyle(theme.colors.textPrimary)
                                                
                                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                                                    ForEach(bookingViewModel.morningSlots) { slot in
                                                        TimeSlotButton(
                                                            time: slot.displayTime,
                                                            price: formatPrice(slot.price),
                                                            isSelected: selectedTimeSlot == slot.time
                                                        ) {
                                                            bookingViewModel.selectedTimeSlot = slot.time
                                                            bookingViewModel.selectedTimeSlotPeriod = "morning"
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        
                                        // Afternoon Slots
                                        if !bookingViewModel.afternoonSlots.isEmpty {
                                            VStack(alignment: .leading, spacing: 12) {
                                                Text("Afternoon")
                                                    .font(theme.typography.semiBold16)
                                                    .foregroundStyle(theme.colors.textPrimary)
                                                
                                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                                                    ForEach(bookingViewModel.afternoonSlots) { slot in
                                                        TimeSlotButton(
                                                            time: slot.displayTime,
                                                            price: formatPrice(slot.price),
                                                            isSelected: selectedTimeSlot == slot.time
                                                        ) {
                                                            bookingViewModel.selectedTimeSlot = slot.time
                                                            bookingViewModel.selectedTimeSlotPeriod = "afternoon"
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        
                                        // Evening Slots
                                        if !bookingViewModel.eveningSlots.isEmpty {
                                            VStack(alignment: .leading, spacing: 12) {
                                                Text("Evening")
                                                    .font(theme.typography.semiBold16)
                                                    .foregroundStyle(theme.colors.textPrimary)
                                                
                                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                                                    ForEach(bookingViewModel.eveningSlots) { slot in
                                                        TimeSlotButton(
                                                            time: slot.displayTime,
                                                            price: formatPrice(slot.price),
                                                            isSelected: selectedTimeSlot == slot.time
                                                        ) {
                                                            bookingViewModel.selectedTimeSlot = slot.time
                                                            bookingViewModel.selectedTimeSlotPeriod = "evening"
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        
                        // Upload Document Section (visible after selecting date and time)
                        if selectedDate != nil && selectedTimeSlot != nil {
                            VStack(alignment: .leading, spacing: 16) {
                                Button(action: {
                                    // Handle document upload
                                    print("Upload document tapped")
                                }) {
                                    VStack(spacing: 12) {
                                        Image(systemName: "doc.fill")
                                            .font(.system(size: 32))
                                            .foregroundStyle(theme.colors.primary.opacity(0.6))
                                        
                                        Text("Upload Document")
                                            .font(theme.typography.regular14)
                                            .foregroundStyle(theme.colors.primary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 120)
                                    .background(Color(red: 0.95, green: 0.97, blue: 0.98))
                                    .cornerRadius(12)
                                }
                                .padding(.horizontal, 20)
                                
                                // Additional Descriptions
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Additional Descriptions")
                                        .font(theme.typography.semiBold16)
                                        .foregroundStyle(theme.colors.textPrimary)
                                    
                                    TextEditor(text: $additionalDescription)
                                        .font(theme.typography.regular14)
                                        .foregroundStyle(theme.colors.textPrimary)
                                        .frame(height: 120)
                                        .padding(12)
                                        .focused($isTextEditorFocused)
                                        .background(Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Bottom spacing
                        if selectedDate != nil && selectedTimeSlot != nil {
                            Color.clear.frame(height: 80)
                        } else {
                            Color.clear.frame(height: 20)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }
                }
                
                // Save & Next Button (visible after selecting date and time)
                if selectedDate != nil && selectedTimeSlot != nil {
                    Button(action: {
                        // Dismiss keyboard
                        hideKeyboard()
                        
                        // Save selected date, time slot and additional notes to view model
                        bookingViewModel.selectedDate = selectedDate
                        bookingViewModel.additionalNotes = additionalDescription
                        
                        // Navigate to booking confirmation to review before creating
                        router.push(.bookingConfirmation)
                    }) {
                        Text("Save & Next")
                            .font(theme.typography.button)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    }
                    .background(theme.colors.primary)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .background(Color.white)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Initialize view model with current date
            bookingViewModel.selectedDate = selectedDate
            
            // Set GP booking parameters
            bookingViewModel.isGP = "1"
            bookingViewModel.selectedDepartmentId = "1"
            
            // Fetch time slots for current date on load
            if selectedDate != nil {
                Task {
                    await bookingViewModel.fetchAvailableTimeSlots()
                }
            }
        }
        .alert("Error", isPresented: $bookingViewModel.showErrorToast) {
            Button("OK", role: .cancel) {
                bookingViewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = bookingViewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatPrice(_ price: String?) -> String {
        guard let price = price else { return "N/A" }
        let currency = bookingViewModel.pricingInfo?.currency ?? "USD"
        let symbol: String
        switch currency {
        case "EUR": symbol = "€"
        case "GBP": symbol = "£"
        case "USD": symbol = "$"
        default: symbol = currency
        }
        return "\(symbol)\(price)"
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
        
        // Get the first day of the month
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
              let monthRange = calendar.range(of: .day, in: .month, for: month) else {
            return days
        }
        
        // Get the weekday of the first day (0 = Sunday)
        let firstWeekday = calendar.component(.weekday, from: monthStart) - 1
        
        // Add nil for days before the month starts
        for _ in 0..<firstWeekday {
            days.append(nil)
        }
        
        // Add all days of the month
        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                days.append(date)
            }
        }
        
        // Add nil for remaining days to complete the grid
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
}

// MARK: - Date Extension
extension Date {
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }
}

// MARK: - Preview
#Preview {
    GPAppointmentBookingForm()
        .environment(\.appTheme, AppTheme.default)
}
