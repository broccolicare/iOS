//
//  ScheduledAppointmentCard.swift
//  Broccoli
//
//  Created by AI Assistant on 16/10/25.
//

import SwiftUI

struct ScheduledAppointmentCard: View {
    let appointment: DoctorAppointment
    let theme: AppThemeProtocol
    let onStartCall: () -> Void
    
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
                    
                    Text("\(appointment.startTime) - \(appointment.endTime)")
                        .font(theme.typography.regular14)
                        .foregroundStyle(theme.colors.primary)
                }
                
                Spacer()
            }
            
            // Start Call Button
            Button(action: onStartCall) {
                Text("Start call")
                    .font(theme.typography.medium16)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(theme.colors.primary)
                    .cornerRadius(8)
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
}

#Preview {
    ScheduledAppointmentCard(
        appointment: DoctorAppointment(
            id: 3,
            patientName: "Marc Maddison",
            patientAvatar: "patient-avatar-3",
            startTime: "12:00 PM",
            endTime: "12:30 PM",
            status: .scheduled
        ),
        theme: AppTheme.default,
        onStartCall: {}
    )
    .padding()
    .background(Color(red: 0.96, green: 0.97, blue: 0.98))
}
