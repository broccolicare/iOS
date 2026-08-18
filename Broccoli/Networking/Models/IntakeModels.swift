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

// MARK: - Progress card (`advance_intake`)

/// How one core question ended.
///
/// The distinction is clinical, not cosmetic: "they wouldn't say" and "it doesn't
/// apply to them" are different statements about the patient, and the server
/// records them separately in the summary the doctor reads. Unknown values degrade
/// rather than throw, so a future outcome can't break an existing client.
public enum IntakeQuestionOutcome: String, Decodable, Equatable {
    case answered
    case declined
    case notApplicable = "not_applicable"
    case unknown

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = IntakeQuestionOutcome(rawValue: raw) ?? .unknown
    }
}

/// `advance_intake` — streamed as an ordinary `tool_result` each time the
/// assistant finishes with a core question.
///
/// The intake asks a fixed, clinically approved set of questions, so unlike the
/// chatbot it has a real end the patient can see coming. This card is what drives
/// the "question N of M" indicator.
///
/// ⚠️ `position` can jump by more than one. The pain follow-ups are skipped
/// wholesale when the patient reports no pain, and `total` stays the full question
/// count rather than shrinking — a bar that leaps forward is honest, a denominator
/// that changes under the user is not.
public struct IntakeProgressPayload: Decodable, Equatable {
    public let questionId: String
    public let outcome: IntakeQuestionOutcome
    public let position: Int
    public let total: Int

    enum CodingKeys: String, CodingKey {
        case questionId = "question_id"
        case outcome
        case position
        case total
    }

    public init(questionId: String, outcome: IntakeQuestionOutcome, position: Int, total: Int) {
        self.questionId = questionId
        self.outcome = outcome
        self.position = position
        self.total = total
    }

    /// Clamped so a malformed or out-of-range card can never drive the bar past
    /// its end or below its start.
    public var fraction: Double {
        guard total > 0 else { return 0 }
        return min(1, max(0, Double(position) / Double(total)))
    }
}

/// The tool name carrying `IntakeProgressPayload`.
public let intakeProgressToolName = "advance_intake"
