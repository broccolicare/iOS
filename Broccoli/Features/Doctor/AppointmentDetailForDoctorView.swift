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
                        theme.colors.gradientStart,
                        theme.colors.gradientEnd
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 170)
                .frame(maxWidth: .infinity)
                .ignoresSafeArea(edges: .top)
                
                VStack(spacing: 0) {
                    // Back button
                    HStack {
                        Button(action: {
                            router.pop()
                        }) {
                            Image("back-icon-white")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(theme.colors.primary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    Spacer()
                        .frame(height: 24)
                    
                    // Patient info
                    HStack(alignment: .top, spacing: 10) {
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
                        
                        VStack(alignment: .leading, spacing: 6) {
                            // Patient name
                            Text(booking.user?.name ?? "Patient")
                                .font(theme.typography.bold30)
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            
                            // Service name
                            Text(booking.service?.name ?? "Consultation")
                                .font(theme.typography.bold18)
                                .foregroundStyle(theme.colors.profileDetailTextColor)
                                .padding(.top, 6)
                            
                            // Patient ID
                            Text("Patient ID: \(booking.userId ?? 0)")
                                .font(theme.typography.regular16)
                                .foregroundStyle(theme.colors.profileDetailTextColor)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            
            // Content Section
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Appointment Details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Appointment Details")
                            .font(theme.typography.bold20)
                            .foregroundStyle(theme.colors.textPrimary)
                        
                        // Date
                        HStack {
                            Text("Date")
                                .font(theme.typography.regular16)
                                .foregroundStyle(theme.colors.textPrimary)
                            Spacer()
                            Text(formatDate(booking.date))
                                .font(theme.typography.regular16)
                                .foregroundStyle(theme.colors.profileDetailTextColor)
                        }
                        
                        // Time
                        HStack {
                            Text("Time")
                                .font(theme.typography.regular16)
                                .foregroundStyle(theme.colors.textPrimary)
                            Spacer()
                            Text(formatTimeRange(booking.time, duration: booking.service?.duration ?? 30))
                                .font(theme.typography.regular16)
                                .foregroundStyle(theme.colors.profileDetailTextColor)
                        }
                        
                        Divider()
                    }
                    .padding(.top, 12)
                    
                    // Medication Summary
                    // VStack(alignment: .leading, spacing: 16) {
                    //     HStack(spacing: 12) {
                    //         // Icon
                    //         ZStack {
                    //             RoundedRectangle(cornerRadius: 12)
                    //                 .fill(theme.colors.profileDetailSectionBackground)
                    //                 .frame(width: 48, height: 48)
                                
                    //             Image(systemName: "pills.fill")
                    //                 .font(.system(size: 24))
                    //                 .foregroundStyle(theme.colors.primary)
                    //         }
                            
                    //         VStack(alignment: .leading, spacing: 2) {
                    //             Text("Medication Summary")
                    //                 .font(theme.typography.bold18)
                    //                 .foregroundStyle(theme.colors.textPrimary)
                                
                    //             Text("Prescribed medications")
                    //                 .font(theme.typography.regular14)
                    //                 .foregroundStyle(theme.colors.textSecondary)
                    //         }
                            
                    //         Spacer()
                    //     }
                        
                    //     // Medication A
                    //     VStack(alignment: .leading, spacing: 8) {
                    //         Text("Medication A")
                    //             .font(theme.typography.regular12)
                    //             .foregroundStyle(theme.colors.textSecondary)
                            
                    //         Text("100mg, twice daily")
                    //             .font(theme.typography.bold18)
                    //             .foregroundStyle(theme.colors.textPrimary)
                    //     }
                        
                    //     // Medication B
                    //     VStack(alignment: .leading, spacing: 8) {
                    //         Text("Medication B")
                    //             .font(theme.typography.regular12)
                    //             .foregroundStyle(theme.colors.textSecondary)
                            
                    //         Text("50mg, once daily")
                    //             .font(theme.typography.bold18)
                    //             .foregroundStyle(theme.colors.textPrimary)
                    //     }
                    // }
                    // .padding(.vertical, 16)
                    
                    // Treatment Details
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            // Icon
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(theme.colors.profileDetailSectionBackground)
                                    .frame(width: 48, height: 48)
                                
                                Image("treatement-icon")
                                    .font(.system(size: 24))
                                    .foregroundStyle(theme.colors.primary)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Treatment Details")
                                    .font(theme.typography.bold18)
                                    .foregroundStyle(theme.colors.textPrimary)
                                
                                Text("Clinical notes")
                                    .font(theme.typography.regular14)
                                    .foregroundStyle(theme.colors.textSecondary)
                            }
                            
                            Spacer()
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(theme.typography.regular12)
                                .foregroundStyle(theme.colors.textSecondary)
                            
                            Text("Patient requires a follow-up appointment to discuss treatment progress and adjust medication dosage.")
                                .font(theme.typography.regular14)
                                .foregroundStyle(theme.colors.textPrimary)
                                .lineSpacing(4)
                        }
                    }
                    .padding(.vertical, 16)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .frame(maxHeight: .infinity)
            
            // Bottom Action Buttons
            VStack {
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
                            .foregroundStyle(.white)
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
                            .foregroundStyle(theme.colors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(red: 0.9, green: 0.9, blue: 0.9), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: -2)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            print("Booking Detail: -- \(booking)")
        }
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
            let endTime = Calendar.current.date(byAdding: .minute, value: duration, to: startTime) ?? startTime
            
            formatter.dateFormat = "hh:mm a"
            let startString = formatter.string(from: startTime)
            let endString = formatter.string(from: endTime)
            
            return "\(startString) - \(endString)"
        }
        return time
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
        ),
        assignedDoctor: nil
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
