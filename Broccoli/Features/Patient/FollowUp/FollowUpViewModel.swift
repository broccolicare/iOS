//
//  FollowUpViewModel.swift
//  Broccoli
//
//  The post-appointment follow-up check-in loop.
//

import Foundation
import Combine

/// Drives one booking's follow-up check-in.
///
/// Structurally close to `IntakeViewModel` — same SSE stream, same one-turn-in-flight
/// rule, same retry policy, same resume-across-launches behaviour — because a
/// follow-up is triggered by a notification the patient may not open right away.
@MainActor
final class FollowUpViewModel: ObservableObject {

    // MARK: - Published state

    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var isTurnInFlight = false
    @Published private(set) var isAwaitingFirstEvent = false
    @Published private(set) var isTakingLonger = false
    @Published private(set) var retryableMessage: String?
    @Published private(set) var retryCooldownRemaining: Int = 0

    /// Terminal. Set from a `done` carrying `conversation_status: "completed"`, or
    /// on open if this booking's follow-up finished in an earlier session.
    @Published private(set) var isComplete = false

    /// The booking isn't the caller's (404) or the backend can't verify it (503).
    @Published private(set) var startupError: String?

    var hasStarted: Bool { !messages.isEmpty }

    var canSend: Bool { !isTurnInFlight && !isComplete && startupError == nil }

    // MARK: - Dependencies

    private let followUpService: FollowUpServiceProtocol
    private let sessionStore: FollowUpSessionStore
    let appointmentId: Int

    // MARK: - Private state

    private var conversationId: Int?

    private var turnTask: Task<Void, Never>?
    private var escalationTask: Task<Void, Never>?
    private var cooldownTask: Task<Void, Never>?

    private let retryCooldown = 30
    private let escalationDelay: Duration = .seconds(15)

    // MARK: - Init

    init(
        appointmentId: Int,
        followUpService: FollowUpServiceProtocol = FollowUpService(),
        sessionStore: FollowUpSessionStore = FollowUpSessionStore()
    ) {
        self.appointmentId = appointmentId
        self.followUpService = followUpService
        self.sessionStore = sessionStore
        self.conversationId = sessionStore.conversationId(forAppointment: appointmentId)
        self.isComplete = sessionStore.isCompleted(appointmentId: appointmentId)
    }

    // MARK: - Sending

    func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, canSend else { return }

        messages.append(.user(trimmed))
        clearRetry()
        startTurn(trimmed)
    }

    /// Opens the check-in. There is no server-side "start" — the first turn *is*
    /// the start — so this sends an opener on the patient's behalf.
    func begin() {
        guard !hasStarted, canSend else { return }
        startTurn(Self.openingMessage)
    }

    func retry() {
        guard let message = retryableMessage, canSend, retryCooldownRemaining == 0 else { return }
        clearRetry()
        startTurn(message)
    }

    // MARK: - Teardown

    /// Cancels any in-flight stream. Deliberately keeps `conversationId` so
    /// re-entering resumes rather than starting a second follow-up.
    func endSession() {
        turnTask?.cancel()
        turnTask = nil
        escalationTask?.cancel()
        escalationTask = nil
        cooldownTask?.cancel()
        cooldownTask = nil

        isTurnInFlight = false
        isAwaitingFirstEvent = false
        isTakingLonger = false
        retryableMessage = nil
        retryCooldownRemaining = 0
    }

    // MARK: - Turn loop

    private func startTurn(_ text: String) {
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
        var assistantId: UUID?
        var pendingCards: [ChatToolCard] = []
        var pendingDisclaimer: String?

        do {
            let stream = followUpService.streamTurn(
                message: text,
                conversationId: conversationId,
                appointmentId: conversationId == nil ? appointmentId : nil
            )

            for try await event in stream {
                try Task.checkCancellation()
                firstEventArrived()

                switch event {
                case .token(let chunk):
                    appendToken(chunk, to: &assistantId)

                case .toolResult(let tool, let data):
                    pendingCards.append(ChatToolCard(tool: tool, data: data))

                case .disclaimer(let text):
                    pendingDisclaimer = text

                case .done(let done):
                    handleDone(
                        done,
                        sentMessage: text,
                        assistantId: assistantId,
                        cards: pendingCards,
                        disclaimer: pendingDisclaimer
                    )
                }
            }
        } catch is CancellationError {
            // Teardown — the user is gone. Say nothing.
        } catch {
            handleFailure(error, sentMessage: text)
        }

        finishTurn()
    }

    private func handleDone(
        _ done: TurnDone,
        sentMessage: String,
        assistantId: UUID?,
        cards: [ChatToolCard],
        disclaimer: String?
    ) {
        if conversationId != done.conversationId {
            conversationId = done.conversationId
            sessionStore.save(conversationId: done.conversationId, forAppointment: appointmentId)
        }

        if done.conversationStatus == .completed {
            sessionStore.markCompleted(appointmentId: appointmentId)
            isComplete = true
        }

        switch done.status {
        case .ok:
            appendCards(cards)
            appendDisclaimer(disclaimer)

        case .guardrailBlocked:
            if done.conversationStatus == .emergencySignposted {
                isComplete = true
            }

        case .error, .unknown:
            appendCards(cards)
            appendDisclaimer(disclaimer)
            if !hasText(assistantId) {
                messages.append(.systemNotice(Self.fallbackErrorText))
            }
            if done.errorCode?.isRetryable == true {
                offerRetry(for: sentMessage)
            }
        }
    }

    private func handleFailure(_ error: Error, sentMessage: String) {
        if let serviceError = error as? ServiceError, let blocking = Self.startupMessage(for: serviceError) {
            startupError = blocking
            if case .user? = messages.last?.kind { messages.removeLast() }
            return
        }

        let text = (error as? ServiceError)?.errorDescription ?? Self.fallbackErrorText
        messages.append(.systemNotice(text))
        offerRetry(for: sentMessage)
    }

    /// Maps the two rejections that make the screen unusable, or nil for an
    /// ordinary failure the patient can retry through.
    private static func startupMessage(for error: ServiceError) -> String? {
        switch error {
        case .server(let message):
            if message.localizedCaseInsensitiveContains("appointment not found") {
                return "We couldn't find this appointment. Please go back and try again."
            }
            if message.localizedCaseInsensitiveContains("try again shortly") {
                return "We can't start your follow-up right now. Please try again in a few minutes."
            }
            return nil
        case .validation:
            return "Something went wrong starting your follow-up. Please try again later."
        default:
            return nil
        }
    }

    private func finishTurn() {
        isTurnInFlight = false
        isAwaitingFirstEvent = false
        isTakingLonger = false
        escalationTask?.cancel()
        escalationTask = nil
        turnTask = nil
    }

    // MARK: - Events

    private func appendToken(_ chunk: String, to assistantId: inout UUID?) {
        if let id = assistantId,
           let index = messages.firstIndex(where: { $0.id == id }),
           case .assistant(let existing) = messages[index].kind {
            messages[index].kind = .assistant(existing + chunk)
        } else {
            let message = ChatMessage.assistant(chunk)
            messages.append(message)
            assistantId = message.id
        }
    }

    private func appendCards(_ cards: [ChatToolCard]) {
        for card in cards {
            messages.append(ChatMessage(kind: .toolCard(card)))
        }
    }

    private func appendDisclaimer(_ text: String?) {
        guard let text, !text.isEmpty else { return }
        messages.append(ChatMessage(kind: .disclaimer(text)))
    }

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

    private static let openingMessage = "I'm here for my follow-up check-in."

    private static let fallbackErrorText =
        "Sorry, something went wrong and I couldn't finish that. Please try again."
}
