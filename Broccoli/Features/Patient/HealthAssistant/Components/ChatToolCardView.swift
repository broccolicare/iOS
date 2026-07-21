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
    let onOpenBooking: (PrepareBookingPayload) -> Void
    let onOpenAppointment: (ChatAppointment) -> Void

    var body: some View {
        switch card.tool {
        case "prepare_booking":
            if let payload = decode(PrepareBookingPayload.self),
               // A card whose action we don't understand is dropped entirely
               // rather than rendered with a button that goes nowhere (P4-03).
               payload.isSupportedAction {
                ChatBookingCardView(payload: payload) {
                    onOpenBooking(payload)
                }
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
