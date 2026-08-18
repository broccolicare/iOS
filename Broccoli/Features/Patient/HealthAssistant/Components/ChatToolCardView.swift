//
//  ChatToolCardView.swift
//  Broccoli
//
//  P4-01 — routes a `tool_result` event to the card that renders it.
//

import SwiftUI

/// The one place a tool name is turned into a view.
///
/// ⚠️ **Unknown tools are silently ignored.** The server can add tools without a
/// client release, and an unrecognised card must never interrupt the stream or
/// show an error — the user's actual answer arrives as text either way. Hence the
/// no-op `default`, and hence a decode failure rendering nothing rather than a
/// placeholder.
///
/// 🚫 **Do not add a `start_booking` case.** It is deprecated and will be removed
/// (guide §4.1); `prepare_booking` replaces it.
struct ChatToolCardView: View {

    let card: ChatToolCard
    /// The slot is non-nil when the user tapped one of the card's offered times
    /// rather than the card body. Both land on the same form.
    let onOpenBooking: (PrepareBookingPayload, BookingSlot?) -> Void
    let onOpenAppointment: (ChatAppointment) -> Void
    /// Sends the given text as the next turn's `message` (a tapped quick-reply).
    let onSendMessage: (String) -> Void

    var body: some View {
        switch card.tool {
        case "offer_quick_replies", "offer_booking_days":
            // Server-driven chips (BIC-1.5). The tapped label is sent as the next
            // message; the booking flow uses this for care type, service, day,
            // time of day and the exact time.
            //
            // `offer_booking_days` is the same chip row with the same payload
            // shape — a separate tool only because the *server* computes the day
            // labels and their dates rather than trusting the model to count
            // forward. Nothing here needs to know the difference.
            if let payload = decode(QuickRepliesPayload.self), !payload.options.isEmpty {
                ChatQuickRepliesView(options: payload.options, onSelect: onSendMessage)
            }

        case "prepare_booking":
            if let payload = decode(PrepareBookingPayload.self),
               // A card whose action we don't understand is dropped entirely
               // rather than rendered with a button that goes nowhere (P4-03).
               payload.isSupportedAction {
                ChatBookingCardView(
                    payload: payload,
                    onTap: { onOpenBooking(payload, nil) },
                    onSelectSlot: { slot in onOpenBooking(payload, slot) }
                )
            }

        case "create_medication_reminder":
            if let payload = decode(MedicationReminderPayload.self) {
                ChatReminderCardView(payload: payload)
            }

        case "lookup_appointments":
            if let payload = decode(LookupAppointmentsPayload.self) {
                ChatAppointmentCardView(payload: payload, onSelect: onOpenAppointment)
            }

        default:
            EmptyView()
        }
    }

    private func decode<T: Decodable>(_ type: T.Type) -> T? {
        do {
            return try JSONDecoder().decode(type, from: card.data)
        } catch {
            #if DEBUG
            print("⚠️ [ChatToolCardView] could not decode \(card.tool): \(error)")
            #endif
            return nil
        }
    }
}
