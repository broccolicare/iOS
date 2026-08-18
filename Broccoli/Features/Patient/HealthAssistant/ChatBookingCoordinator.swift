//
//  ChatBookingCoordinator.swift
//  Broccoli
//
//  P4-04 / P4-06 — turning a chat card tap into navigation.
//  Contract: docs/ios-integration-guide.md §4.1.1.
//

import Foundation

/// Bridges the Health Assistant's cards to the existing native flows.
///
/// 🛑 **This never books anything.** It prefills and pushes a screen; the user
/// still walks through `BookingConfirmationView` and taps confirm. That screen is
/// the only human checkpoint before a real appointment is created — with
/// `covered: true` Stripe is skipped entirely, so there is no payment step to act
/// as a second confirmation. Never add a path that routes past it.
///
/// Which screen depends on what chat already settled. When the assistant got as
/// far as an exact time (service → day → period → time), the picker has nothing
/// left to ask and we open the confirmation screen directly; otherwise the user
/// lands on the ordinary form. Either way the confirm tap is untouched.
@MainActor
final class ChatBookingCoordinator {

    private let bookingViewModel: BookingGlobalViewModel
    private let router: Router

    init(bookingViewModel: BookingGlobalViewModel, router: Router = .shared) {
        self.bookingViewModel = bookingViewModel
        self.router = router
    }

    // MARK: - prepare_booking (P4-04)

    /// - Parameter slot: the time the user tapped on the card, if they tapped one
    ///   rather than the card body. It narrows the prefill to that exact day and
    ///   time. Together with `payload.selectedTime` (a time already chosen in
    ///   chat) it decides whether the day/time picker is worth showing at all —
    ///   it never shortens the *decision*: the same confirmation screen, the same
    ///   tap to confirm.
    func openBooking(_ payload: PrepareBookingPayload, slot: BookingSlot? = nil) async {
        // Anything other than `open_booking` is a card shape we don't understand.
        // Do nothing rather than guess at a destination.
        guard payload.isSupportedAction else { return }

        let departmentId = String(payload.departmentId)
        let isGP = payload.isGp ? "1" : "0"

        // A tapped slot is more specific than the window and period the model
        // asked for, so it wins over both. Its date still goes through
        // `parseDate`, which drops anything in the past.
        let preferredDate = Self.parseDate(slot?.date ?? payload.dateFrom)
        let period = slot.map { Self.normalisedTimePreference($0.period) }
            ?? Self.normalisedTimePreference(payload.timePreference)
        // The time the user has already settled on — tapped on the card, or picked
        // from the assistant's time chips before the card was ever shown.
        let chosenTime = Self.normalisedClockTime(slot?.time ?? payload.selectedTime)

        func handOver(serviceId: Int?) {
            bookingViewModel.pendingChatPrefill = ChatBookingPrefill(
                departmentId: departmentId,
                isGP: isGP,
                serviceId: serviceId,
                preferredDate: preferredDate,
                timeSlotPeriod: period,
                reason: payload.reason,
                // Dropped if the date didn't survive `parseDate` — a time without
                // the day it belongs to would select a slot on whatever day the
                // form happens to open on.
                exactTime: preferredDate == nil ? nil : chosenTime
            )
            bookingViewModel.selectedDepartmentId = departmentId
            bookingViewModel.isGP = isGP
        }

        if payload.isGp {
            // GP has no service picker — the form loads the department and selects
            // its only service itself. Resolving a hint here would mean a network
            // call whose result the form immediately discards, so skip it entirely.
            handOver(serviceId: nil)
            if preferredDate != nil, chosenTime != nil {
                // Only for the confirmation shortcut, and only then: the slot fetch
                // needs a service id, and GP's is "the department's one service" —
                // exactly what `GPAppointmentBookingForm` resolves for itself. On
                // the ordinary path the form still does it, so this stays a call we
                // make only when it buys the user a screen.
                await bookingViewModel.loadDepartmentServices(departmentId: departmentId)
                bookingViewModel.selectedService = bookingViewModel.services.first
                if await pushConfirmationIfStillFree(
                    date: preferredDate, time: chosenTime, reason: payload.reason
                ) { return }
            }
            router.push(.gPAppointBookingForm)
            return
        }

        // Load the department's services so `service_id` / `service_hint` can be
        // resolved against real data. The picker would load these anyway, so this
        // isn't an extra round trip so much as an earlier one.
        await bookingViewModel.loadDepartmentServices(departmentId: departmentId)
        let resolved = Self.resolveService(payload, in: bookingViewModel.services)
        handOver(serviceId: resolved?.id)

        guard let resolved else {
            // Chat saves taps; it must never dead-end. An unresolvable hint lands
            // the user on the picker they'd have reached from the home screen
            // anyway, with the department already narrowed down (P4-04).
            router.push(.specialistList(departmentId: departmentId))
            return
        }

        bookingViewModel.selectedService = resolved
        if await pushConfirmationIfStillFree(
            date: preferredDate, time: chosenTime, reason: payload.reason
        ) { return }
        router.push(.specialistBookingForm)
    }

    /// Skip the day/time picker and open the confirmation screen — but only when
    /// the user has genuinely already chosen, and the choice is still bookable.
    ///
    /// Chat now asks for the service, the day, the period and the exact time, so
    /// by the time the card appears the picker has nothing left to ask. Sending
    /// the user back to it is a screen of re-entering what they just answered.
    ///
    /// 🛑 **This does not route past the human checkpoint.** `BookingConfirmationView`
    /// is where the user reviews the appointment and taps confirm (and pays);
    /// this lands them *on* it, never beyond it.
    ///
    /// The live fetch is the whole safety story: the assistant's times were read
    /// mid-conversation and nothing reserved them, so we re-fetch the day and let
    /// `applyChatExactTime` select the slot only if it is still there. If it is
    /// gone — or there is no date, or no time — we return `false` and the caller
    /// falls back to the ordinary form, where the user sees the real times. Chat
    /// saves taps; it never dead-ends.
    ///
    /// - Returns: `true` when the confirmation screen was pushed.
    private func pushConfirmationIfStillFree(
        date: Date?,
        time: String?,
        reason: String?
    ) async -> Bool {
        guard let date, let time else { return false }

        bookingViewModel.selectedDate = date
        // Cleared first: this path skips the forms, so nothing else calls
        // `resetBookingForm()`, and a slot left over from an earlier booking would
        // make the check below pass on a time this conversation never chose.
        bookingViewModel.selectedTimeSlot = nil
        bookingViewModel.selectedTimeSlotPeriod = nil

        await bookingViewModel.fetchAvailableTimeSlots()
        bookingViewModel.applyChatExactTime(time)
        guard bookingViewModel.selectedTimeSlot != nil else { return false }

        if let reason, !reason.isEmpty {
            bookingViewModel.additionalNotes = reason
        }
        // Consume the prefill we just parked: nothing downstream of here calls
        // `consumeChatPrefill()`, and leaving it set would prefill whatever
        // booking form the user opens next with this conversation's answers.
        _ = bookingViewModel.consumeChatPrefill()
        router.push(.bookingConfirmation)
        return true
    }

    // MARK: - lookup_appointments tap-through (P4-06)

    /// Fetches the appointment by id and pushes the existing detail screen.
    ///
    /// The fetch happens here, on tap — never at render time. A transcript can hold
    /// a dozen appointment rows and pre-fetching them all would be a burst of calls
    /// for taps that mostly never happen.
    ///
    /// Errors surface through the booking view model's existing error toast, so a
    /// failed fetch never disturbs the transcript.
    func openAppointment(id: Int) async {
        await bookingViewModel.navigateToBookingFromNotification(
            bookingId: id,
            userRole: .patient
        )
    }

    // MARK: - Resolution

    /// `service_id` wins when present; otherwise match `service_hint` by name.
    ///
    /// The server now resolves the service itself against the same catalogue and
    /// sends the id back, so the id path is the usual one. The hint path is still
    /// load-bearing: `service_id` is null whenever the server's own match failed
    /// or Laravel was unreachable, and it stays the only path for a card the
    /// server enriched without a client (guide §4.1.1).
    static func resolveService(_ payload: PrepareBookingPayload, in services: [Service]) -> Service? {
        if let serviceId = payload.serviceId,
           let match = services.first(where: { $0.id == serviceId }) {
            return match
        }

        guard let hint = payload.serviceHint?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(),
            !hint.isEmpty
        else { return nil }

        // Exact name first, so "Blood Test" doesn't lose to "Blood Test Panel"
        // just because the latter happens to come first in the list.
        if let exact = services.first(where: { $0.name.lowercased() == hint }) {
            return exact
        }

        // Then substring, in either direction — the hint is the model's phrasing
        // ("cardiology") against a catalogue name ("Cardiology Consultation").
        return services.first { service in
            let name = service.name.lowercased()
            return name.contains(hint) || hint.contains(name)
        }
    }

    /// `any` is a real value on the wire but has no form representation — it feeds
    /// `time_slot` on the booking request, where "any" would be rejected. Treat it
    /// as "no preference" and leave the field untouched.
    static func normalisedTimePreference(_ raw: String?) -> String? {
        guard let raw = raw?.lowercased(), raw != "any" else { return nil }
        return ["morning", "afternoon", "evening"].contains(raw) ? raw : nil
    }

    /// Clock times for comparison: `"14:00"`, `"14:00:00"` and `"2:00 PM"` are all
    /// the same slot to Laravel, and which one arrives is not ours to assume.
    /// Compare on `HH:mm`, and give up rather than guess if it isn't one.
    static func normalisedClockTime(_ raw: String?) -> String? {
        guard let raw = raw?.trimmingCharacters(in: .whitespaces), !raw.isEmpty else { return nil }
        let parts = raw.split(separator: ":")
        guard parts.count >= 2, let hour = Int(parts[0]), let minute = Int(parts[1].prefix(2)),
              (0...23).contains(hour), (0...59).contains(minute)
        else { return nil }
        return String(format: "%02d:%02d", hour, minute)
    }

    /// `date_from` is `yyyy-MM-dd`. Impossible windows are stripped server-side, so
    /// a value that arrives is either sane or absent — but a past date can still
    /// slip through, and the form must not open on one.
    static func parseDate(_ raw: String?) -> Date? {
        guard let raw, let parsed = dateFormatter.date(from: raw) else { return nil }
        let today = Calendar.current.startOfDay(for: Date())
        return parsed < today ? nil : parsed
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        // Fixed locale/calendar/zone: a user on a non-Gregorian calendar or in a
        // 12-hour locale must still parse this server format correctly.
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "Europe/Dublin")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
