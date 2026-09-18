//
//  ChatAppointmentActionCardView.swift
//  Broccoli
//
//  The `open_appointment_action` card — a hand-off to the native
//  cancel/reschedule screens, never an execution in itself.
//

import SwiftUI

/// Shows the appointment the patient asked to cancel or reschedule, with a
/// single button that hands off to the existing native flow.
///
/// 🛑 **This never cancels or reschedules anything.** Tapping the button opens
/// `AppointmentDetailForPatientView` (cancel) or `RescheduleBookingView`
/// (reschedule) — the same screens `MyAppointmentsView` already opens — so the
/// existing lead-time cutoff, refund window and one-reschedule limit apply
/// unchanged. The card must never claim the action is complete.
struct ChatAppointmentActionCardView: View {
    @Environment(\.appTheme) private var theme

    let payload: OpenAppointmentActionPayload
    let onTap: () -> Void

    private var appointment: ChatAppointment { payload.appointment }

    private var ctaTitle: String {
        payload.action == .reschedule ? "Reschedule this appointment" : "Cancel this appointment"
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(appointment.specialty)
                        .font(theme.typography.medium14)
                        .foregroundStyle(theme.colors.textPrimary)
                        .multilineTextAlignment(.leading)

                    if let schedule = appointment.formattedSchedule {
                        Text(schedule)
                            .font(theme.typography.regular12)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                }

                HStack(spacing: theme.spacing.xs) {
                    Text(ctaTitle)
                        .font(theme.typography.medium14)
                        .foregroundStyle(theme.colors.primary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(theme.colors.primary)
                        .accessibilityHidden(true)
                }
            }
            .padding(theme.spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(theme.colors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(theme.colors.border, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel([appointment.specialty, appointment.formattedSchedule].compactMap { $0 }.joined(separator: ", "))
        .accessibilityHint(ctaTitle)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview("Cancel") {
    ChatAppointmentActionCardView(
        payload: OpenAppointmentActionPayload(
            action: .cancel,
            appointment: ChatAppointment(
                id: 1,
                specialty: "Cardiology Consultation",
                date: "2026-08-20",
                time: "09:30",
                status: "confirmed",
                doctor: "Dr Ryan",
                bookingNumber: "BK-1"
            )
        )
    ) {}
    .padding()
    .environment(\.appTheme, AppTheme.default)
}

#Preview("Reschedule") {
    ChatAppointmentActionCardView(
        payload: OpenAppointmentActionPayload(
            action: .reschedule,
            appointment: ChatAppointment(
                id: 1,
                specialty: "GP Consultation",
                date: "2026-08-20",
                time: "09:30",
                status: "confirmed",
                doctor: nil,
                bookingNumber: "BK-1"
            )
        )
    ) {}
    .padding()
    .environment(\.appTheme, AppTheme.default)
}
