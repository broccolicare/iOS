//
//  PaymentSuccessView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 27/11/25.
//

import SwiftUI

struct PaymentSuccessView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var router: Router
    
    let booking: BookingData?
    
    // Format booking data for display
    private var appointmentDate: String {
        guard let dateString = booking?.date else { return "Sep 05, 2025" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "MMM dd, yyyy"
            return formatter.string(from: date)
        }
        return dateString
    }
    
    private var appointmentTime: String {
        guard let time = booking?.time else { return "04:00 PM" }
        // Convert 24-hour format to 12-hour with AM/PM
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        if let date = formatter.date(from: time) {
            formatter.dateFormat = "hh:mm a"
            return formatter.string(from: date)
        }
        return time
    }
    
    private var bookingId: String {
        guard let id = booking?.id else { return "BRO21535" }
        return "BRO\(id)"
    }
    
    private var serviceName: String {
        booking?.service?.name ?? "Consultation"
    }
    
    private var departmentName: String {
        booking?.department?.name ?? "General Medicine"
    }
    
    init(booking: BookingData?) {
        self.booking = booking
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Success Icon
                Image(systemName: "checkmark.seal.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(theme.colors.lightGreen)
                    .padding(.bottom, theme.spacing.lg)
                
                // Congratulations Text
                Text("Congratulations")
                    .font(theme.typography.bold34)
                    .foregroundStyle(theme.colors.textPrimary)
                    .padding(.bottom, 16)
                
                // Confirmation Message
                VStack(spacing: 8) {
                    Text("Your \(serviceName) appointment")
                        .font(theme.typography.medium18)
                        .foregroundStyle(theme.colors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("at \(departmentName)")
                        .font(theme.typography.regular16)
                        .foregroundStyle(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 4) {
                        Text("on")
                        Text(appointmentDate)
                            .fontWeight(.semibold)
                        Text("at")
                        Text(appointmentTime)
                            .fontWeight(.semibold)
                    }
                    .font(theme.typography.regular16)
                    .foregroundStyle(theme.colors.textPrimary)
                    .padding(.top, 4)
                    
                    Text("has been confirmed.")
                        .font(theme.typography.regular16)
                        .foregroundStyle(theme.colors.textPrimary)
                    
                    Text("Booking ID: \(bookingId)")
                        .font(theme.typography.medium16)
                        .foregroundStyle(theme.colors.primary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 12)
                }
                .padding(.horizontal, 32)
                Spacer().frame(height: 40)
                // Go Home Button
                Button(action: {
                    router.popToRoot()
                }) {
                    Text("Go Home")
                        .font(theme.typography.button)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(theme.colors.primary)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Star Badge Shape
struct StarBadgeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius * 0.85
        let numberOfPoints = 12
        
        for i in 0..<numberOfPoints {
            let angle = (CGFloat(i) * 2 * .pi / CGFloat(numberOfPoints)) - .pi / 2
            let pointRadius = i % 2 == 0 ? radius : innerRadius
            let x = center.x + pointRadius * cos(angle)
            let y = center.y + pointRadius * sin(angle)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview
#Preview {
    PaymentSuccessView(booking: nil)
        .environment(\.appTheme, AppTheme.default)
}
