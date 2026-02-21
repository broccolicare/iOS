//
//  ScheduledAppointmentCard.swift
//  Broccoli
//
//  Created by AI Assistant on 16/10/25.
//

import SwiftUI

struct ScheduledAppointmentCard: View {
    let booking: BookingData
    let theme: AppThemeProtocol
    var onCardTap: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            // Patient Info — tapping here navigates to detail
            HStack(spacing: 12) {
                // Patient Avatar
                Circle()
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image("patient-placeholder")
                            .foregroundStyle(.gray)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.user?.name ?? "Patient")
                        .font(theme.typography.semiBold22)
                        .foregroundStyle(.black)
                    
                    Text(formattedDate)
                        .font(theme.typography.regular14)
                        .foregroundStyle(theme.colors.textSecondary)
                    
                    Text(formattedTimeRange)
                        .font(theme.typography.regular14)
                        .foregroundStyle(theme.colors.primary)
                }
                
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture { onCardTap?() }
            
            // Start Call Button — reusable component handles token fetch + navigation
            VideoCallButton(booking: booking, role: .doctor)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.colors.border, lineWidth: 1)
        )
    }
    
    // MARK: - Helpers
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: booking.date) {
            formatter.dateFormat = "MMMM dd, yyyy"
            return formatter.string(from: date)
        }
        return booking.date
    }
    
    private var formattedTimeRange: String {
        var fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        let startDate = fmt.date(from: booking.time) ?? {
            fmt.dateFormat = "HH:mm"
            return fmt.date(from: booking.time)
        }()
        guard let startTime = startDate else { return booking.time }
        let duration = booking.service?.duration ?? 30
        let endTime = Calendar.current.date(byAdding: .minute, value: duration, to: startTime) ?? startTime
        let display = DateFormatter()
        display.dateFormat = "h:mm a"
        return "\(display.string(from: startTime)) - \(display.string(from: endTime))"
    }
}

#Preview {
    let sampleBooking = BookingData(
        id: 60,
        userId: 30,
        departmentId: 1,
        serviceId: 1,
        assignedDoctorId: 29,
        date: "2026-02-20",
        time: "08:00",
        timeSlot: "morning",
        amount: "50.00",
        status: "confirmed",
        paymentStatus: "paid",
        paymentMethod: "stripe",
        stripePaymentIntentId: nil,
        stripeCustomerId: nil,
        stripePaymentMethodId: nil,
        doctorStatus: "accepted",
        doctorNotes: nil,
        doctorRespondedAt: nil,
        consultationNotes: nil,
        consultationCompletedAt: nil,
        agoraSessionId: "booking_60_1771512180",
        bookingNumber: "BRC-00000060",
        createdAt: nil,
        updatedAt: nil,
        service: nil,
        department: nil,
        user: UserData(
            id: 30, name: "Marc Maddison", email: "marc@example.com",
            username: nil, stripeId: nil, pmType: nil, pmLastFour: nil,
            trialEndsAt: nil, twoFactorSecret: nil, twoFactorRecoveryCodes: nil,
            twoFactorConfirmedAt: nil, createdAt: nil, updatedAt: nil
        ),
        assignedDoctor: nil
    )
    ScheduledAppointmentCard(booking: sampleBooking, theme: AppTheme.default)
        .padding()
        .background(Color(red: 0.96, green: 0.97, blue: 0.98))
        .environment(\.appTheme, AppTheme.default)
        .environmentObject(BookingGlobalViewModel(bookingService: BookingService(httpClient: HTTPClient())))
}
