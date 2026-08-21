//
//  ChatBookingCardView.swift
//  Broccoli
//
//  P4-03 — the `prepare_booking` card.
//

import SwiftUI

/// Renders entirely from `display` and `slots` — the server owns this copy so the
/// wording can change without a client release. Nothing here is derived from the
/// booking fields, which are a *suggestion* carried into the form, not a
/// commitment (guide §4.1.1).
///
/// 🛑 **Tapping a time is not booking a time.** Both the card body and a time chip
/// land on the same booking form and the same confirmation screen; a chip only
/// arrives there with the day and time already filled in. Never let a chip become
/// a shortcut past the confirmation step.
struct ChatBookingCardView: View {
    @Environment(\.appTheme) private var theme

    let payload: PrepareBookingPayload
    let onTap: () -> Void
    /// Nil-safe by construction: only called for a slot this view was given.
    var onSelectSlot: (BookingSlot) -> Void = { _ in }

    /// Chips are grouped under their day so "Thursday" isn't repeated eight times.
    /// `slots` arrives ordered by date then time, so first-seen order is already
    /// chronological — no sorting, and no re-deriving the day name from `date`.
    private var slotsByDay: [(day: String, slots: [BookingSlot])] {
        payload.slots.reduce(into: []) { groups, slot in
            if let index = groups.firstIndex(where: { $0.day == slot.displayDate }) {
                groups[index].slots.append(slot)
            } else {
                groups.append((day: slot.displayDate, slots: [slot]))
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            cardBody

            if !payload.slots.isEmpty {
                slotPicker
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(theme.colors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(theme.colors.primary.opacity(0.25), lineWidth: 1)
        )
    }

    private var cardBody: some View {
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
                    // With times on the card the body is the "none of these" path,
                    // so it says so rather than repeating the server's "Choose a
                    // time" next to eight chips that already are times.
                    Text(payload.slots.isEmpty ? payload.display.cta : "See more times")
                        .font(theme.typography.medium14)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(theme.colors.primary)
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(theme.spacing.lg)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel([payload.display.title, payload.display.subtitle]
            .compactMap { $0 }
            .joined(separator: ". "))
        .accessibilityHint(payload.display.cta)
        .accessibilityAddTraits(.isButton)
    }

    /// The offered times. Laid out as wrapping rows rather than a horizontal
    /// scroller: eight chips fit, and a scroller hides times behind a gesture the
    /// user has no reason to expect inside a chat transcript.
    private var slotPicker: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Divider().overlay(theme.colors.primary.opacity(0.15))

            ForEach(slotsByDay, id: \.day) { group in
                VStack(alignment: .leading, spacing: 6) {
                    Text(group.day)
                        .font(theme.typography.regular12)
                        .foregroundStyle(theme.colors.textSecondary)

                    ChipFlowLayout(spacing: 6) {
                        ForEach(group.slots) { slot in
                            slotChip(slot)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, theme.spacing.lg)
        .padding(.bottom, theme.spacing.lg)
        .padding(.top, 2)
    }

    private func slotChip(_ slot: BookingSlot) -> some View {
        Button {
            onSelectSlot(slot)
        } label: {
            // `displayTime` verbatim — Laravel's own rendering, the same string
            // the native booking screen shows for this slot.
            Text(slot.displayTime)
                .font(theme.typography.medium14)
                .foregroundStyle(theme.colors.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule().fill(theme.colors.primary.opacity(0.08))
                )
                .overlay(
                    Capsule().stroke(theme.colors.primary.opacity(0.35), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(slot.displayDate) at \(slot.displayTime)")
        .accessibilityHint("Opens the booking form with this time selected")
    }
}

#Preview {
    let full = try! JSONDecoder().decode(PrepareBookingPayload.self, from: Data(#"""
    {
      "action": "open_booking",
      "department_id": 2,
      "is_gp": false,
      "service_hint": "cardiology",
      "service_id": 17,
      "service_name": "Cardiology Consultation",
      "slots": [
        {"date": "2026-08-01", "display_date": "Saturday 1 August", "period": "morning",
         "time": "09:00", "display_time": "9:00 AM", "price": "80.00", "currency": "EUR"},
        {"date": "2026-08-01", "display_date": "Saturday 1 August", "period": "morning",
         "time": "09:20", "display_time": "9:20 AM", "price": "80.00", "currency": "EUR"},
        {"date": "2026-08-01", "display_date": "Saturday 1 August", "period": "morning",
         "time": "11:40", "display_time": "11:40 AM", "price": "80.00", "currency": "EUR"},
        {"date": "2026-08-02", "display_date": "Sunday 2 August", "period": "morning",
         "time": "10:00", "display_time": "10:00 AM", "price": "80.00", "currency": "EUR"}
      ],
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
