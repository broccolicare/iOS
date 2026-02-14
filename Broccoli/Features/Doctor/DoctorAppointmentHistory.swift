//
//  DoctorAppointmentHistory.swift
//  Broccoli
//
//  Created by AI Assistant on 14/02/26.
//

import SwiftUI

// MARK: - Appointment History Row

struct AppointmentHistoryRow: View {
    let patientName: String
    let time: String
    let price: String
    let profileImage: String
    
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            Circle()
                .fill(theme.colors.surface)
                .frame(width: 52, height: 52)
                .overlay(
                    Image(profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipShape(Circle())
                )
            
            // Patient Info
            VStack(alignment: .leading, spacing: 4) {
                Text(patientName)
                    .font(theme.typography.semiBold16)
                    .foregroundStyle(theme.colors.textPrimary)
                
                Text(time)
                    .font(theme.typography.regular14)
                    .foregroundStyle(theme.colors.textSecondary)
            }
            
            Spacer()
            
            // Price
            Text(price)
                .font(theme.typography.bold20)
                .foregroundStyle(theme.colors.textPrimary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Main View

struct DoctorAppointmentHistory: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var router: Router
    
    // Sample data grouped by date
    private let appointmentsByDate: [(date: String, appointments: [(name: String, time: String, price: String, image: String)])] = [
        (
            date: "20 Sep, 2025",
            appointments: [
                (name: "Sophia Carter", time: "10:00 AM", price: "€49", image: "doctor-square-placeholder"),
                (name: "Olivia Bennett", time: "11:00 AM", price: "€49", image: "doctor-square-placeholder")
            ]
        ),
        (
            date: "18 Sep, 2025",
            appointments: [
                (name: "Noah Thompson", time: "9:00 AM", price: "€40", image: "doctor-square-placeholder"),
                (name: "Sophia Clark", time: "10:00 AM", price: "€40", image: "doctor-square-placeholder"),
                (name: "Liam Walker", time: "11:00 AM", price: "€40", image: "doctor-square-placeholder"),
                (name: "Ava Lewis", time: "12:00 PM", price: "€40", image: "doctor-square-placeholder")
            ]
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 16) {
                Button(action: { router.pop() }) {
                    Image("BackButton")
                        .foregroundStyle(theme.colors.primary)
                }
                
                Text("Appointment History")
                    .font(theme.typography.bold20)
                    .foregroundStyle(theme.colors.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
            
            // Appointments List
            List {
                ForEach(appointmentsByDate, id: \.date) { section in
                    Section {
                        ForEach(section.appointments, id: \.name) { appointment in
                            AppointmentHistoryRow(
                                patientName: appointment.name,
                                time: appointment.time,
                                price: appointment.price,
                                profileImage: appointment.image
                            )
                            .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.white)
                        }
                    } header: {
                        Text(section.date)
                            .font(theme.typography.semiBold16)
                            .foregroundStyle(theme.colors.textPrimary)
                            .textCase(nil)
                            .padding(.top, 8)
                    }
                }
            }
            .listStyle(.plain)
            .scrollIndicators(.hidden)
        }
        .background(Color.white)
        .navigationBarHidden(true)
    }
}

// MARK: - Preview

#Preview {
    DoctorAppointmentHistory()
        .environment(\.appTheme, AppTheme.default)
        .environmentObject(Router.shared)
}
