//
//  IntakeService.swift
//  Broccoli
//
//  Pre-appointment intake. Contract: docs/ios-integration-guide.md §5.
//

import Foundation

public protocol IntakeServiceProtocol {
    /// Streams one turn of the intake questionnaire.
    ///
    /// Pass `conversationId: nil` and an `appointmentId` to start; pass the
    /// `conversationId` from the `done` event to continue. The server rejects a
    /// start with no appointment (422) and an appointment this patient does not
    /// own (404) — both arrive as a thrown `ServiceError`, not as stream events.
    ///
    /// ⚠️ One turn in flight at a time, as with the chatbot: there is no
    /// server-side concurrency lock, and two overlapping turns on one
    /// `conversation_id` interleave and corrupt the transcript (guide §4.3).
    func streamTurn(
        message: String,
        conversationId: Int?,
        appointmentId: Int?
    ) -> AsyncThrowingStream<TurnEvent, Error>
}

public final class IntakeService: BaseService, IntakeServiceProtocol {

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
        let endpoint = IntakeEndpoint.turn(
            IntakeTurnRequest(
                message: message,
                conversationId: conversationId,
                appointmentId: appointmentId
            )
        )

        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    // Mirrors ChatService: the mapping wraps consumption of the
                    // stream rather than its creation, so HTTP errors surface as
                    // ServiceError mid-stream rather than at call time.
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
