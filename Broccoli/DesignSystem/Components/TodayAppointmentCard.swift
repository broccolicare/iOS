//
//  TodayAppointmentCard.swift
//  Broccoli
//
//  Created by AI Assistant on 16/10/25.
//

import SwiftUI

struct TodayAppointmentCard: View {
    let appointment: DoctorAppointment
    let theme: AppThemeProtocol
    let onAccept: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Patient Info
            HStack(spacing: 12) {
                // Patient Avatar
                Circle()
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image("patient-placeholder")
                            .foregroundStyle(.gray)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(appointment.patientName)
                        .font(theme.typography.semiBold22)
                        .foregroundStyle(.black)
                    
                    Text(formatDate(appointment.date))
                        .font(theme.typography.regular14)
                        .foregroundStyle(theme.colors.textSecondary)
                    
                    Text("\(appointment.startTime) - \(appointment.endTime)")
                        .font(theme.typography.regular14)
                        .foregroundStyle(theme.colors.primary)
                }
                
                Spacer()
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                // Accept Button
                Button(action: onAccept) {
                    Text("Accept")
                        .font(theme.typography.medium16)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(theme.colors.primary)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                // Reject Button
                Button(action: onReject) {
                    Text("Reject")
                        .font(theme.typography.medium16)
                        .foregroundStyle(theme.colors.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(theme.colors.primary, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.colors.border, lineWidth: 1)
        )
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "MMMM dd, yyyy"
            return formatter.string(from: date)
        }
        return dateString
    }
}

#Preview {
    TodayAppointmentCard(
        appointment: DoctorAppointment(
            id: 1,
            patientName: "Sophia Carter",
            patientAvatar: "patient-avatar-1",
            date: "2026-02-14",
            startTime: "10:00 AM",
            endTime: "10:30 AM",
            status: .pending
        ),
        theme: AppTheme.default,
        onAccept: {},
        onReject: {}
    )
    .padding()
    .background(Color(red: 0.96, green: 0.97, blue: 0.98))
}
