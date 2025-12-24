//
//  BookingConfirmationView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 21/11/25.
//

import SwiftUI
@_spi(CustomerSessionBetaAccess) import StripePaymentSheet

struct BookingConfirmationView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var bookingViewModel: BookingGlobalViewModel
    @EnvironmentObject private var userVM: UserGlobalViewModel
    
    @State private var isShowingPaymentSheet = false
    
    // Computed properties from view models
    private var patientName: String {
        userVM.profileData?.name ?? "Guest User"
    }
    
    private var patientPhone: String {
        if let code = userVM.profileData?.profile?.phoneCode,
           let phone = userVM.profileData?.profile?.phone {
            return "\(code) \(phone)"
        }
        return "Not provided"
    }
    
    private var patientEmail: String {
        userVM.profileData?.email ?? "Not provided"
    }
    
    private var appointmentDate: String {
        guard let date = bookingViewModel.selectedDate else { return "Not selected" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter.string(from: date)
    }
    
    private var appointmentTime: String {
        guard let timeSlot = bookingViewModel.selectedTimeSlot else { return "Not selected" }
        // Find the selected slot to get display time
        let allSlots = bookingViewModel.morningSlots + bookingViewModel.afternoonSlots + bookingViewModel.eveningSlots
        if let slot = allSlots.first(where: { $0.time == timeSlot }) {
            return slot.displayTime
        }
        return timeSlot
    }
    
    private var selectedSlot: TimeSlot? {
        let allSlots = bookingViewModel.morningSlots + bookingViewModel.afternoonSlots + bookingViewModel.eveningSlots
        return allSlots.first(where: { $0.time == bookingViewModel.selectedTimeSlot })
    }
    
    private var serviceName: String {
        bookingViewModel.isGP == "1" ? "GP Consultation" : "Specialist Consultation"
    }
    
    private var serviceCharge: String {
        // First try to get price from selected slot
        if let slotPrice = selectedSlot?.price {
            return formatPrice(slotPrice)
        }
        // Fall back to selected service price if slot doesn't have price
        if let servicePrice = bookingViewModel.selectedService?.price {
            return formatPrice(servicePrice)
        }
        // If neither has a price, return N/A
        return "N/A"
    }
    
    private var totalPrice: String {
        return serviceCharge
    }
    
    private func formatPrice(_ price: String) -> String {
        return "€\(price)"
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { router.pop() }) {
                        Image("BackButton")
                    }
                    
                    Spacer()
                    
                    Text("Confirmation Detail")
                        .font(theme.typography.medium24)
                        .foregroundStyle(theme.colors.textPrimary)
                    
                    Spacer()
                    
                    // Invisible spacer for centering
                    Image("back-icon-white")
                        .opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white)
                
                ScrollView(showsIndicators: false) {
                    ZStack(alignment: .top) {
                        
                        VStack{
                            Spacer().frame(height: 280)
                            // Appointment Summary Card
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Appointment Summary")
                                    .font(theme.typography.semiBold18)
                                    .foregroundStyle(theme.colors.textPrimary)
                                
                                VStack(spacing: 12) {
                                    SummaryRow(label: "Doctor :", value: "Broccoli Doctors")
                                    SummaryRow(label: "Date :", value: appointmentDate)
                                    SummaryRow(label: "Time :", value: appointmentTime)
                                }
                            }
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                            
                            // Services Charge Card
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Services Charge")
                                    .font(theme.typography.semiBold18)
                                    .foregroundStyle(theme.colors.textPrimary)
                                
                                VStack(spacing: 12) {
                                    ChargeRow(label: serviceName, value: serviceCharge)
                                }
                            }
                            .padding(.vertical,20)
                            .padding(.horizontal, 20)
                            
                            // Final Price
                            HStack {
                                Text("Final Price")
                                    .font(theme.typography.semiBold22)
                                    .foregroundStyle(theme.colors.primary)
                                
                                Spacer()
                                
                                Text(totalPrice)
                                    .font(theme.typography.semiBold22)
                                    .foregroundStyle(theme.colors.primary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            
                            // Bottom spacing for button
                            Color.clear.frame(height: 10)
                        }
                        .background(theme.colors.otpInputBox)
                        .border(theme.colors.orderConfirmationBorderColor)
                        .cornerRadius(16)
                        
                        
                        // Clinic Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Broccoli Care")
                                        .font(theme.typography.bold20)
                                        .foregroundStyle(.white)
                                    
                                    Text("Block A2, apartment, Louisa Park\nApartment 12, Leixlip, Co. Kildare, W23\nP584, Ireland, W23 P584, Leixlip, Ireland")
                                        .font(theme.typography.regular14)
                                        .foregroundStyle(.white)
                                        .lineSpacing(4)
                                }
                                
                                Spacer()
                                
                                // Logo
                                Circle()
                                    .fill(.white)
                                    .frame(width: 56, height: 56)
                                    .overlay(
                                        Text("B")
                                            .font(theme.typography.bold30)
                                            .foregroundStyle(theme.colors.primary)
                                    )
                            }
                            
                            Divider()
                                .background(.white.opacity(0.3))
                                .padding(.vertical, 4)
                            
                            // Patient Info
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Patient info")
                                    .font(theme.typography.bold18)
                                    .foregroundStyle(.white)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(patientName)
                                        .font(theme.typography.regular16)
                                        .foregroundStyle(.white)
                                    
                                    Text(patientPhone)
                                        .font(theme.typography.regular16)
                                        .foregroundStyle(.white)
                                    
                                    Text(patientEmail)
                                        .font(theme.typography.regular16)
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            theme.colors.primary
                        )
                        .overlay(
                            // Zigzag bottom border
                            ZigzagShape()
                                .fill(theme.colors.otpInputBox)
                                .frame(height: 20)
                                .offset(y: 12),
                            alignment: .bottom
                        )
                    }
                    .cornerRadius(12)
                    
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
                
                // Confirm Booking & Pay Button
                Button(action: {
                    Task {
                        // Step 1: Initialize payment - check subscription and get payment intent
                        guard let initResponse = await bookingViewModel.initializePayment() else {
                            // Error already handled in view model
                            return
                        }
                        
                        // Step 2: Check if booking is covered by subscription
                        if initResponse.covered == true {
                            // User has subscription - show success message and navigate
                            bookingViewModel.showSuccessToast = true
                            bookingViewModel.errorMessage = initResponse.message ?? "This booking is covered by your subscription"
                            
                            // Small delay to show the message
                            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                            
                            router.push(.paymentSuccess(booking: bookingViewModel.confirmedBooking))
                        } else {
                            // Payment required - prepare and show payment sheet
                            bookingViewModel.preparePaymentSheet(with: initResponse)
                            
                            // Show payment sheet if preparation was successful
                            if bookingViewModel.isPaymentReady {
                                isShowingPaymentSheet = true
                            }
                        }
                    }
                }) {
                    if bookingViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    } else {
                        Text("Confirm Booking & Pay")
                            .font(theme.typography.button)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    }
                }
                .background(theme.colors.primary)
                .cornerRadius(12)
                .disabled(bookingViewModel.isLoading)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .background(Color.white)
            }
        }
        .navigationBarHidden(true)
        .paymentSheet(
            isPresented: $isShowingPaymentSheet,
            paymentSheet: bookingViewModel.paymentSheet ?? PaymentSheet(paymentIntentClientSecret: "", configuration: PaymentSheet.Configuration())
        ) { result in
            Task {
                // Get payment intent ID from stored value
                guard let paymentIntentId = bookingViewModel.currentPaymentIntentId else {
                    bookingViewModel.errorMessage = "Payment intent ID not found"
                    bookingViewModel.showErrorToast = true
                    return
                }
                
                // Confirm payment and create booking on backend
                let confirmResponse = await bookingViewModel.onPaymentCompletion(result: result, paymentIntentId: paymentIntentId)
                
                if confirmResponse != nil {
                    // Payment confirmed and booking created successfully
                    router.push(.paymentSuccess(booking: bookingViewModel.confirmedBooking))
                }
                
                // Reset payment sheet
                bookingViewModel.paymentSheet = nil
                bookingViewModel.isPaymentReady = false
                bookingViewModel.currentPaymentIntentId = nil
            }
        }
        .alert("Error", isPresented: $bookingViewModel.showErrorToast) {
            Button("OK", role: .cancel) {
                bookingViewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = bookingViewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

// MARK: - Summary Row Component
struct SummaryRow: View {
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
                .font(theme.typography.regular16)
                .foregroundStyle(theme.colors.textPrimary)
        }
    }
}

// MARK: - Charge Row Component
struct ChargeRow: View {
    @Environment(\.appTheme) private var theme
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(theme.typography.regular16)
                .foregroundStyle(theme.colors.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(theme.typography.extraBold16)
                .foregroundStyle(theme.colors.textPrimary)
        }
    }
}

// MARK: - Zigzag Shape for Card Border
struct ZigzagShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let zigzagWidth: CGFloat = 10
        let zigzagHeight: CGFloat = 8
        let numberOfZigzags = Int(rect.width / zigzagWidth)
        
        path.move(to: CGPoint(x: 0, y: 0))
        
        for i in 0..<numberOfZigzags {
            let x = CGFloat(i) * zigzagWidth
            path.addLine(to: CGPoint(x: x + zigzagWidth / 2, y: zigzagHeight))
            path.addLine(to: CGPoint(x: x + zigzagWidth, y: 0))
        }
        
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Preview
#Preview {
    BookingConfirmationView()
        .environment(\.appTheme, AppTheme.default)
}
