//
//  FollowUpModels.swift
//  Broccoli
//
//  Wire models for the post-appointment follow-up check-in turn (POST /followup/turn).
//

import Foundation

/// One turn of the follow-up check-in.
///
/// Same two rules as `IntakeTurnRequest`: `appointmentId` (the booking id from the
/// `ai_followup_checkin` notification) is required on the first turn and ignored on
/// resume, and `conversationId` is omitted entirely rather than sent as `null`.
public struct FollowUpTurnRequest: Equatable {
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
        if conversationId == nil, let appointmentId {
            body["appointment_id"] = appointmentId
        }
        return body
    }
}
