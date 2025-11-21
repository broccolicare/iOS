//
//  DatePickerField.swift
//  Broccoli
//
//  Created by AI Assistant on 19/11/25.
//

import SwiftUI

struct DatePickerField: View {
    @Environment(\.appTheme) private var theme
    
    @Binding var selectedDate: Date?
    var placeholder: String = "Select Date"
    var dateFormat: String = "yyyy-MM-dd"
    var minimumDate: Date? = nil
    var maximumDate: Date? = nil
    var displayedComponents: DatePickerComponents = [.date]
    
    @State private var showDatePicker: Bool = false
    @State private var tempDate: Date = Date()
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Button(action: {
                // Set temp date to current selected date or today
                tempDate = selectedDate ?? Date()
                showDatePicker = true
            }) {
                HStack {
                    Text(formattedDate)
                        .font(theme.typography.callout)
                        .foregroundStyle(selectedDate == nil ? theme.colors.textSecondary : theme.colors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "calendar")
                        .imageScale(.small)
                        .foregroundStyle(theme.colors.textSecondary)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.colors.border, lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(
                selectedDate: $tempDate,
                minimumDate: minimumDate,
                maximumDate: maximumDate,
                displayedComponents: displayedComponents,
                onDone: {
                    selectedDate = tempDate
                    showDatePicker = false
                },
                onCancel: {
                    showDatePicker = false
                }
            )
            .presentationDetents([.height(400)])
            .presentationDragIndicator(.visible)
        }
    }
    
    private var formattedDate: String {
        guard let date = selectedDate else {
            return placeholder
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        return formatter.string(from: date)
    }
}

// MARK: - Date Picker Sheet
struct DatePickerSheet: View {
    @Environment(\.appTheme) private var theme
    
    @Binding var selectedDate: Date
    var minimumDate: Date?
    var maximumDate: Date?
    var displayedComponents: DatePickerComponents
    var onDone: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Cancel and Done buttons
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .foregroundStyle(theme.colors.textSecondary)
                
                Spacer()
                
                Text("Select Date")
                    .font(theme.typography.subtitle)
                    .foregroundStyle(theme.colors.textPrimary)
                
                Spacer()
                
                Button("Done") {
                    onDone()
                }
                .foregroundStyle(theme.colors.primary)
                .fontWeight(.semibold)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(UIColor.systemGray6))
            
            // Date Picker
            DatePicker(
                "",
                selection: $selectedDate,
                in: dateRange,
                displayedComponents: displayedComponents
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .background(Color.white)
    }
    
    private var dateRange: ClosedRange<Date> {
        let min = minimumDate ?? Date.distantPast
        let max = maximumDate ?? Date.distantFuture
        return min...max
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        DatePickerField(
            selectedDate: .constant(nil),
            placeholder: "Date of Birth (YYYY-MM-DD)"
        )
        
        DatePickerField(
            selectedDate: .constant(Date()),
            placeholder: "Select Date",
            dateFormat: "MMM dd, yyyy"
        )
        
        DatePickerField(
            selectedDate: .constant(nil),
            placeholder: "Select Date & Time",
            displayedComponents: [.date, .hourAndMinute]
        )
    }
    .padding(20)
    .environment(\.appTheme, AppTheme.default)
}
