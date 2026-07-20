//
//  ChatService.swift
//  Broccoli
//
//  Health Assistant chat. Contract: docs/ios-integration-guide.md §4.
//

import Foundation

public protocol ChatServiceProtocol {
    /// Streams one conversational turn.
    ///
    /// Pass `conversationId: nil` for the first message of a chat — the server
    /// creates the conversation and returns its id in the `done` event. Pass that
    /// id back on every subsequent message to continue the thread.
    ///
    /// ⚠️ One turn in flight per conversation. There is no server-side concurrency
    /// lock; two overlapping turns on one `conversation_id` interleave and corrupt
    /// the transcript. Callers must serialise (guide §4.3).
    func streamTurn(
        message: String,
        conversationId: Int?
    ) -> AsyncThrowingStream<TurnEvent, Error>
}

public final class ChatService: BaseService, ChatServiceProtocol {

    private let sseClient: SSEClientProtocol

    public init(sseClient: SSEClientProtocol) {
        self.sseClient = sseClient
        super.init()
    }

    public func streamTurn(
        message: String,
        conversationId: Int? = nil
    ) -> AsyncThrowingStream<TurnEvent, Error> {
        let endpoint = ChatEndpoint.chatbotTurn(
            TurnRequest(message: message, conversationId: conversationId)
        )

        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    // handleServiceError maps HTTPError -> ServiceError. It wraps a
                    // single async operation, so the mapping is applied around the
                    // consumption of the stream rather than its creation — errors
                    // surface mid-stream, not at call time.
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
