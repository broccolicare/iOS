//
//  ChatViewModel.swift
//  Broccoli
//
//  P3-01 / P3-03 / P3-04 / P3-06 / P3-07 / P3-08 / P3-10 — the conversation loop.
//  Contract: docs/ios-integration-guide.md §4, §6.
//

import Foundation
import Combine

/// Drives one Health Assistant conversation.
///
/// ⚠️ **Feature-scoped by design — do not promote this to a `GlobalViewModel`**
/// (plan §4.1). The view owns it as a `@StateObject`, so the VM dies with the
/// screen and takes `conversationId` with it. That makes the chat's ephemerality
/// *structural* rather than a rule someone has to remember: there is no shared
/// instance that could outlive the screen, and no persistence layer to leak the
/// conversation into. Re-entering the screen is always a genuinely new thread.
///
/// `conversationId` is never written to disk, per the definition of done.
@MainActor
final class ChatViewModel: ObservableObject {

    // MARK: - Published state

    @Published private(set) var messages: [ChatMessage] = []

    /// True from send until `done` or an error. The composer is disabled throughout
    /// (P3-04) — there is no server-side concurrency lock, and two turns on one
    /// `conversation_id` interleave and corrupt the transcript (guide §4.3).
    @Published private(set) var isTurnInFlight = false

    /// Send → first event. Drives the typing indicator (P3-05).
    @Published private(set) var isAwaitingFirstEvent = false

    /// Set after `escalationDelay` of silence so a long turn doesn't look stalled.
    @Published private(set) var isTakingLonger = false

    /// The message to re-send when the user taps retry, or nil if the last failure
    /// was terminal. Only ever set for `provider_error` and transport failures.
    @Published private(set) var retryableMessage: String?

    /// Seconds until retry becomes available. Non-zero means "show the button,
    /// disabled, counting down" (P3-07).
    @Published private(set) var retryCooldownRemaining: Int = 0

    /// Last `conversation_status` seen on a `done`. Surfaced for Phase 5 (the
    /// emergency banner and composer lock, P5-01/P5-02, both gated on clinical
    /// sign-off). Phase 3 stores it and does nothing else with it.
    @Published private(set) var conversationStatus: ConversationStatus?

    /// The chips are a pre-first-message affordance only.
    var showsStarterChips: Bool { messages.isEmpty && !isTurnInFlight }

    var canSend: Bool { !isTurnInFlight }

    // MARK: - Dependencies

    private let chatService: ChatServiceProtocol

    // MARK: - Private state

    /// In-memory only, for the lifetime of this VM. nil → the next turn starts a new
    /// conversation server-side.
    private var conversationId: Int?

    private var turnTask: Task<Void, Never>?
    private var escalationTask: Task<Void, Never>?
    private var cooldownTask: Task<Void, Never>?

    /// Retry backoff. An open circuit breaker is indistinguishable from an ordinary
    /// provider failure from the client's side, and it resets after ~30s — retrying
    /// sooner just trips it again (guide §6.1).
    private let retryCooldown = 30
    private let escalationDelay: Duration = .seconds(15)

    // MARK: - Init

    init(chatService: ChatServiceProtocol) {
        self.chatService = chatService
    }

    // MARK: - Sending (P3-03)

    func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        #if DEBUG
        // A tap that "does nothing" almost always dies on this guard: either the
        // text trimmed to empty, or a previous turn is still in flight. Log both
        // sides so a silent no-op is never invisible again.
        print("📨 [ChatViewModel] send(\"\(trimmed.prefix(40))\") isTurnInFlight=\(isTurnInFlight) canSend=\(canSend)")
        #endif

        guard !trimmed.isEmpty, canSend else {
            #if DEBUG
            print("⏹️ [ChatViewModel] send ignored — empty=\(trimmed.isEmpty) canSend=\(canSend)")
            #endif
            return
        }

        messages.append(.user(trimmed))
        clearRetry()
        startTurn(trimmed)
    }

    /// P3-07 — always user-initiated. There is no idempotency key and no server-side
    /// dedupe, so an automatic retry can double-post a turn the server actually
    /// completed. Never call this from a failure path.
    func retry() {
        guard let message = retryableMessage, canSend, retryCooldownRemaining == 0 else { return }
        clearRetry()
        startTurn(message)
    }

    // MARK: - Teardown (P3-10)

    /// Cancels any in-flight stream and drops the conversation. Call from the view's
    /// `onDisappear`.
    func endSession() {
        turnTask?.cancel()
        turnTask = nil
        escalationTask?.cancel()
        escalationTask = nil
        cooldownTask?.cancel()
        cooldownTask = nil

        conversationId = nil
        conversationStatus = nil
        isTurnInFlight = false
        isAwaitingFirstEvent = false
        isTakingLonger = false
        retryableMessage = nil
        retryCooldownRemaining = 0
    }

    // MARK: - Turn loop

    private func startTurn(_ text: String) {
        #if DEBUG
        print("🚀 [ChatViewModel] startTurn — conversationId=\(conversationId.map(String.init) ?? "nil")")
        #endif
        isTurnInFlight = true
        isAwaitingFirstEvent = true
        isTakingLonger = false
        startEscalationTimer()

        turnTask = Task { [weak self] in
            guard let self else { return }
            await self.runTurn(text)
        }
    }

    private func runTurn(_ text: String) async {
        // Identity of the assistant bubble for this turn. Created lazily on the
        // first token so a turn that only emits a card doesn't leave an empty
        // bubble behind.
        var assistantId: UUID?
        // Cards emitted during THIS turn, so P3-08 can drop them if the turn ends
        // blocked. Scoped to the turn — cards from earlier turns are unaffected.
        var cardIds: [UUID] = []

        do {
            for try await event in chatService.streamTurn(message: text, conversationId: conversationId) {
                try Task.checkCancellation()
                firstEventArrived()

                switch event {
                case .token(let chunk):
                    appendToken(chunk, to: &assistantId)

                case .toolResult(let tool, let data):
                    let card = ChatToolCard(tool: tool, data: data)
                    let message = ChatMessage(kind: .toolCard(card))
                    messages.append(message)
                    // The MESSAGE id, not the card's — `messages` is keyed by the
                    // former, and P3-08 removes entries from `messages`.
                    cardIds.append(message.id)
                    // A card ends the current bubble: any text after it belongs to a
                    // new one, so it renders below the card rather than jumping above.
                    assistantId = nil

                case .done(let done):
                    handleDone(done, sentMessage: text, assistantId: assistantId, cardIds: cardIds)
                }
            }
        } catch is CancellationError {
            // Teardown or a new screen — the user is gone. Say nothing.
        } catch {
            handleTransportFailure(error, sentMessage: text)
        }

        finishTurn()
    }

    /// P3-06 — the three `done` statuses.
    private func handleDone(
        _ done: TurnDone,
        sentMessage: String,
        assistantId: UUID?,
        cardIds: [UUID]
    ) {
        // Always, on every status: this is the only place a new conversation's id
        // is ever supplied (guide §4).
        conversationId = done.conversationId
        conversationStatus = done.conversationStatus

        switch done.status {
        case .ok:
            // The streamed text is already in the bubble — nothing to finalise.
            break

        case .guardrailBlocked:
            // The deflection text was streamed like any other reply and reads as
            // one, so it stays as a normal assistant message with no error styling.
            //
            // P3-08 — an output-phase block discards the turn's tool calls
            // server-side (guide §6.2). Leaving the cards up would offer the user a
            // booking or reminder the server never actually recorded.
            removeCards(cardIds)

        case .error, .unknown:
            // The server streams a user-facing fallback before `done` on most
            // errors. Only add our own line when THIS turn didn't produce one —
            // checking the whole transcript would wrongly suppress the notice
            // whenever an earlier turn had succeeded.
            if !hasText(assistantId) {
                messages.append(.systemNotice(Self.fallbackErrorText))
            }
            // Only `provider_error` is worth re-sending — every other code is
            // content-based, so the same text reproduces it exactly (guide §6.1).
            if done.errorCode?.isRetryable == true {
                offerRetry(for: sentMessage)
            }
        }
    }

    /// A dropped connection, a 401, a timeout. Keep whatever text arrived — a
    /// half-received answer is still useful — and offer a manual retry (P5-03).
    private func handleTransportFailure(_ error: Error, sentMessage: String) {
        #if DEBUG
        print("❌ [ChatViewModel] turn failed: \(error)")
        #endif

        let text = (error as? ServiceError)?.errorDescription ?? Self.fallbackErrorText
        messages.append(.systemNotice(text))
        offerRetry(for: sentMessage)
    }

    private func finishTurn() {
        isTurnInFlight = false
        isAwaitingFirstEvent = false
        isTakingLonger = false
        escalationTask?.cancel()
        escalationTask = nil
        turnTask = nil
    }

    // MARK: - Token accumulation (P3-03)

    /// Appends verbatim. No trimming, no separator, no normalisation — the server
    /// chunks mid-word and mid-whitespace, so any cleanup here corrupts the reply.
    private func appendToken(_ chunk: String, to assistantId: inout UUID?) {
        if let id = assistantId,
           let index = messages.firstIndex(where: { $0.id == id }),
           case .assistant(let existing) = messages[index].kind {
            // Mutate in place, preserving the element's id (see ChatMessage).
            messages[index].kind = .assistant(existing + chunk)
        } else {
            let message = ChatMessage.assistant(chunk)
            messages.append(message)
            assistantId = message.id
        }
    }

    private func removeCards(_ ids: [UUID]) {
        guard !ids.isEmpty else { return }
        let doomed = Set(ids)
        messages.removeAll { doomed.contains($0.id) && $0.isToolCard }
    }

    /// Did this turn's assistant bubble receive any text?
    private func hasText(_ assistantId: UUID?) -> Bool {
        guard let assistantId,
              let message = messages.first(where: { $0.id == assistantId })
        else { return false }
        return message.assistantText?.isEmpty == false
    }

    // MARK: - Indicator & retry timers

    private func firstEventArrived() {
        guard isAwaitingFirstEvent else { return }
        isAwaitingFirstEvent = false
        isTakingLonger = false
        escalationTask?.cancel()
        escalationTask = nil
    }

    /// The socket stays silent for the whole turn — up to ~120s — then delivers
    /// everything at once. Without this the indicator looks frozen (P3-05).
    private func startEscalationTimer() {
        escalationTask?.cancel()
        escalationTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: self.escalationDelay)
            guard !Task.isCancelled else { return }
            if self.isAwaitingFirstEvent {
                self.isTakingLonger = true
            }
        }
    }

    private func offerRetry(for message: String) {
        retryableMessage = message
        retryCooldownRemaining = retryCooldown

        cooldownTask?.cancel()
        cooldownTask = Task { [weak self] in
            while let self, self.retryCooldownRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                self.retryCooldownRemaining -= 1
            }
        }
    }

    private func clearRetry() {
        cooldownTask?.cancel()
        cooldownTask = nil
        retryableMessage = nil
        retryCooldownRemaining = 0
    }

    // MARK: - Copy

    private static let fallbackErrorText =
        "Sorry, something went wrong and I couldn't finish that. Please try again."
}
