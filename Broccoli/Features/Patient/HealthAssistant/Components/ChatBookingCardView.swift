//
//  ChatBookingCardView.swift
//  Broccoli
//
//  P4-03 — the `prepare_booking` card.
//

import SwiftUI

/// Renders entirely from `display` — the server owns this copy so the wording can
/// change without a client release. Nothing here is derived from the booking
/// fields, which are a *suggestion* carried into the form, not a commitment
/// (guide §4.1.1).
struct ChatBookingCardView: View {
    @Environment(\.appTheme) private var theme

    let payload: PrepareBookingPayload
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                HStack(spacing: theme.spacing.sm) {
                    Image(systemName: "calendar")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(theme.colors.primary)
                        .accessibilityHidden(true)

                    Text(payload.display.title)
                        .font(theme.typography.medium14)
                        .foregroundStyle(theme.colors.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Optional — routinely absent, and its absence is not an error.
                if let subtitle = payload.display.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(theme.typography.regular12)
                        .foregroundStyle(theme.colors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 4) {
                    Text(payload.display.cta)
                        .font(theme.typography.medium14)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(theme.colors.primary)
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(theme.spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(theme.colors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(theme.colors.primary.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel([payload.display.title, payload.display.subtitle]
            .compactMap { $0 }
            .joined(separator: ". "))
        .accessibilityHint(payload.display.cta)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    let full = try! JSONDecoder().decode(PrepareBookingPayload.self, from: Data(#"""
    {
      "action": "open_booking",
      "department_id": 2,
      "is_gp": false,
      "service_hint": "cardiology",
      "service_id": null,
      "date_from": "2026-08-01",
      "date_to": "2026-08-08",
      "time_preference": "morning",
      "reason": "chest tightness when climbing stairs",
      "display": {
        "title": "Book a cardiology consultation",
        "subtitle": "Mornings, week of 1 August",
        "cta": "Choose a time"
      }
    }
    """#.utf8))

    let minimal = try! JSONDecoder().decode(PrepareBookingPayload.self, from: Data(#"""
    {
      "action": "open_booking",
      "department_id": 1,
      "is_gp": true,
      "display": { "title": "Book a GP appointment", "cta": "Continue" }
    }
    """#.utf8))

    return VStack(spacing: 16) {
        ChatBookingCardView(payload: full) {}
        ChatBookingCardView(payload: minimal) {}
    }
    .padding()
    .environment(\.appTheme, AppTheme.default)
}
