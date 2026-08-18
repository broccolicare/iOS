//
//  IntakeSessionStore.swift
//  Broccoli
//
//  Remembers where an intake got to, scoped to its appointment.
//

import Foundation

/// Persists the intake `conversation_id` for an appointment, and whether that
/// intake finished.
///
/// ⚠️ **A deliberate exception to the chat's ephemeral-session rule** — and the
/// only one. `ChatViewModel` keeps its `conversationId` in memory precisely so the
/// thread dies with the screen; intake must do the opposite, for two reasons the
/// AI-backend team set out in `docs/ios-integration-answers.md` §7:
///
/// 1. **Restarting is worse than resuming.** Intake is a multi-question clinical
///    interview. A patient interrupted at question 8 who has to restart from
///    question 1 will often just abandon it — and an abandoned intake yields the
///    clinician *nothing*. The failure mode here is a lost clinical record, not a
///    lost chat transcript.
/// 2. **Nothing server-side prevents duplicates.** There is no unique constraint
///    on `appointment_id` and no resume-or-409 on start, so a second intake on the
///    same appointment simply succeeds — and if it also completes, its (likely
///    thinner) summary silently supersedes the first in the doctor's view.
///    Remembering the id client-side is what keeps that from happening.
///
/// Only the id and a completion flag are stored — never message content, which
/// stays server-side in the transcript.
struct IntakeSessionStore {

    // MARK: - Constants

    private static let conversationKey = "intakeConversationIdsByAppointment"
    private static let completedKey = "completedIntakeAppointmentIds"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Conversation id

    /// The in-progress intake for this appointment, or nil to start a new one.
    func conversationId(forAppointment appointmentId: Int) -> Int? {
        let map = defaults.dictionary(forKey: Self.conversationKey) as? [String: Int]
        return map?[String(appointmentId)]
    }

    /// Records the id the server assigned, so the next visit resumes rather than
    /// starting a second intake against the same appointment.
    func save(conversationId: Int, forAppointment appointmentId: Int) {
        var map = defaults.dictionary(forKey: Self.conversationKey) as? [String: Int] ?? [:]
        map[String(appointmentId)] = conversationId
        defaults.set(map, forKey: Self.conversationKey)
    }

    // MARK: - Completion

    /// True once this appointment's intake reached `conversation_status: completed`.
    ///
    /// Read before the screen opens so a finished intake shows its summary state
    /// instead of a composer — the server would happily start a *second* intake if
    /// we sent another message, and that is exactly the silent-supersede case.
    func isCompleted(appointmentId: Int) -> Bool {
        completedIds().contains(appointmentId)
    }

    func markCompleted(appointmentId: Int) {
        var ids = completedIds()
        ids.insert(appointmentId)
        defaults.set(Array(ids), forKey: Self.completedKey)
    }

    /// Forgets everything about one appointment's intake. Not used by the flow —
    /// it exists for sign-out, where another patient must never inherit a
    /// conversation id that is not theirs.
    func clear(appointmentId: Int) {
        var map = defaults.dictionary(forKey: Self.conversationKey) as? [String: Int] ?? [:]
        map.removeValue(forKey: String(appointmentId))
        defaults.set(map, forKey: Self.conversationKey)

        var ids = completedIds()
        ids.remove(appointmentId)
        defaults.set(Array(ids), forKey: Self.completedKey)
    }

    /// Drops every remembered intake. **Call on sign-out.** A conversation id is
    /// scoped to the patient who owns the appointment; leaving one behind would
    /// have the next account resume a stranger's questionnaire (the server's IDOR
    /// guard 404s it, but the correct fix is not to ask).
    func clearAll() {
        defaults.removeObject(forKey: Self.conversationKey)
        defaults.removeObject(forKey: Self.completedKey)
    }

    // MARK: - Private

    private func completedIds() -> Set<Int> {
        Set(defaults.array(forKey: Self.completedKey) as? [Int] ?? [])
    }
}
