//
//  IntakeModels.swift
//  Broccoli
//
//  Wire models for the pre-appointment intake turn (POST /intake/turn).
//  Contract: docs/ios-integration-guide.md §5.
//

import Foundation

// MARK: - Request

/// One turn of the intake questionnaire.
///
/// Two rules the server enforces and this type encodes:
///
/// * `appointmentId` is **required on the first turn** (omit it → 422) and
///   **ignored on resume** — a resumed intake keeps the appointment it was started
///   against, so the client cannot re-point it at another one.
/// * `conversationId` is omitted entirely when nil, never sent as `null`: an absent
///   key is what tells the server to start a new intake.
public struct IntakeTurnRequest: Equatable {
    public let message: String
    public let conversationId: Int?
    public let appointmentId: Int?

    public init(message: String, conversationId: Int? = nil, appointmentId: Int? = nil) {
        self.message = message
        self.conversationId = conversationId
        self.appointmentId = appointmentId
    }

    public var jsonBody: [String: Any] {
        var body: [String: Any] = ["message": message]
        if let conversationId {
            body["conversation_id"] = conversationId
        }
        // Sent only when starting. On resume the server ignores it anyway, but
        // omitting it keeps the request honest about what it is asking for.
        if conversationId == nil, let appointmentId {
            body["appointment_id"] = appointmentId
        }
        return body
    }
}

// MARK: - Progress marker (`advance_intake`)

/// `advance_intake` streams as an ordinary `tool_result` each time the assistant
/// finishes with a core question, but there is no on-screen progress indicator —
/// the questionnaire's length isn't shown to the patient — so the client drops
/// this card rather than decoding or rendering it (see `IntakeViewModel`).
public let intakeProgressToolName = "advance_intake"
