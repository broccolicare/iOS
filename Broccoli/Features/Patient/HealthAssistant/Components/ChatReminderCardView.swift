//
//  ChatReminderCardView.swift
//  Broccoli
//
//  P4-02 — confirmation for `create_medication_reminder`.
//

import SwiftUI

/// ⚠️ **Copy constraint:** the reminder API is create-only. There is no list,
/// cancel, update or delete endpoint (guide §4.1) — a reminder created here cannot
/// be viewed or cancelled anywhere in the app. Nothing on this card may imply
/// otherwise: no "manage", no "view reminders", no tap target suggesting a detail
/// screen exists. The second line says so explicitly rather than staying silent,
/// because silence reads as "it's in there somewhere".
struct ChatReminderCardView: View {
    @Environment(\.appTheme) private var theme

    let payload: MedicationReminderPayload

    var body: some View {
        HStack(alignment: .top, spacing: theme.spacing.md) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(theme.colors.primary)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Reminder set")
                    .font(theme.typography.medium14)
                    .foregroundStyle(theme.colors.textPrimary)

                Text("You'll get a notification when it's due. Reminders can't be changed or cancelled from the app yet.")
                    .font(theme.typography.regular12)
                    .foregroundStyle(theme.colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Free text forwarded verbatim from Laravel — never switched on,
                // never mapped to an enum. Shown only when it says something a
                // patient can act on.
                if isNoteworthy(payload.status) {
                    Text(payload.status.capitalized)
                        .font(theme.typography.regular12)
                        .foregroundStyle(theme.colors.textSecondary)
                        .padding(.horizontal, theme.spacing.sm)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(theme.colors.primary.opacity(0.08)))
                        .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(theme.spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(theme.colors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(theme.colors.border, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Reminder set. You'll get a notification when it's due. Reminders can't be changed or cancelled from the app yet.")
    }

    /// "active"/"created" tell the patient nothing the headline hasn't; anything
    /// else might, so show it.
    private func isNoteworthy(_ status: String) -> Bool {
        !["active", "created", "scheduled", "ok"].contains(status.lowercased())
    }
}

#Preview {
    VStack(spacing: 16) {
        ChatReminderCardView(payload: MedicationReminderPayload(id: 1, status: "active"))
        ChatReminderCardView(payload: MedicationReminderPayload(id: 2, status: "pending_review"))
    }
    .padding()
    .environment(\.appTheme, AppTheme.default)
}
