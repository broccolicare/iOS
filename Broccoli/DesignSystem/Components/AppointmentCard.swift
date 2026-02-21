//
//  AppointmentCard.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 02/11/25.
//
import SwiftUI

struct AppointmentCard: View {
    @Environment(\..appTheme) private var theme
    let booking: BookingData
    
    var body: some View {
        VStack {
            
            HStack{
                Image("doctor-placeholder")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(booking.service?.name ?? booking.assignedDoctor.map { "Dr. \($0.name)" } ?? "Doctor")
                        .font(theme.typography.bold22)
                        .foregroundStyle(.white)
                    Text(booking.department?.name ?? "Specialist")
                        .font(theme.typography.regular14)
                        .foregroundStyle(.white)
                }
                Spacer()
                // Video call icon — uses VideoCallButton in iconOnly style
                VideoCallButton(booking: booking, role: .patient, style: .iconOnly)
                    .buttonStyle(PlainButtonStyle())
            }
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image("calendar-icon-white")
                    Text(formattedDate)
                        .font(theme.typography.regular16)
                }
                Spacer()
                HStack(spacing: 6) {
                    Image("watch-icon-white")
                    Text(formattedTime)
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
    
    // MARK: - Helpers
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: booking.date) {
            formatter.dateFormat = "MMM dd, yyyy"
            return formatter.string(from: date)
        }
        return booking.date
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let date = formatter.date(from: booking.time) ?? {
            formatter.dateFormat = "HH:mm"
            return formatter.date(from: booking.time)
        }()
        guard let t = date else { return booking.time }
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: t)
    }
}

#Preview {
    let sampleBooking = BookingData(
        id: 1,
        userId: 1,
        departmentId: 1,
        serviceId: 1,
        assignedDoctorId: 29,
        date: "2026-11-15",
        time: "10:30",
        timeSlot: "morning",
        amount: "50.00",
        status: "confirmed",
        paymentStatus: "paid",
        paymentMethod: "card",
        stripePaymentIntentId: nil,
        stripeCustomerId: nil,
        stripePaymentMethodId: nil,
        doctorStatus: "accepted",
        doctorNotes: nil,
        doctorRespondedAt: nil,
        consultationNotes: nil,
        consultationCompletedAt: nil,
        agoraSessionId: nil,
        bookingNumber: "BRC-00000001",
        createdAt: nil,
        updatedAt: nil,
        service: ServiceData(
            id: 1, name: "Cardiology", code: "CARDIO", description: nil,
            price: "50.00", duration: 30, departmentId: 1, specializationId: 1,
            parentId: nil, status: "active", billingType: "one_off",
            subscriptionRequired: 0, subscriptionQuotaMonthly: nil,
            quotaScopedTo: nil, requiresDoctor: 1, bookableOnline: 1,
            stripeProductId: nil, stripePriceId: nil,
            createdAt: nil, updatedAt: nil, specialization: nil
        ),
        department: DepartmentData(
            id: 1, name: "Cardiologist", code: "CARDIO",
            description: nil, status: "active", createdAt: nil, updatedAt: nil
        ),
        user: nil,
        assignedDoctor: AssignedDoctorData(id: 29, name: "Sarah Johnson")
    )
    AppointmentCard(booking: sampleBooking)
        .environment(\.appTheme, AppTheme.default)
        .environmentObject(BookingGlobalViewModel(bookingService: BookingService(httpClient: HTTPClient())))
        .padding()
}
