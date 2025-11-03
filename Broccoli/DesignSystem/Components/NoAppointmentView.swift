//
//  NoAppointmentView.swift
//  Broccoli
//
//  Created by AI Assistant on 16/10/25.
//

import SwiftUI

struct NoAppointmentView: View {
    @Environment(\.appTheme) private var theme
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 40))
                .foregroundStyle(theme.colors.textSecondary.opacity(0.5))
            
            Text(message)
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.colors.border.opacity(0.5), lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        NoAppointmentView(message: "No appointments for today")
        NoAppointmentView(message: "No scheduled appointments")
    }
    .padding()
    .background(Color(red: 0.96, green: 0.97, blue: 0.98))
    .environment(\.appTheme, AppTheme.default)
}
