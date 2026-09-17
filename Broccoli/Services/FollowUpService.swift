//
//  FollowUpService.swift
//  Broccoli
//
//  Post-appointment follow-up check-in.
//

import Foundation

public protocol FollowUpServiceProtocol {
    /// Streams one turn of the follow-up check-in.
    ///
    /// Pass `conversationId: nil` and an `appointmentId` (the booking id from the
    /// `ai_followup_checkin` notification) to start; pass the `conversationId` from
    /// the `done` event to continue. A booking that does not belong to the caller
    /// arrives as a 404 `ServiceError`, not as a stream event.
    ///
    /// One turn in flight at a time — no server-side concurrency lock, so two
    /// overlapping turns on one `conversation_id` interleave and corrupt the
    /// transcript (same rule as Intake and the chatbot).
    func streamTurn(
        message: String,
        conversationId: Int?,
        appointmentId: Int?
    ) -> AsyncThrowingStream<TurnEvent, Error>
}

public final class FollowUpService: BaseService, FollowUpServiceProtocol {

    private let sseClient: SSEClientProtocol

    public init(sseClient: SSEClientProtocol = SSEClient()) {
        self.sseClient = sseClient
        super.init()
    }

    public func streamTurn(
        message: String,
        conversationId: Int?,
        appointmentId: Int?
    ) -> AsyncThrowingStream<TurnEvent, Error> {
        let endpoint = FollowUpEndpoint.turn(
            FollowUpTurnRequest(
                message: message,
                conversationId: conversationId,
                appointmentId: appointmentId
            )
        )

        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await self.handleServiceError {
                        for try await event in self.sseClient.stream(endpoint) {
                            continuation.yield(event)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
