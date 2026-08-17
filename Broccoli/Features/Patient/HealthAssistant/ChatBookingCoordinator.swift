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
/// 🛑 **This never books anything.** It prefills and pushes a form; the user still
/// walks through `BookingConfirmationView` and taps confirm. That screen is the
/// only human checkpoint before a real appointment is created — with
/// `covered: true` Stripe is skipped entirely, so there is no payment step to act
/// as a second confirmation. Never add a path that routes past it.
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
    ///   time — it does **not** shorten the journey: the same form, the same
    ///   confirmation screen, the same tap to confirm.
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
                exactTime: preferredDate == nil ? nil : slot?.time
            )
            bookingViewModel.selectedDepartmentId = departmentId
            bookingViewModel.isGP = isGP
        }

        if payload.isGp {
            // GP has no service picker — the form loads the department and selects
            // its only service itself. Resolving a hint here would mean a network
            // call whose result the form immediately discards, so skip it entirely.
            handOver(serviceId: nil)
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
        router.push(.specialistBookingForm)
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
