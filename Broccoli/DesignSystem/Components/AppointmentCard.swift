//
//  AppointmentCard.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 02/11/25.
//
import SwiftUI

struct AppointmentCard: View {
    @Environment(\.appTheme) private var theme
    let appointment: Appointment
    
    var body: some View {
        VStack {
            
            HStack{
                Image("doctor-placeholder")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(appointment.doctorName)
                        .font(theme.typography.bold22)
                        .foregroundStyle(.white)
                    Text(appointment.specialty)
                        .font(theme.typography.regular14)
                        .foregroundStyle(.white)
                }
                Spacer()
                // video call icon
                Button {
                    // start call
                } label: {
                    Image("video-icon-white")
                        .foregroundStyle(theme.colors.primary)
                        .padding(10)
                        .background(theme.colors.appointmentCardLightBlue)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image("calendar-icon-white")
                    Text(appointment.date)
                        .font(theme.typography.regular16)
                }
                Spacer()
                HStack(spacing: 6) {
                    Image("watch-icon-white")
                    Text(appointment.time)
                        .font(theme.typography.regular16)
                }
            }
            .foregroundStyle(.white)
            .padding(11)
            .background(theme.colors.appointmentCardLightBlue)
            .cornerRadius(8)
        }
        .padding()
        .background(theme.colors.appointmentCardBlue)
        .cornerRadius(14)
    }
}

#Preview {
    AppointmentCard(
        appointment: Appointment(
            doctorName: "Dr. Sarah Johnson",
            specialty: "Cardiologist",
            date: "Nov 15, 2025",
            time: "10:30 AM",
            avatar: "doctor-placeholder"
        )
    )
    .environment(\.appTheme, AppTheme.default)
    .padding()
}
