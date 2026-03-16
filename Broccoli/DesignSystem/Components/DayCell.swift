//
//  DayCell.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 21/11/25.
//
import SwiftUI

struct DayCell: View {
    @Environment(\.appTheme) private var theme
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let action: () -> Void

    private var isPastDate: Bool {
        date < Calendar.current.startOfDay(for: Date())
    }
    
    var body: some View {
        Button(action: action) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(theme.typography.regular14)
                .foregroundStyle(isSelected ? theme.colors.primary : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(isSelected ? .white : Color.clear)
                .cornerRadius(20)
                .opacity(isCurrentMonth && !isPastDate ? 1.0 : 0.3)
        }
        .disabled(!isCurrentMonth || isPastDate)
    }
}
