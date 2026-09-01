//
//  IntakeViewModel.swift
//  Broccoli
//
//  The pre-appointment questionnaire loop.
//  Contract: docs/ios-integration-guide.md §5.
//

import Foundation
import Combine

/// Drives one appointment's intake questionnaire.
///
/// Structurally close to `ChatViewModel` — same SSE stream, same one-turn-in-flight
/// rule, same retry policy — and deliberately a separate type, because the three
/// places it differs are the three places a shared implementation would be wrong:
///
/// 1. **It is tied to an appointment.** `appointmentId` goes out on the first turn
///    only; on resume the server keeps the appointment the intake started against.
/// 2. **It completes.** `conversation_status: "completed"` is terminal: the input
///    box goes away for good and the summary is written server-side. Sending
///    another message after that would start a *second* intake on the same
///    appointment, whose summary would silently supersede the first.
/// 3. **It resumes.** The conversation id is persisted per appointment
///    (`IntakeSessionStore`) rather than dying with the screen. Chat's ephemerality
///    is a privacy feature; here it would cost the clinician the record.
@MainActor
final class IntakeViewModel: ObservableObject {

    // MARK: - Published state

    @Published private(set) var messages: [ChatMessage] = []

    /// True from send until `done` or an error. The composer is disabled throughout
    /// — there is no server-side concurrency lock, and two turns on one
    /// `conversation_id` interleave and corrupt the transcript (guide §4.3).
    @Published private(set) var isTurnInFlight = false

    /// Send → first event. Drives the typing indicator.
    @Published private(set) var isAwaitingFirstEvent = false

    /// Set after `escalationDelay` of silence so a long turn doesn't look stalled.
    @Published private(set) var isTakingLonger = false

    /// The message to re-send when the user taps retry, or nil if the last failure
    /// was terminal. Only ever set for `provider_error` and transport failures.
    @Published private(set) var retryableMessage: String?

    /// Seconds until retry becomes available. Non-zero means "show the button,
    /// disabled, counting down".
    @Published private(set) var retryCooldownRemaining: Int = 0

    /// Terminal. Set from a `done` carrying `conversation_status: "completed"`, or
    /// on open if this appointment's intake finished in an earlier session. Once
    /// true the composer never comes back.
    @Published private(set) var isComplete = false

    /// A start-time failure the patient cannot type their way out of — the
    /// appointment isn't theirs (404) or the backend can't verify it (503). The
    /// screen shows this instead of a composer.
    @Published private(set) var startupError: String?

    /// True until the first message is sent, so the screen can show the intro card
    /// and a "Start" button rather than an empty transcript.
    var hasStarted: Bool { !messages.isEmpty }

    var canSend: Bool { !isTurnInFlight && !isComplete && startupError == nil }

    // MARK: - Dependencies

    private let intakeService: IntakeServiceProtocol
    private let sessionStore: IntakeSessionStore
    let appointmentId: Int

    // MARK: - Private state

    /// nil → the next turn starts a new intake. Restored from `sessionStore` at
    /// init, so re-entering the screen resumes rather than restarting.
    private var conversationId: Int?

    private var turnTask: Task<Void, Never>?
    private var escalationTask: Task<Void, Never>?
    private var cooldownTask: Task<Void, Never>?

    /// An open circuit breaker is indistinguishable from an ordinary provider
    /// failure from here, and it resets after ~30s — retrying sooner just trips it
    /// again (guide §6.1).
    private let retryCooldown = 30
    private let escalationDelay: Duration = .seconds(15)

    // MARK: - Init

    init(
        appointmentId: Int,
        intakeService: IntakeServiceProtocol = IntakeService(),
        sessionStore: IntakeSessionStore = IntakeSessionStore()
    ) {
        self.appointmentId = appointmentId
        self.intakeService = intakeService
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

    /// Opens the questionnaire. The server has no "start" endpoint — the first turn
    /// *is* the start — so this sends an opener on the patient's behalf rather than
    /// making them type something to begin.
    func begin() {
        guard !hasStarted, canSend else { return }
        startTurn(Self.openingMessage)
    }

    /// Always user-initiated. There is no idempotency key and no server-side
    /// dedupe, so an automatic retry can double-post a turn the server completed.
    func retry() {
        guard let message = retryableMessage, canSend, retryCooldownRemaining == 0 else { return }
        clearRetry()
        startTurn(message)
    }

    // MARK: - Teardown

    /// Cancels any in-flight stream. **Does not drop `conversationId`** — that is
    /// the point of the intake session store. Call from the view's `onDisappear`.
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
        // Cards stream before the question text (P1-1.5) but read better below it,
        // so they are buffered and appended on `done` — and simply dropped if the
        // turn was blocked.
        var pendingCards: [ChatToolCard] = []
        var pendingDisclaimer: String?

        do {
            let stream = intakeService.streamTurn(
                message: text,
                conversationId: conversationId,
                // Only meaningful on the first turn; the server ignores it after.
                appointmentId: conversationId == nil ? appointmentId : nil
            )

            for try await event in stream {
                try Task.checkCancellation()
                firstEventArrived()

                switch event {
                case .token(let chunk):
                    appendToken(chunk, to: &assistantId)

                case .toolResult(let tool, let data):
                    // `advance_intake`'s card is chrome for a progress indicator
                    // the patient never sees — drop it rather than rendering it as
                    // a normal card. Everything else renders as a normal card.
                    if tool != intakeProgressToolName {
                        pendingCards.append(ChatToolCard(tool: tool, data: data))
                    }

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
        // The only place a new intake's id is learned — and it is persisted
        // immediately, before anything else can fail, so an interrupted session
        // still resumes instead of starting a duplicate intake.
        if conversationId != done.conversationId {
            conversationId = done.conversationId
            sessionStore.save(conversationId: done.conversationId, forAppointment: appointmentId)
        }

        if done.conversationStatus == .completed {
            // Terminal: the summary is written server-side and the composer must
            // not come back. Recorded before rendering so a crash between the two
            // still leaves the intake closed rather than restartable.
            sessionStore.markCompleted(appointmentId: appointmentId)
            isComplete = true
        }

        switch done.status {
        case .ok:
            appendCards(cards)
            appendDisclaimer(disclaimer)

        case .guardrailBlocked:
            // The deflection text streamed like any other reply and reads as one.
            // An output-phase block discards the turn's tool calls server-side
            // (guide §6.2), so the buffered cards are dropped with it.
            //
            // `conversation_status: "emergency_signposted"` also lands here: the
            // intake stopped on a red flag and is never summarised. Leaving the
            // composer live would let the patient keep answering a questionnaire
            // that no longer exists, so it is treated as terminal too.
            if done.conversationStatus == .emergencySignposted {
                isComplete = true
            }

        case .error, .unknown:
            appendCards(cards)
            appendDisclaimer(disclaimer)
            // The server streams a user-facing fallback before `done` on most
            // errors. Only add our own line when THIS turn produced none.
            if !hasText(assistantId) {
                messages.append(.systemNotice(Self.fallbackErrorText))
            }
            if done.errorCode?.isRetryable == true {
                offerRetry(for: sentMessage)
            }
        }
    }

    /// A dropped connection, a timeout, or a start-time rejection.
    ///
    /// The start-time cases are separated out because they are not conversational
    /// failures: a 404 means this appointment is not the caller's, a 503 means the
    /// backend cannot verify that it is. Neither is fixed by re-typing, and both
    /// must stop the screen before the patient answers a single question.
    private func handleFailure(_ error: Error, sentMessage: String) {
        if let serviceError = error as? ServiceError, let blocking = Self.startupMessage(for: serviceError) {
            startupError = blocking
            // Drop the optimistic user bubble — nothing was recorded server-side.
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
            // 404 — not this patient's appointment. The server deliberately does
            // not distinguish "no such appointment" from "not yours", and neither
            // does this copy.
            if message.localizedCaseInsensitiveContains("appointment not found") {
                return "We couldn't find this appointment. Please go back and try again."
            }
            // 503 — the appointment check is an authorisation check, so the server
            // fails closed rather than guessing. It is genuinely temporary.
            if message.localizedCaseInsensitiveContains("try again shortly") {
                return "We can't start your questionnaire right now. Please try again in a few minutes."
            }
            return nil
        case .validation:
            // 422 on a start means the request was malformed — a client bug, not
            // something the patient can act on.
            return "Something went wrong starting your questionnaire. Please try again later."
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

    /// Appends verbatim. No trimming or normalisation — the server chunks mid-word,
    /// so any cleanup here corrupts the reply.
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

    /// The socket stays silent for the whole turn — up to ~120s — then delivers
    /// everything at once. Without this the indicator looks frozen.
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

    /// Sent as the first `message` to open the questionnaire. The server needs a
    /// non-empty message (1–8000 chars) to run a turn, and the assistant replies
    /// with the first core question.
    private static let openingMessage = "I'm ready to start my pre-appointment questions."

    private static let fallbackErrorText =
        "Sorry, something went wrong and I couldn't finish that. Please try again."
}
