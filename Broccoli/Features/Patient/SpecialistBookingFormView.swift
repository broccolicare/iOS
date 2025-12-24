//
//  SpecialistBookingFormView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 28/11/25.
//

import SwiftUI

struct SpecialistBookingFormView: View {
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
                // Header with gradient background
                HStack {
                    Button(action: { router.pop() }) {
                        Image("back-icon-white")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(theme.colors.primary)
                    }
                    
                    Spacer()
                    
                    Text("Select Date")
                        .font(theme.typography.semiBold20)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    // Invisible spacer for centering
                    Circle()
                        .fill(.clear)
                        .frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(theme.colors.gradientStart)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Calendar Section with gradient background
                        VStack(spacing: 16) {
                            // Month Navigation
                            VStack {
                                HStack {
                                    Button(action: { previousMonth() }) {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 16, weight: .semibold))
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
                                            .font(.system(size: 16, weight: .semibold))
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
                            VStack(spacing: 16) {
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
                                            SpecialistDayCell(
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
                                                .frame(height: 44)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                            }
                        }
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
                                                            isSelected: selectedTimeSlot == slot.time,
                                                            showPrice: false
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
                                                            isSelected: selectedTimeSlot == slot.time,
                                                            showPrice: false
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
                                                            isSelected: selectedTimeSlot == slot.time,
                                                            showPrice: false
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
                        
                        // Additional Descriptions Section (visible after selecting date and time)
                        if selectedDate != nil && selectedTimeSlot != nil {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Additional Descriptions")
                                    .font(theme.typography.semiBold18)
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
                                            .stroke(Color(red: 0.9, green: 0.9, blue: 0.9), lineWidth: 1)
                                    )
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
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
            
            // Set specialist booking parameters (isGP = 0 for specialists)
            bookingViewModel.isGP = "0"
            // Note: selectedDepartmentId should be set from the specialty selection
            //bookingViewModel.selectedDepartmentId = "2"
            
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
        // Use slot price if available, otherwise use service price if available
        let priceToUse: String?
        if let slotPrice = price {
            priceToUse = slotPrice
        } else if let selectedService = bookingViewModel.selectedService {
            priceToUse = selectedService.price
        } else {
            priceToUse = nil
        }
        
        guard let finalPrice = priceToUse else { return "N/A" }
        
        let currency = bookingViewModel.pricingInfo?.currency ?? "USD"
        let symbol: String
        switch currency {
        case "EUR": symbol = "€"
        case "GBP": symbol = "£"
        case "USD": symbol = "$"
        default: symbol = currency
        }
        return "\(symbol)\(finalPrice)"
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

// MARK: - Specialist Day Cell Component
struct SpecialistDayCell: View {
    @Environment(\.appTheme) private var theme
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(theme.typography.regular16)
                .foregroundStyle(isSelected ? theme.colors.primary : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isSelected ? .white : Color.clear)
                .cornerRadius(22)
                .opacity(isCurrentMonth ? 1.0 : 0.4)
        }
        .disabled(!isCurrentMonth)
    }
}


// MARK: - Preview
#Preview {
    SpecialistBookingFormView()
        .environment(\.appTheme, AppTheme.default)
}
