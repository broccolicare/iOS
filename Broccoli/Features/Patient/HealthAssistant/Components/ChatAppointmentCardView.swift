//
//  ChatAppointmentCardView.swift
//  Broccoli
//
//  P4-05 / P4-06 — the `lookup_appointments` card.
//

import SwiftUI

/// Deliberately minimal: **specialty and status only**.
///
/// 🛑 **Never render `scheduled_at`.** The AI payload's timestamp has no timezone
/// normalisation and nothing in it indicates its zone. Ireland observes DST, so
/// rendering it risks telling a patient the wrong appointment time — the worst
/// possible failure for this screen. The booking flow owns time; tapping through
/// shows the authoritative detail screen (P4-06). No doctor name and no "Join
/// call" either — both belong to the appointment detail, not to a chat summary
/// (plan §2.5, §3).
struct ChatAppointmentCardView: View {
    @Environment(\.appTheme) private var theme

    let payload: LookupAppointmentsPayload
    let onSelect: (ChatAppointment) -> Void

    var body: some View {
        if payload.appointments.isEmpty {
            emptyState
        } else {
            VStack(spacing: 1) {
                ForEach(payload.appointments) { appointment in
                    row(appointment)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(theme.colors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(theme.colors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    /// An empty list is a normal answer, not a broken card — say so in a sentence
    /// rather than rendering an empty container.
    private var emptyState: some View {
        Text("You have no upcoming appointments.")
            .font(theme.typography.regular12)
            .foregroundStyle(theme.colors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(theme.spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(theme.colors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(theme.colors.border, lineWidth: 1)
            )
    }

    private func row(_ appointment: ChatAppointment) -> some View {
        Button {
            onSelect(appointment)
        } label: {
            HStack(spacing: theme.spacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(appointment.specialty)
                        .font(theme.typography.medium14)
                        .foregroundStyle(theme.colors.textPrimary)
                        .multilineTextAlignment(.leading)

                    // Free text from Laravel — displayed, never switched on.
                    Text(appointment.status.capitalized)
                        .font(theme.typography.regular12)
                        .foregroundStyle(theme.colors.textSecondary)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(theme.colors.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding(theme.spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(appointment.specialty), \(appointment.status)")
        .accessibilityHint("Opens the appointment")
        .accessibilityAddTraits(.isButton)
    }
}

extension ChatAppointment: Identifiable {}

#Preview("With appointments") {
    ChatAppointmentCardView(
        payload: LookupAppointmentsPayload(appointments: [
            ChatAppointment(id: 1, specialty: "Cardiology", scheduledAt: "2026-08-01 09:30:00", status: "confirmed"),
            ChatAppointment(id: 2, specialty: "General Practice", scheduledAt: nil, status: "pending")
        ])
    ) { _ in }
    .padding()
    .environment(\.appTheme, AppTheme.default)
}

#Preview("Empty") {
    ChatAppointmentCardView(payload: LookupAppointmentsPayload(appointments: [])) { _ in }
        .padding()
        .environment(\.appTheme, AppTheme.default)
}
