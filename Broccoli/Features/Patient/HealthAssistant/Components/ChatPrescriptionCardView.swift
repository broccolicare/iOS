//
//  ChatPrescriptionCardView.swift
//  Broccoli
//
//  The `lookup_prescriptions` card — the prescriptions twin of
//  `ChatAppointmentCardView`.
//

import SwiftUI

/// One of the two lists behind My Prescriptions' tabs, summarised in the
/// transcript: the orders still in flight, or — only when the patient asked for
/// them — the past ones. The server sends whichever it was asked for and says so
/// in `scope`; the card never shows a history nobody asked about.
///
/// Dates are rendered from the server's own strings without any timezone
/// conversion — same rule as the appointment card, and for the same reason.
///
/// Deliberately a summary, and deliberately **status only**: no treatment
/// description, no dosage, no questionnaire answers. The assistant may tell a
/// patient where their order has got to; what a treatment does and how to take it
/// is a clinician's or the pharmacy's answer, and the card must not become a
/// back door to it.
///
/// Every row taps through to the My Prescriptions screen (`PrescriptionRowAPIView`
/// there is not itself tappable, so there is no per-order detail to push). That
/// screen refetches, so what the patient acts on is the authoritative record
/// rather than this transcript snapshot.
struct ChatPrescriptionCardView: View {
    @Environment(\.appTheme) private var theme

    let payload: LookupPrescriptionsPayload
    let onSelect: (ChatPrescription) -> Void

    private var prescriptions: [ChatPrescription] {
        payload.prescriptions
    }

    /// The heading names the list the patient asked for — "in progress" and
    /// "already ordered" are different answers and must not read the same.
    private var sectionTitle: String {
        payload.scope == .history ? "Prescription history" : "Active prescriptions"
    }

    private var emptyMessage: String {
        payload.scope == .history
            ? "You have no past prescriptions."
            : "You have no prescriptions in progress."
    }

    var body: some View {
        if prescriptions.isEmpty {
            emptyState
        } else {
            VStack(spacing: theme.spacing.md) {
                section(sectionTitle, prescriptions)
            }
        }
    }

    /// An empty list is a normal answer, not a broken card.
    private var emptyState: some View {
        Text(emptyMessage)
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

    private func section(_ title: String, _ prescriptions: [ChatPrescription]) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text(title.uppercased())
                .font(theme.typography.medium12)
                .foregroundStyle(theme.colors.textSecondary)
                .padding(.leading, 2)

            VStack(spacing: 1) {
                ForEach(prescriptions) { prescription in
                    row(prescription)
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

    private func row(_ prescription: ChatPrescription) -> some View {
        Button {
            onSelect(prescription)
        } label: {
            HStack(spacing: theme.spacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(prescription.treatment)
                        .font(theme.typography.medium14)
                        .foregroundStyle(theme.colors.textPrimary)
                        .multilineTextAlignment(.leading)

                    if let subtitle = prescription.subtitle {
                        Text(subtitle)
                            .font(theme.typography.regular12)
                            .foregroundStyle(theme.colors.textSecondary)
                            .multilineTextAlignment(.leading)
                    }

                    // The same badge the My Prescriptions screen uses, so a status
                    // reads identically whether the patient came via chat or the
                    // tab — including the wording for a status neither knows.
                    PrescriptionStatusBadge(status: prescription.status, theme: theme)
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
        .accessibilityLabel(prescription.accessibilityLabel)
        .accessibilityHint("Opens your prescriptions")
        .accessibilityAddTraits(.isButton)
    }
}

extension ChatPrescription: Identifiable {}

extension ChatPrescription {
    /// `"Ordered 20 Aug 26 · Dr Ryan"` — the order date, then whoever is
    /// involved so far. Nil when the server sent none of it, so the row simply
    /// drops the line rather than showing an empty one.
    var subtitle: String? {
        var parts: [String] = []
        if let ordered = Self.formattedDay(orderedOn) {
            parts.append("Ordered \(ordered)")
        }
        if let doctor, !doctor.isEmpty {
            parts.append(doctor)
        }
        if let pharmacy, !pharmacy.isEmpty {
            parts.append(pharmacy)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// The two date shapes the server passes through — `"2026-08-20 13:12:28"`
    /// (`created_at`) and `"2026-11-18"` (`valid_until`) — rendered as
    /// `"20 Aug 26"`.
    ///
    /// Fixed locale, and **no timezone conversion**: this is presentation only.
    /// Anything unparseable falls back to the raw string rather than being
    /// dropped — a patient seeing `"2026-08-20"` is fine; a row missing its date
    /// is not.
    static func formattedDay(_ raw: String?) -> String? {
        guard let raw, !raw.isEmpty else { return nil }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for format in ["yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd"] {
            formatter.dateFormat = format
            if let parsed = formatter.date(from: raw) {
                formatter.dateFormat = "dd MMM yy"
                return formatter.string(from: parsed)
            }
        }
        return raw
    }

    var accessibilityLabel: String {
        [treatment, status.replacingOccurrences(of: "_", with: " "), subtitle]
            .compactMap { $0 }
            .joined(separator: ", ")
    }
}

#Preview("Active") {
    ChatPrescriptionCardView(
        payload: LookupPrescriptionsPayload(
            scope: .active,
            active: [
                ChatPrescription(
                    id: 10,
                    treatment: "Cold Sore Treatments",
                    status: "doctor_assigned",
                    paymentStatus: "paid",
                    amount: "17.50",
                    orderedOn: "2026-08-20 13:04:20",
                    validUntil: "2026-11-18",
                    doctor: "Dr Ragvendra Singh",
                    pharmacy: nil
                )
            ]
        )
    ) { _ in }
    .padding()
    .environment(\.appTheme, AppTheme.default)
}

#Preview("History") {
    ChatPrescriptionCardView(
        payload: LookupPrescriptionsPayload(
            scope: .history,
            history: [
                ChatPrescription(
                    id: 4,
                    treatment: "Hay Fever Treatments",
                    status: "completed",
                    paymentStatus: "paid",
                    amount: "25.00",
                    orderedOn: "2026-05-02 09:00:00",
                    validUntil: "2026-08-01",
                    doctor: nil,
                    pharmacy: "Boots O'Connell Street"
                )
            ]
        )
    ) { _ in }
    .padding()
    .environment(\.appTheme, AppTheme.default)
}

#Preview("Empty") {
    ChatPrescriptionCardView(
        payload: LookupPrescriptionsPayload(scope: .active)
    ) { _ in }
    .padding()
    .environment(\.appTheme, AppTheme.default)
}
