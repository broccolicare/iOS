//
//  TimeSlotRow.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 20/11/25.
//
import SwiftUI

struct TimeSlotRow: View {
    @Environment(\.appTheme) private var theme
    let time: String
    
    var body: some View {
        HStack(alignment:.top, spacing: 12) {
            // Calendar Icon
            Rectangle()
                .fill(theme.colors.background)
                .frame(width: 48, height: 48)
                .cornerRadius(8)
                .overlay(
                    Image(systemName: "calendar")
                        .font(.system(size: 18))
                        .foregroundStyle(theme.colors.textPrimary)
                )
            
            Text(time)
                .font(theme.typography.medium16)
                .foregroundStyle(theme.colors.profileDetailTextColor)
            
            Spacer()
        }
    }
}
