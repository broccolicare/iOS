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
    
    // State variables
    @State private var selectedDate: Date? = nil
    @State private var selectedTimeSlot: String? = nil
    @State private var additionalDescription: String = ""
    @State private var currentMonth: Date = Date()
    
    // Sample time slots - will be dynamic based on selected date
    private let timeSlots = [
        "9:00 AM", "10:00 AM", "11:00 AM",
        "12:00 PM", "01:00 PM", "02:00 PM",
        "03:00 PM", "04:00 PM", "05:00 PM",
        "06:00 PM", "07:00 PM", "08:00 PM"
    ]
    
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
                                                selectedTimeSlot = nil // Reset time slot when date changes
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
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Available Slots")
                                .font(theme.typography.semiBold18)
                                .foregroundStyle(theme.colors.textPrimary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                                ForEach(timeSlots, id: \.self) { slot in
                                    SpecialistTimeSlot(
                                        time: slot,
                                        isSelected: selectedTimeSlot == slot
                                    ) {
                                        selectedTimeSlot = slot
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        
                        // Additional Descriptions Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Additional Descriptions")
                                .font(theme.typography.semiBold18)
                                .foregroundStyle(theme.colors.textPrimary)
                            
                            TextEditor(text: $additionalDescription)
                                .font(theme.typography.regular14)
                                .foregroundStyle(theme.colors.textPrimary)
                                .frame(height: 120)
                                .padding(12)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(red: 0.9, green: 0.9, blue: 0.9), lineWidth: 1)
                                )
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        
                        // Bottom spacing for button
                        Color.clear.frame(height: 100)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }
                }
                
                // Save & Next Button
                Button(action: {
                    hideKeyboard()
                    // Handle save and next
                    print("Save & Next tapped")
                    // Navigate to next screen
                    router.push(.bookingConfirmation)
                }) {
                    Text("Save & Next")
                        .font(theme.typography.button)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            (selectedDate != nil && selectedTimeSlot != nil) 
                                ? theme.colors.primary 
                                : theme.colors.primary.opacity(0.5)
                        )
                        .cornerRadius(12)
                }
                .disabled(selectedDate == nil || selectedTimeSlot == nil)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .background(
                    Color.white
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5)
                )
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Helper Functions
    
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

// MARK: - Specialist Time Slot Component
struct SpecialistTimeSlot: View {
    @Environment(\.appTheme) private var theme
    let time: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(time)
                .font(theme.typography.medium14)
                .foregroundStyle(isSelected ? .white : theme.colors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(isSelected ? theme.colors.primary : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? theme.colors.primary : Color(red: 0.9, green: 0.9, blue: 0.9), lineWidth: 1)
                )
                .cornerRadius(8)
        }
    }
}

// MARK: - Preview
#Preview {
    SpecialistBookingFormView()
        .environment(\.appTheme, AppTheme.default)
}
