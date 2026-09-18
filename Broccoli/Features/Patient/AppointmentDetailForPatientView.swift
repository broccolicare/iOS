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

    @State private var selectedAttachmentURL: URL? = nil
    @State private var selectedAttachmentName: String = ""

    @State private var showCancelSheet = false
    @State private var cancelReason: String = ""
    @State private var isCancelling = false
    @State private var showCancelResultAlert = false
    @State private var cancelSucceeded = false
    @State private var cancelResultMessage = ""

    /// Whether this appointment's intake has been started or finished. Read on
    /// appear rather than held live — nothing else on this screen changes it, and
    /// the intake screen writes it as the questionnaire progresses.
    @State private var intakeIsComplete = false
    @State private var intakeIsInProgress = false
    
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
                        // Doctor profile image
                        Circle()
                            .fill(Color.white)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Group {
                                    if let urlString = booking.assignedDoctor?.profileImage,
                                       let url = URL(string: urlString) {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image.resizable()
                                                    .scaledToFill()
                                                    .frame(width: 80, height: 80)
                                                    .clipShape(Circle())
                                            default:
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 30))
                                                    .foregroundStyle(.gray)
                                            }
                                        }
                                    } else {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 30))
                                            .foregroundStyle(.gray)
                                    }
                                }
                            )
                            .overlay(
                                Circle()
                                    .stroke(theme.colors.primary.opacity(0.3), lineWidth: 1)
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

                    // Uploaded Documents
                    if let attachments = booking.attachments, !attachments.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(theme.colors.profileDetailSectionBackground)
                                        .frame(width: 48, height: 48)
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 20))
                                        .foregroundStyle(theme.colors.primary)
                                }
                                Text("Uploaded Documents")
                                    .font(theme.typography.bold18)
                                    .foregroundStyle(theme.colors.textPrimary)
                                Spacer()
                            }

                            ForEach(attachments) { attachment in
                                Button(action: {
                                    if let url = URL(string: attachment.url) {
                                        selectedAttachmentName = attachment.fileName
                                        selectedAttachmentURL = url
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: attachmentIcon(for: attachment.mimeType))
                                            .font(.system(size: 20))
                                            .foregroundStyle(theme.colors.primary)
                                        Text(attachment.fileName)
                                            .font(theme.typography.regular14)
                                            .foregroundStyle(theme.colors.textPrimary)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                        Spacer()
                                        Image(systemName: "arrow.down.circle")
                                            .font(.system(size: 16))
                                            .foregroundStyle(theme.colors.textSecondary)
                                    }
                                    .padding(12)
                                    .background(Color(red: 0.96, green: 0.97, blue: 0.98))
                                    .cornerRadius(8)
                                }
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
                        if booking.isRescheduled {
                            Text("Rescheduled")
                                .font(theme.typography.semiBold16)
                                .foregroundStyle(Color.blue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                        Text(booking.status.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(theme.typography.semiBold16)
                            .foregroundStyle(statusColor(for: booking.status))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(statusColor(for: booking.status).opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Pre-appointment questionnaire, for confirmed appointments.
                    if showsIntakeButton {
                        intakeButton
                            .padding(.horizontal, 20)
                    }

                    // Call Button (only for confirmed bookings)
                    if booking.status == "confirmed" {
                        VideoCallButton(booking: booking, role: .patient)
                            .padding(.horizontal, 20)
                    }

                    // Reschedule / Cancel — only while more than 10 minutes remain
                    // before the appointment, and only for bookings still awaiting
                    // or confirmed for a future visit.
                    if canManageBooking {
                        if canReschedule {
                            Button(action: {
                                router.push(.rescheduleBooking(booking: booking))
                            }) {
                                Text("Reschedule Booking")
                                    .font(theme.typography.medium16)
                                    .foregroundStyle(theme.colors.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        Capsule().stroke(theme.colors.primary, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 20)
                        }

                        Button(action: {
                            cancelReason = ""
                            showCancelSheet = true
                        }) {
                            Text("Cancel Booking")
                                .font(theme.typography.medium16)
                                .foregroundStyle(Color.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    Capsule().fill(Color.red.opacity(0.1))
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 16)
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: -2)
            }
        }
        .sheet(item: $selectedAttachmentURL) { url in
            AttachmentViewer(url: url, fileName: selectedAttachmentName)
        }
        .sheet(isPresented: $showCancelSheet) {
            CancelBookingSheet(
                isRefundEligible: isEligibleForRefund,
                reason: $cancelReason,
                isSubmitting: isCancelling,
                onConfirm: { Task { await performCancel() } },
                onDismiss: { showCancelSheet = false }
            )
        }
        .alert(cancelSucceeded ? "Booking Cancelled" : "Cancellation Failed", isPresented: $showCancelResultAlert) {
            Button("OK", role: .cancel) {
                if cancelSucceeded {
                    router.popTo(.myAppointments)
                }
            }
        } message: {
            Text(cancelResultMessage)
        }
        .navigationBarHidden(true)
        .onAppear {
            print("Booking Detail: -- \(booking)")
            refreshIntakeState()
        }
    }

    // MARK: - Cancel / Reschedule eligibility

    /// Cancel/Reschedule are only offered while the booking is still awaiting or
    /// confirmed for a future visit, and more than 10 minutes remain before it.
    private var canManageBooking: Bool {
        guard !booking.isCancelled else { return false }
        guard booking.status == "pending" || booking.status == "confirmed" else { return false }
        return Date.hasLeadTime(minutes: 10, beforeAppointmentDate: booking.date, appointmentTime: booking.time)
    }

    /// A cancellation made more than 12 hours before the appointment is refunded;
    /// after that it still goes through, just without a refund.
    private var isEligibleForRefund: Bool {
        Date.hasLeadTime(minutes: 12 * 60, beforeAppointmentDate: booking.date, appointmentTime: booking.time)
    }

    /// A booking can only be rescheduled once — `rescheduleCount` is nil until the
    /// backend starts sending it, which is treated as "not yet rescheduled".
    private var canReschedule: Bool {
        canManageBooking && (booking.rescheduleCount ?? 0) == 0
    }

    private func performCancel() async {
        isCancelling = true
        let refund = isEligibleForRefund
        let trimmedReason = cancelReason.trimmingCharacters(in: .whitespacesAndNewlines)
        let success = await bookingVM.cancelBooking(bookingId: booking.id, reason: trimmedReason, refund: refund)
        isCancelling = false
        showCancelSheet = false
        cancelSucceeded = success
        cancelResultMessage = success
            ? (refund
                ? "Your booking has been cancelled and a refund will be processed."
                : "Your booking has been cancelled. As this was within 12 hours of the appointment, no refund applies.")
            : (bookingVM.errorMessage ?? "Failed to cancel booking. Please try again.")
        if success {
            await bookingVM.refreshAppointments()
        }
        showCancelResultAlert = true
    }
    
    // MARK: - Pre-appointment intake

    /// Offered on confirmed appointments.
    ///
    /// `pending` does not count: an unconfirmed booking may never happen, and an
    /// intake answered against one produces a clinical summary no clinician will
    /// ever read.
    private var showsIntakeButton: Bool {
        booking.status == "confirmed"
        // Past appointments are not filtered out for now — re-enable once the
        // server-supplied intake state lands:
        // guard booking.status == "confirmed" else { return false }
        // return !isPastAppointment
    }

    private var isPastAppointment: Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: booking.date) else {
            // An unparseable date is not a reason to hide the questionnaire — the
            // server owns the real ownership/eligibility check either way.
            return false
        }
        return date < Calendar.current.startOfDay(for: Date())
    }

    private var intakeButton: some View {
        Button {
            guard !intakeIsComplete else { return }
            router.push(.intake(
                appointmentId: booking.id,
                doctorName: booking.assignedDoctor?.name
            ))
        } label: {
            HStack(spacing: 8) {
                Image(systemName: intakeIsComplete ? "checkmark.circle.fill" : "list.clipboard")
                    .font(.system(size: 15, weight: .semibold))
                Text(intakeTitle)
                    .font(theme.typography.medium16)
            }
            .foregroundStyle(intakeIsComplete ? theme.colors.textSecondary : theme.colors.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Capsule().fill(
                    intakeIsComplete
                        ? theme.colors.primary.opacity(0.06)
                        : theme.colors.primary.opacity(0.12)
                )
            )
        }
        .buttonStyle(.plain)
        // Finished intakes are shown, not hidden — the patient should be able to
        // see it is done — but tapping does nothing: re-opening would start a
        // second questionnaire whose summary silently supersedes the first.
        .disabled(intakeIsComplete)
        .accessibilityLabel(intakeTitle)
    }

    private var intakeTitle: String {
        if intakeIsComplete { return "Pre-appointment questions completed" }
        if intakeIsInProgress { return "Continue pre-appointment questions" }
        return "Answer pre-appointment questions"
    }

    private func refreshIntakeState() {
        let store = IntakeSessionStore()
        intakeIsComplete = store.isCompleted(appointmentId: booking.id)
        intakeIsInProgress = store.conversationId(forAppointment: booking.id) != nil
    }

    // MARK: - Helper Methods
    
    private func attachmentIcon(for mimeType: String?) -> String {
        guard let mimeType else { return "doc.fill" }
        if mimeType.hasPrefix("image/") { return "photo" }
        if mimeType == "application/pdf" { return "doc.richtext" }
        return "doc.fill"
    }

    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "confirmed": return Color.green
        case "completed": return Color.blue
        case "cancelled": return Color.red
        case "pending": return Color.orange
        case "prescription_pending": return Color.orange
        default: return Color.gray
        }
    }

}

// MARK: - Cancel Booking Sheet

/// Confirmation sheet for cancelling a booking — collects a reason and makes the
/// refund outcome explicit before the patient commits, since it can't be undone.
private struct CancelBookingSheet: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isReasonFocused: Bool

    let isRefundEligible: Bool
    @Binding var reason: String
    let isSubmitting: Bool
    let onConfirm: () -> Void
    let onDismiss: () -> Void

    private var canConfirm: Bool {
        !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSubmitting
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Cancel Booking")
                .font(theme.typography.bold20)
                .foregroundStyle(theme.colors.textPrimary)

            Text(isRefundEligible
                 ? "You're cancelling more than 12 hours before your appointment, so you'll receive a full refund."
                 : "You're cancelling within 12 hours of your appointment, so no refund will be issued.")
                .font(theme.typography.regular14)
                .foregroundStyle(theme.colors.textSecondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Reason for Cancellation")
                    .font(theme.typography.semiBold16)
                    .foregroundStyle(theme.colors.textPrimary)

                TextEditor(text: $reason)
                    .font(theme.typography.regular14)
                    .foregroundStyle(theme.colors.textPrimary)
                    .frame(height: 100)
                    .padding(12)
                    .focused($isReasonFocused)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(12)
            }

            HStack(spacing: 12) {
                Button(action: {
                    onDismiss()
                    dismiss()
                }) {
                    Text("Keep Booking")
                        .font(theme.typography.medium16)
                        .foregroundStyle(theme.colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Capsule().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button(action: onConfirm) {
                    if isSubmitting {
                        ProgressView().tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    } else {
                        Text("Yes, Cancel")
                            .font(theme.typography.medium16)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                }
                .background(canConfirm ? Color.red : Color.red.opacity(0.4))
                .cornerRadius(50)
                .disabled(!canConfirm)
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .presentationDetents([.medium])
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
        patient: nil,
        assignedDoctor: AssignedDoctorData(
            id: 29,
            name: "Emily Carter",
            email: nil,
            profileImage: nil
        ),
        attachments: nil
    )
    
    NavigationStack {
        AppointmentDetailForPatientView(booking: sampleBooking)
            .environment(\.appTheme, AppTheme.default)
            .environmentObject(Router.shared)
    }
}

