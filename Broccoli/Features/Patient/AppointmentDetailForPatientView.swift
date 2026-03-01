//
//  AppointmentDetailForPatientView.swift
//  Broccoli
//
//  Created by AI Assistant on 06/02/26.
//

import SwiftUI

struct AppointmentDetailForPatientView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var bookingVM: BookingGlobalViewModel
    let booking: BookingData
    
    /// Returns the window's real top safe-area inset so the gradient height
    /// adapts across devices (e.g. iPhone 11 ≈ 44 pt, iPhone 16 ≈ 59 pt).
    private var topSafeAreaInset: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.safeAreaInsets.top ?? 44
    }
    
    private var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let appointmentDate = dateFormatter.date(from: booking.date) else {
            return booking.date
        }
        
        dateFormatter.dateFormat = "MMMM dd, yyyy"
        return dateFormatter.string(from: appointmentDate)
    }
    
    private var formattedTime: String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        guard let startTime = timeFormatter.date(from: booking.time) else {
            return booking.time
        }
        
        // Add 30 minutes for end time (assuming default duration)
        let endTime = Calendar.current.date(byAdding: .minute, value: 30, to: startTime) ?? startTime
        
        timeFormatter.dateFormat = "hh:mm a"
        let startTimeStr = timeFormatter.string(from: startTime)
        let endTimeStr = timeFormatter.string(from: endTime)
        
        return "\(startTimeStr) - \(endTimeStr)"
    }
    
    var body: some View {
        VStack(spacing: 0){
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
                // Base content height (116 pt) + real safe-area inset.
                // iPhone 11 (≈44 pt) → 160 pt  |  iPhone 16 (≈59 pt) → 175 pt
                .frame(height: 116 + topSafeAreaInset)
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
                        
                        VStack(alignment: .leading, spacing: 6){
                            // Doctor name or Department name
                            if let doctor = booking.assignedDoctor {
                                Text("Dr. \(doctor.name)")
                                    .font(theme.typography.bold30)
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            } else if let department = booking.department {
                                Text(department.name)
                                    .font(theme.typography.bold30)
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            } else {
                                Text("Doctor TBD")
                                    .font(theme.typography.bold30)
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            
                            // Service name
                            Text(booking.service?.name ?? "Consultation")
                                .font(theme.typography.bold18)
                                .foregroundStyle(theme.colors.profileDetailTextColor)
                                .padding(.top, 10)
                            
                            // Booking number
                            Text(booking.bookingNumber ?? "#\(booking.id)")
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
                VStack(alignment: .leading, spacing: 24) {
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
                            Text(formattedDate)
                                .font(theme.typography.regular16)
                                .foregroundStyle(theme.colors.profileDetailTextColor)
                        }
                        
                        // Time
                        HStack {
                            Text("Time")
                                .font(theme.typography.regular16)
                                .foregroundStyle(theme.colors.textPrimary)
                            Spacer()
                            Text(formattedTime)
                                .font(theme.typography.regular16)
                                .foregroundStyle(theme.colors.profileDetailTextColor)
                        }
                        
                        Divider()
                    }
                    .padding(.top, 12)
                    
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
                            }
                            
                            Spacer()
                        }
                        
                        // Treatment Type
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Treatment Type")
                                .font(theme.typography.regular12)
                                .foregroundStyle(theme.colors.textSecondary)
                            
                            Text(booking.service?.name ?? "General Consultation")
                                .font(theme.typography.bold18)
                                .foregroundStyle(theme.colors.textPrimary)
                        }
                        
                        // Consultation Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Consultation Notes")
                                .font(theme.typography.regular12)
                                .foregroundStyle(theme.colors.textSecondary)
                            
                            if let notes = booking.consultationNotes, !notes.isEmpty {
                                Text(notes)
                                    .font(theme.typography.regular14)
                                    .foregroundStyle(theme.colors.textPrimary)
                                    .lineSpacing(4)
                            } else {
                                Text("No notes added yet.")
                                    .font(theme.typography.regular14)
                                    .foregroundStyle(theme.colors.textSecondary)
                                    .italic()
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .frame(maxHeight: .infinity)
            
            // Bottom Action Buttons
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    // Status Card (full width)
                    HStack {
                        Text("Status")
                            .font(theme.typography.regular16)
                            .foregroundStyle(theme.colors.textPrimary)
                        Spacer()
                        Text(booking.status.capitalized)
                            .font(theme.typography.semiBold16)
                            .foregroundStyle(statusColor(for: booking.status))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(statusColor(for: booking.status).opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Call Button (only for confirmed bookings)
                    if booking.status == "confirmed" {
                        VideoCallButton(booking: booking, role: .patient)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 16)
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: -2)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            print("Booking Detail: -- \(booking)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "confirmed": return Color.green
        case "completed": return Color.blue
        case "cancelled": return Color.red
        case "pending": return Color.orange
        default: return Color.gray
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
        assignedDoctorId: 29,
        date: "2025-09-05",
        time: "10:00",
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
            id: 1,
            name: "Cardiac Health",
            code: "CARDIAC_CONSULT",
            description: "Comprehensive cardiovascular assessment including ECG analysis, blood pressure monitoring, and review of cardiac history. The doctor will evaluate current medications and discuss lifestyle modifications for optimal heart health.",
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
            specialization: nil
        ),
        department: DepartmentData(
            id: 1,
            name: "Cardiology",
            code: "CARDIO",
            description: nil,
            status: "active",
            createdAt: nil,
            updatedAt: nil
        ),
        user: nil,
        assignedDoctor: AssignedDoctorData(
            id: 29,
            name: "Emily Carter"
        )
    )
    
    NavigationStack {
        AppointmentDetailForPatientView(booking: sampleBooking)
            .environment(\.appTheme, AppTheme.default)
            .environmentObject(Router.shared)
    }
}

