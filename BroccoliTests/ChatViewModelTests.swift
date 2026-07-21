//
//  ChatViewModelTests.swift
//  BroccoliTests
//
//  Covers P3-03 (token accumulation), P3-04 (turn serialisation), P3-06 (done
//  statuses), P3-07 (retry policy), P3-08 (card clearing) and P3-10 (teardown).
//  No network is involved — the service is stubbed.
//

import XCTest
@testable import Broccoli

@MainActor
final class ChatViewModelTests: XCTestCase {

    // MARK: - Stub

    /// Replays a scripted event sequence, recording what it was asked to send.
    private final class StubChatService: ChatServiceProtocol, @unchecked Sendable {
        var script: [TurnEvent] = []
        var error: Error?
        /// Every (message, conversationId) pair the VM asked for, in order.
        private(set) var calls: [(message: String, conversationId: Int?)] = []

        func streamTurn(message: String, conversationId: Int?) -> AsyncThrowingStream<TurnEvent, Error> {
            calls.append((message, conversationId))
            let script = script
            let error = error
            return AsyncThrowingStream { continuation in
                Task {
                    for event in script {
                        continuation.yield(event)
                    }
                    if let error {
                        continuation.finish(throwing: error)
                    } else {
                        continuation.finish()
                    }
                }
            }
        }
    }

    private func makeVM(_ service: StubChatService) -> ChatViewModel {
        ChatViewModel(chatService: service)
    }

    /// Spins the run loop until `condition` holds or we give up. The VM's turn runs
    /// in a detached Task, so assertions can't be made synchronously after `send`.
    private func wait(
        for condition: @escaping () -> Bool,
        timeout: TimeInterval = 2,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return }
            try? await Task.sleep(for: .milliseconds(10))
        }
        XCTFail("Condition not met within \(timeout)s", file: file, line: line)
    }

    // MARK: - P3-03 · Token accumulation

    func testTokensConcatenateInOrderPreservingWhitespace() async {
        let service = StubChatService()
        service.script = [
            .token("Hello"),
            .token(", "),
            .token("how are  you"),
            .token("?"),
            .done(TurnDone(status: .ok, conversationId: 7))
        ]
        let vm = makeVM(service)

        vm.send("hi")
        await wait { !vm.isTurnInFlight }

        // Exact concatenation — no trimming, no inserted separators. The server
        // chunks mid-word, so any normalisation here corrupts the reply.
        XCTAssertEqual(vm.messages.compactMap(\.assistantText), ["Hello, how are  you?"])
    }

    func testStreamingAssistantBubbleKeepsAStableIdentity() async {
        let service = StubChatService()
        service.script = [
            .token("a"), .token("b"), .token("c"),
            .done(TurnDone(status: .ok, conversationId: 1))
        ]
        let vm = makeVM(service)

        vm.send("hi")
        await wait { !vm.isTurnInFlight }

        // One assistant message, not three — chunks mutate in place so SwiftUI
        // doesn't tear down and rebuild the bubble on every token.
        let assistantMessages = vm.messages.filter { $0.assistantText != nil }
        XCTAssertEqual(assistantMessages.count, 1)
    }

    // MARK: - P3-04 · Turn serialisation

    func testRapidDoubleSendIssuesExactlyOneTurn() async {
        let service = StubChatService()
        service.script = [.done(TurnDone(status: .ok, conversationId: 1))]
        let vm = makeVM(service)

        vm.send("first")
        vm.send("second")   // must be dropped — a turn is already in flight

        await wait { !vm.isTurnInFlight }

        XCTAssertEqual(service.calls.count, 1)
        XCTAssertEqual(service.calls.first?.message, "first")
    }

    // MARK: - P3-06 · done handling

    func testConversationIdIsCapturedOnFirstTurnAndReusedAfterwards() async {
        let service = StubChatService()
        service.script = [.done(TurnDone(status: .ok, conversationId: 42))]
        let vm = makeVM(service)

        vm.send("one")
        await wait { !vm.isTurnInFlight }
        vm.send("two")
        await wait { !vm.isTurnInFlight }

        XCTAssertNil(service.calls[0].conversationId, "First turn must start a new conversation")
        XCTAssertEqual(service.calls[1].conversationId, 42)
    }

    func testGuardrailBlockedRendersDeflectionAsANormalAssistantMessage() async {
        let service = StubChatService()
        service.script = [
            .token("I can't help with that, but I can book you a consultation."),
            .done(TurnDone(status: .guardrailBlocked, conversationId: 3))
        ]
        let vm = makeVM(service)

        vm.send("something blocked")
        await wait { !vm.isTurnInFlight }

        XCTAssertEqual(
            vm.messages.compactMap(\.assistantText),
            ["I can't help with that, but I can book you a consultation."]
        )
        XCTAssertNil(vm.retryableMessage, "A guardrail block is not retryable")
    }

    func testErrorWithNoStreamedTextAddsAFallbackNotice() async {
        let service = StubChatService()
        service.script = [
            .done(TurnDone(status: .error, conversationId: 3, errorCode: .providerError))
        ]
        let vm = makeVM(service)

        vm.send("hi")
        await wait { !vm.isTurnInFlight }

        let notices = vm.messages.filter {
            if case .systemNotice = $0.kind { return true }
            return false
        }
        XCTAssertEqual(notices.count, 1)
    }

    func testErrorWithStreamedFallbackDoesNotDoubleUpTheMessage() async {
        let service = StubChatService()
        service.script = [
            .token("Sorry, I'm having trouble right now."),
            .done(TurnDone(status: .error, conversationId: 3, errorCode: .providerError))
        ]
        let vm = makeVM(service)

        vm.send("hi")
        await wait { !vm.isTurnInFlight }

        let notices = vm.messages.filter {
            if case .systemNotice = $0.kind { return true }
            return false
        }
        XCTAssertTrue(notices.isEmpty, "Server already streamed a user-facing fallback")
    }

    func testEmergencySignpostStatusIsRecorded() async {
        let service = StubChatService()
        service.script = [
            .token("Please call 112 now."),
            .done(TurnDone(
                status: .ok,
                conversationId: 5,
                conversationStatus: .emergencySignposted
            ))
        ]
        let vm = makeVM(service)

        vm.send("chest pain")
        await wait { !vm.isTurnInFlight }

        // Phase 3 records it; the banner and composer lock are P5-01/P5-02.
        XCTAssertEqual(vm.conversationStatus, .emergencySignposted)
    }

    // MARK: - P3-07 · Retry policy

    func testOnlyProviderErrorOffersRetry() async {
        for code in [ChatErrorCode.inputModeration, .redFlagKeyword, .redFlagClassifier, .outputModeration] {
            let service = StubChatService()
            service.script = [.done(TurnDone(status: .error, conversationId: 1, errorCode: code))]
            let vm = makeVM(service)

            vm.send("hi")
            await wait { !vm.isTurnInFlight }

            XCTAssertNil(vm.retryableMessage, "\(code) is terminal and must not offer retry")
        }
    }

    func testProviderErrorOffersRetryBehindACooldown() async {
        let service = StubChatService()
        service.script = [.done(TurnDone(status: .error, conversationId: 1, errorCode: .providerError))]
        let vm = makeVM(service)

        vm.send("hi")
        await wait { !vm.isTurnInFlight }

        XCTAssertEqual(vm.retryableMessage, "hi")
        // ≥30s — an open circuit breaker is indistinguishable from an ordinary
        // provider failure and resets after ~30s.
        XCTAssertGreaterThanOrEqual(vm.retryCooldownRemaining, 29)
    }

    func testRetryIsIgnoredWhileTheCooldownIsRunning() async {
        let service = StubChatService()
        service.script = [.done(TurnDone(status: .error, conversationId: 1, errorCode: .providerError))]
        let vm = makeVM(service)

        vm.send("hi")
        await wait { !vm.isTurnInFlight }

        vm.retry()
        XCTAssertEqual(service.calls.count, 1, "Retry must wait out the backoff")
    }

    func testTransportFailureKeepsReceivedTextAndOffersRetry() async {
        let service = StubChatService()
        service.script = [.token("Partial answer so far")]
        service.error = ServiceError.server(message: "Connection lost")
        let vm = makeVM(service)

        vm.send("hi")
        await wait { !vm.isTurnInFlight }

        // P5-03 — keep what arrived, never auto re-POST.
        XCTAssertEqual(vm.messages.compactMap(\.assistantText), ["Partial answer so far"])
        XCTAssertEqual(vm.retryableMessage, "hi")
        XCTAssertEqual(service.calls.count, 1)
    }

    // MARK: - P3-08 · Cards cleared on an output-phase block

    func testGuardrailBlockRemovesCardsEmittedDuringThatTurn() async {
        let payload = Data(#"{"id":1,"status":"scheduled"}"#.utf8)
        let service = StubChatService()
        service.script = [
            .toolResult(tool: "create_medication_reminder", data: payload),
            .token("Blocked deflection text"),
            .done(TurnDone(status: .guardrailBlocked, conversationId: 9))
        ]
        let vm = makeVM(service)

        vm.send("hi")
        await wait { !vm.isTurnInFlight }

        // The server discards the turn's tool calls on an output block (guide §6.2)
        // — leaving the card up would promise something never recorded.
        XCTAssertFalse(vm.messages.contains { $0.isToolCard })
    }

    func testCardsFromEarlierTurnsSurviveALaterBlock() async {
        let payload = Data(#"{"id":1,"status":"scheduled"}"#.utf8)
        let service = StubChatService()
        service.script = [
            .toolResult(tool: "create_medication_reminder", data: payload),
            .done(TurnDone(status: .ok, conversationId: 9))
        ]
        let vm = makeVM(service)

        vm.send("set a reminder")
        await wait { !vm.isTurnInFlight }
        XCTAssertTrue(vm.messages.contains { $0.isToolCard })

        service.script = [
            .token("Blocked"),
            .done(TurnDone(status: .guardrailBlocked, conversationId: 9))
        ]
        vm.send("something blocked")
        await wait { !vm.isTurnInFlight }

        // Only the blocked turn's own cards are dropped.
        XCTAssertTrue(vm.messages.contains { $0.isToolCard })
    }

    func testOkTurnKeepsItsCards() async {
        let payload = Data(#"{"id":1,"status":"scheduled"}"#.utf8)
        let service = StubChatService()
        service.script = [
            .toolResult(tool: "create_medication_reminder", data: payload),
            .done(TurnDone(status: .ok, conversationId: 9))
        ]
        let vm = makeVM(service)

        vm.send("set a reminder")
        await wait { !vm.isTurnInFlight }

        XCTAssertTrue(vm.messages.contains { $0.isToolCard })
    }

    /// The server streams the card (and disclaimer) before/after the text, but the
    /// UI reads better with the card *below* the message (e.g. booking chips under
    /// the question) and the compliance caption at the very bottom. So cards and the
    /// disclaimer are buffered and appended after the turn's text, in that order.
    func testCardAndDisclaimerRenderAfterTheTurnsText() async {
        let payload = Data(#"{"options":["GP","Specialist"]}"#.utf8)
        let service = StubChatService()
        service.script = [
            .toolResult(tool: "offer_quick_replies", data: payload),
            .token("What type of appointment would you like?"),
            .disclaimer("This is an AI assistant, not a clinician."),
            .done(TurnDone(status: .ok, conversationId: 9))
        ]
        let vm = makeVM(service)

        vm.send("Book appointment")
        await wait { !vm.isTurnInFlight }

        // Order: user message, assistant text, the card, then the disclaimer caption.
        let kinds = vm.messages.map { message -> String in
            switch message.kind {
            case .user: return "user"
            case .assistant: return "assistant"
            case .toolCard: return "card"
            case .systemNotice: return "notice"
            case .disclaimer: return "disclaimer"
            }
        }
        XCTAssertEqual(kinds, ["user", "assistant", "card", "disclaimer"])
        // The disclaimer is NOT concatenated into the assistant bubble.
        XCTAssertEqual(
            vm.messages.compactMap(\.assistantText),
            ["What type of appointment would you like?"]
        )
    }

    // MARK: - P3-10 · Teardown

    func testEndSessionDropsTheConversationSoTheNextTurnStartsFresh() async {
        let service = StubChatService()
        service.script = [.done(TurnDone(status: .ok, conversationId: 42))]
        let vm = makeVM(service)

        vm.send("one")
        await wait { !vm.isTurnInFlight }

        vm.endSession()

        vm.send("two")
        await wait { !vm.isTurnInFlight }

        XCTAssertNil(
            service.calls[1].conversationId,
            "Re-entering the screen must start a genuinely new conversation"
        )
    }

    func testEndSessionClearsInFlightState() async {
        let service = StubChatService()
        service.script = [.done(TurnDone(status: .ok, conversationId: 1))]
        let vm = makeVM(service)

        vm.send("hi")
        vm.endSession()

        XCTAssertFalse(vm.isTurnInFlight)
        XCTAssertFalse(vm.isAwaitingFirstEvent)
        XCTAssertNil(vm.retryableMessage)
    }

    // MARK: - Chips

    func testStarterChipsHideAfterTheFirstUserMessage() async {
        let service = StubChatService()
        service.script = [.done(TurnDone(status: .ok, conversationId: 1))]
        let vm = makeVM(service)

        XCTAssertTrue(vm.showsStarterChips)

        vm.send("hi")
        await wait { !vm.isTurnInFlight }

        XCTAssertFalse(vm.showsStarterChips)
    }
}
