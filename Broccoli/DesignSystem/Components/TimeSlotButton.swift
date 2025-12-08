//
//  TimeSlotButton.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 21/11/25.
//
import SwiftUI

struct TimeSlotButton: View {
    @Environment(\.appTheme) private var theme
    let time: String
    let price: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(time)
                    .font(theme.typography.medium14)
                    .foregroundStyle(isSelected ? .white : theme.colors.textPrimary)
                
                Text(price)
                    .font(theme.typography.regular12)
                    .foregroundStyle(isSelected ? .white : theme.colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(isSelected ? theme.colors.primary : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? theme.colors.primary : Color.gray.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(8)
        }
    }
}
