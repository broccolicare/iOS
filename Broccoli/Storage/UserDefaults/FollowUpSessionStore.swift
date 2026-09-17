//
//  FollowUpSessionStore.swift
//  Broccoli
//
//  Remembers where a follow-up check-in got to, scoped to its booking.
//

import Foundation

/// Persists the follow-up `conversation_id` for a booking, and whether that
/// check-in finished.
///
/// Same rationale as `IntakeSessionStore`: the check-in is triggered by a
/// notification the patient may not act on immediately, so a follow-up interrupted
/// partway through must resume rather than restart — and nothing server-side
/// prevents a second check-in on the same booking from silently superseding the
/// first in the clinician's view.
struct FollowUpSessionStore {

    // MARK: - Constants

    private static let conversationKey = "followUpConversationIdsByBooking"
    private static let completedKey = "completedFollowUpBookingIds"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Conversation id

    func conversationId(forAppointment appointmentId: Int) -> Int? {
        let map = defaults.dictionary(forKey: Self.conversationKey) as? [String: Int]
        return map?[String(appointmentId)]
    }

    func save(conversationId: Int, forAppointment appointmentId: Int) {
        var map = defaults.dictionary(forKey: Self.conversationKey) as? [String: Int] ?? [:]
        map[String(appointmentId)] = conversationId
        defaults.set(map, forKey: Self.conversationKey)
    }

    // MARK: - Completion

    func isCompleted(appointmentId: Int) -> Bool {
        completedIds().contains(appointmentId)
    }

    func markCompleted(appointmentId: Int) {
        var ids = completedIds()
        ids.insert(appointmentId)
        defaults.set(Array(ids), forKey: Self.completedKey)
    }

    /// Drops every remembered follow-up. **Call on sign-out** — a conversation id
    /// is scoped to the patient who owns the booking, and leaving one behind would
    /// have the next account resume a stranger's check-in.
    func clearAll() {
        defaults.removeObject(forKey: Self.conversationKey)
        defaults.removeObject(forKey: Self.completedKey)
    }

    // MARK: - Private

    private func completedIds() -> Set<Int> {
        Set(defaults.array(forKey: Self.completedKey) as? [Int] ?? [])
    }
}
