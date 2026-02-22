//
//  VideoCallButton.swift
//  Broccoli
//
//  Reusable video call button that handles:
//    1. Checking whether the call window is open
//    2. Generating an Agora token via the API
//    3. Navigating to the VideoCallView on success
//

import SwiftUI

struct VideoCallButton: View {

    // MARK: - Role

    enum Role {
        case doctor   // generates token + marks call started
        case patient  // generates token only
    }
    
    // MARK: - Style
    
    enum Style {
        case fullWidth  // default: full-width rectangle button
        case iconOnly   // compact circular icon button (e.g. AppointmentCard)
    }

    // MARK: - Input

    let booking: BookingData
    let role: Role
    var style: Style = .fullWidth

    // MARK: - Dependencies

    @EnvironmentObject private var bookingVM: BookingGlobalViewModel
    @Environment(\.appTheme) private var theme

    // MARK: - Local state

    @State private var isConnecting = false
    @State private var errorMessage: String? = nil
    @State private var showError = false

    // MARK: - Computed

    /// True when the booking has been marked completed by the server.
    private var isCompleted: Bool {
        booking.status.lowercased() == "completed"
    }

    private var withinCallWindow: Bool {
        guard !isCompleted else { return false }
        return Date.isCallWindowOpen(
            appointmentDate: booking.date,
            appointmentTime: booking.time
        )
    }

    private var isDisabled: Bool {
        !withinCallWindow || isConnecting
    }

    private var buttonBackground: Color {
        if isConnecting || !withinCallWindow {
            return theme.colors.textSecondary
        }
        return role == .doctor ? theme.colors.primary : Color.green
    }

    private var label: String {
        if isConnecting { return "Connecting..." }
        if isCompleted  { return "Consultation Completed" }
        if !withinCallWindow { return "Call available 5 min before" }
        return role == .doctor ? "Start Call" : "Join Call"
    }

    // MARK: - Body

    var body: some View {
        Button(action: handleTap) {
            switch style {
            case .fullWidth:
                fullWidthLabel
            case .iconOnly:
                iconOnlyLabel
            }
        }
        .disabled(isDisabled)
        .alert("Video Call Error", isPresented: $showError, presenting: errorMessage) { _ in
            Button("OK", role: .cancel) {}
        } message: { msg in
            Text(msg)
        }
    }
    
    // MARK: - Label Views
    
    @ViewBuilder
    private var fullWidthLabel: some View {
        HStack(spacing: 8) {
            if isConnecting {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.85)
            } else {
                Image(systemName: "video.fill")
            }
            Text(label)
        }
        .font(theme.typography.semiBold16)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(buttonBackground)
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var iconOnlyLabel: some View {
        ZStack {
            if isConnecting {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.75)
            } else {
                Image("video-icon-white")
                    .foregroundStyle(isDisabled ? .white.opacity(0.5) : .white)
            }
        }
        .padding(10)
        .background(isDisabled ? Color.gray.opacity(0.5) : buttonBackground)
        .clipShape(Circle())
    }

    // MARK: - Action

    private func handleTap() {
        guard withinCallWindow, !isConnecting else { return }

        isConnecting = true
        Task {
            if role == .doctor {
                await bookingVM.generateTokenAndStartCall(booking: booking)
            } else {
                await bookingVM.generateTokenAndJoinCall(booking: booking)
            }
            // If the ViewModel set an error, surface it locally
            if let vmError = bookingVM.errorMessage {
                errorMessage = vmError
                showError = true
            }
            isConnecting = false
        }
    }
}

// MARK: - Preview

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
        user: nil,
        assignedDoctor: nil
    )

    VStack(spacing: 16) {
        VideoCallButton(booking: sampleBooking, role: .doctor)
        VideoCallButton(booking: sampleBooking, role: .patient)
    }
    .padding()
    .environment(\.appTheme, AppTheme.default)
    .environmentObject(BookingGlobalViewModel(bookingService: BookingService(httpClient: HTTPClient())))
}
