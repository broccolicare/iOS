//
//  AppointmentDetailForDoctorView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 27/12/25.
//

import SwiftUI

struct AppointmentDetailForDoctorView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var bookingVM: BookingGlobalViewModel
    
    let booking: BookingData
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with gradient background
            ZStack(alignment: .topLeading) {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.38, green: 0.73, blue: 0.42),
                        Color(red: 0.26, green: 0.65, blue: 0.58)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 220)
                
                VStack(spacing: 0) {
                    // Back button
                    HStack {
                        Button(action: {
                            router.pop()
                        }) {
                            Circle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "arrow.left")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.white)
                                )
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Patient info
                    VStack(spacing: 8) {
                        // Profile image
                        Circle()
                            .fill(Color.white)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image("patient-placeholder")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                            )
                        
                        // Patient name
                        Text(booking.user?.name ?? "Patient")
                            .font(theme.typography.semiBold24)
                            .foregroundColor(.white)
                        
                        // Patient ID
                        Text("Patient ID: \(booking.userId ?? 0)")
                            .font(theme.typography.regular14)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.top, 20)
                }
            }
            
            // Main content
            ScrollView {
                VStack(spacing: 24) {
                    // Appointment Details Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Appointment Details")
                            .font(theme.typography.semiBold18)
                            .foregroundStyle(theme.colors.textPrimary)
                        
                        VStack(spacing: 12) {
                            DetailRow(
                                label: "Date",
                                value: formatDate(booking.date)
                            )
                            
                            Divider()
                            
                            DetailRow(
                                label: "Time",
                                value: formatTimeRange(booking.time, duration: booking.service?.duration ?? 30)
                            )
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(12)
                    
                    // Medication Summary Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Medication Summary")
                            .font(theme.typography.semiBold18)
                            .foregroundStyle(theme.colors.textPrimary)
                        
                        VStack(spacing: 12) {
                            MedicationRow(
                                name: "Medication A",
                                dosage: "100mg, twice daily"
                            )
                            
                            Divider()
                            
                            MedicationRow(
                                name: "Medication B",
                                dosage: "50mg, once daily"
                            )
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(12)
                    
                    // Treatment Details Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Treatment Details")
                            .font(theme.typography.semiBold18)
                            .foregroundStyle(theme.colors.textPrimary)
                        
                        Text("Patient requires a follow-up appointment to discuss treatment progress and adjust medication dosage.")
                            .font(theme.typography.regular16)
                            .foregroundStyle(theme.colors.textSecondary)
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(12)
                }
                .padding(20)
            }
            .background(Color(red: 0.96, green: 0.97, blue: 0.98))
            
            // Bottom action buttons
            HStack(spacing: 12) {
                // Accept button
                Button(action: {
                    Task {
                        let success = await bookingVM.acceptBooking(bookingId: booking.id)
                        if success {
                            router.pop()
                        }
                    }
                }) {
                    Text("Accept")
                        .font(theme.typography.semiBold16)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(theme.colors.primary)
                        .cornerRadius(12)
                }
                
                // Reject button
                Button(action: {
                    Task {
                        let success = await bookingVM.rejectBooking(bookingId: booking.id, reason: "Rejected by doctor")
                        if success {
                            router.pop()
                        }
                    }
                }) {
                    Text("Reject")
                        .font(theme.typography.semiBold16)
                        .foregroundColor(theme.colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(theme.colors.border, lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.05), radius: 8, y: -2)
        }
        .navigationBarHidden(true)
        .edgesIgnoringSafeArea(.top)
    }
    
    // MARK: - Helper Functions
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "MMMM dd, yyyy"
            return formatter.string(from: date)
        }
        return dateString
    }
    
    private func formatTimeRange(_ time: String, duration: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        if let startTime = formatter.date(from: time) {
            let endTime = Calendar.current.date(byAdding: .minute, value: duration, to: startTime)
            
            formatter.dateFormat = "h:mm a"
            let startString = formatter.string(from: startTime)
            let endString = endTime != nil ? formatter.string(from: endTime!) : ""
            
            return "\(startString) - \(endString)"
        }
        return time
    }
}

// MARK: - Detail Row Component
struct DetailRow: View {
    @Environment(\.appTheme) private var theme
    
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(theme.typography.regular16)
                .foregroundStyle(theme.colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(theme.typography.semiBold16)
                .foregroundStyle(theme.colors.primary)
        }
    }
}

// MARK: - Medication Row Component
struct MedicationRow: View {
    @Environment(\.appTheme) private var theme
    
    let name: String
    let dosage: String
    
    var body: some View {
        HStack {
            Text(name)
                .font(theme.typography.regular16)
                .foregroundStyle(theme.colors.textSecondary)
            
            Spacer()
            
            Text(dosage)
                .font(theme.typography.semiBold16)
                .foregroundStyle(theme.colors.primary)
        }
    }
}

// MARK: - Preview
#Preview {
    let sampleBooking = BookingData(
        id: 1,
        userId: 123456,
        departmentId: 1,
        serviceId: 1,
        assignedDoctorId: nil,
        date: "2025-09-05",
        time: "10:00",
        timeSlot: "morning",
        amount: "50.00",
        status: "pending",
        paymentStatus: "paid",
        paymentMethod: "card",
        stripePaymentIntentId: nil,
        stripeCustomerId: nil,
        stripePaymentMethodId: nil,
        doctorStatus: "pending",
        doctorNotes: nil,
        doctorRespondedAt: nil,
        createdAt: nil,
        updatedAt: nil,
        service: ServiceData(
            id: 1,
            name: "General Consultation",
            code: "GP_CONSULT",
            description: nil,
            price: "50.00",
            duration: 30,
            departmentId: 1,
            specializationId: 1,
            parentId: nil,
            status: "active",
            billingType: "one_off",
            subscriptionRequired: 0,
            subscriptionQuotaMonthly: nil,
            quotaScopedTo: nil,
            requiresDoctor: 1,
            bookableOnline: 1,
            stripeProductId: nil,
            stripePriceId: nil,
            createdAt: nil,
            updatedAt: nil,
            specialization: Specialization(id: 1, name: "General Physician")
        ),
        department: nil,
        user: UserData(
            id: 123456,
            name: "Sophia Carter",
            email: "sophia@example.com",
            username: "sophia",
            stripeId: nil,
            pmType: nil,
            pmLastFour: nil,
            trialEndsAt: nil,
            twoFactorSecret: nil,
            twoFactorRecoveryCodes: nil,
            twoFactorConfirmedAt: nil,
            createdAt: nil,
            updatedAt: nil
        )
    )
    
    NavigationStack {
        AppointmentDetailForDoctorView(booking: sampleBooking)
            .environment(\.appTheme, AppTheme.default)
            .environmentObject({
                let httpClient = HTTPClient() as any HTTPClientProtocol
                let bookingService = BookingService(httpClient: httpClient)
                return BookingGlobalViewModel(bookingService: bookingService)
            }())
    }
}
