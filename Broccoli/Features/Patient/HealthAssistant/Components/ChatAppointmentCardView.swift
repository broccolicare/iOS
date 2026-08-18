//
//  ChatAppointmentCardView.swift
//  Broccoli
//
//  P4-05 / P4-06 — the `lookup_appointments` card.
//

import SwiftUI

/// The two lists behind My Appointments' tabs, summarised in the transcript:
/// upcoming first, then a short history.
///
/// Date and time **are** shown, and are safe to show: the server sends Laravel's
/// own `date` / `time` strings from `GET /bookings`, in the clinic's timezone,
/// and they are rendered as-is (the same formatting My Appointments uses). What
/// is never done is re-interpreting them as an instant in the device's zone —
/// Ireland observes DST, and that is how a patient gets told the wrong time.
///
/// Still deliberately a summary: no "Join call", no notes, no payment state.
/// Those belong to the appointment detail, which every row taps through to
/// (P4-06) — the detail screen refetches the booking, so what the patient acts
/// on is always the authoritative record rather than this transcript snapshot.
struct ChatAppointmentCardView: View {
    @Environment(\.appTheme) private var theme

    let payload: LookupAppointmentsPayload
    let onSelect: (ChatAppointment) -> Void

    private var isEmpty: Bool {
        payload.upcoming.isEmpty && payload.history.isEmpty
    }

    var body: some View {
        if isEmpty {
            emptyState
        } else {
            VStack(spacing: theme.spacing.md) {
                if !payload.upcoming.isEmpty {
                    section("Upcoming", payload.upcoming)
                }
                if !payload.history.isEmpty {
                    section("Past appointments", payload.history)
                }
            }
        }
    }

    /// No appointments at all is a normal answer, not a broken card — say so in a
    /// sentence rather than rendering an empty container.
    private var emptyState: some View {
        Text("You have no appointments yet.")
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

    private func section(_ title: String, _ appointments: [ChatAppointment]) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text(title.uppercased())
                .font(theme.typography.medium12)
                .foregroundStyle(theme.colors.textSecondary)
                .padding(.leading, 2)

            VStack(spacing: 1) {
                ForEach(appointments) { appointment in
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

                    if let schedule = appointment.formattedSchedule {
                        Text(schedule)
                            .font(theme.typography.regular12)
                            .foregroundStyle(theme.colors.textPrimary)
                    }

                    // Free text from Laravel — displayed, never switched on.
                    Text(appointment.subtitle)
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
        .accessibilityLabel(appointment.accessibilityLabel)
        .accessibilityHint("Opens the appointment")
        .accessibilityAddTraits(.isButton)
    }
}

extension ChatAppointment: Identifiable {}

extension ChatAppointment {
    /// `"20 Aug 26, 09:30 AM"` — the same shape `AppointmentListRow` uses, so a
    /// patient reads one format whether they came via chat or the tab.
    ///
    /// Both formatters are given the strings verbatim and no timezone
    /// conversion: this is presentation only. Anything unparseable falls back to
    /// the raw string rather than being dropped — a patient seeing
    /// `"2026-08-20"` is fine; a row with no date at all is not.
    var formattedSchedule: String? {
        guard let date, !date.isEmpty else { return time }

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let day = dateFormatter.date(from: date).map { parsed -> String in
            dateFormatter.dateFormat = "dd MMM yy"
            return dateFormatter.string(from: parsed)
        } ?? date

        guard let time, !time.isEmpty else { return day }
        return "\(day), \(Self.formattedTime(time))"
    }

    /// Accepts `HH:mm` and `HH:mm:ss` — which one Laravel sends is not ours to
    /// assume — and renders 12-hour. Unparseable input is passed through.
    private static func formattedTime(_ time: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for format in ["HH:mm:ss", "HH:mm"] {
            formatter.dateFormat = format
            if let parsed = formatter.date(from: time) {
                formatter.dateFormat = "hh:mm a"
                return formatter.string(from: parsed)
            }
        }
        return time
    }

    /// Status, plus the doctor once one is assigned.
    var subtitle: String {
        guard let doctor, !doctor.isEmpty else { return status.capitalized }
        return "\(status.capitalized) · \(doctor)"
    }

    var accessibilityLabel: String {
        [specialty, formattedSchedule, subtitle]
            .compactMap { $0 }
            .joined(separator: ", ")
    }
}

#Preview("With appointments") {
    ChatAppointmentCardView(
        payload: LookupAppointmentsPayload(
            upcoming: [
                ChatAppointment(
                    id: 1,
                    specialty: "Cardiology Consultation",
                    date: "2026-08-20",
                    time: "09:30",
                    status: "confirmed",
                    doctor: "Dr Ryan",
                    bookingNumber: "BK-1"
                )
            ],
            history: [
                ChatAppointment(
                    id: 2,
                    specialty: "GP Consultation",
                    date: "2026-07-15",
                    time: "14:00:00",
                    status: "completed",
                    doctor: nil,
                    bookingNumber: "BK-2"
                )
            ]
        )
    ) { _ in }
    .padding()
    .environment(\.appTheme, AppTheme.default)
}

#Preview("Empty") {
    ChatAppointmentCardView(
        payload: LookupAppointmentsPayload(upcoming: [], history: [])
    ) { _ in }
    .padding()
    .environment(\.appTheme, AppTheme.default)
}
