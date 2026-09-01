//
//  IntakeViewModelTests.swift
//  BroccoliTests
//
//  Covers the three ways intake deliberately differs from the chat: it is tied to
//  an appointment, it completes, and it resumes. No network — the service is
//  stubbed and the session store runs against a scratch UserDefaults suite.
//

import XCTest
@testable import Broccoli

@MainActor
final class IntakeViewModelTests: XCTestCase {

    // MARK: - Stubs

    /// Replays a scripted event sequence, recording exactly what it was asked for.
    private final class StubIntakeService: IntakeServiceProtocol, @unchecked Sendable {
        var script: [TurnEvent] = []
        var error: Error?
        /// Every (message, conversationId, appointmentId) triple, in order.
        private(set) var calls: [(message: String, conversationId: Int?, appointmentId: Int?)] = []

        func streamTurn(
            message: String,
            conversationId: Int?,
            appointmentId: Int?
        ) -> AsyncThrowingStream<TurnEvent, Error> {
            calls.append((message, conversationId, appointmentId))
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

    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        // A private suite per test — the store is intentionally persistent, so
        // sharing `.standard` would leak state between tests and into the device.
        suiteName = "IntakeViewModelTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    private func makeVM(
        _ service: StubIntakeService,
        appointmentId: Int = 501
    ) -> IntakeViewModel {
        IntakeViewModel(
            appointmentId: appointmentId,
            intakeService: service,
            sessionStore: IntakeSessionStore(defaults: defaults)
        )
    }

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

    private func progressCard(position: Int, total: Int = 16) -> TurnEvent {
        .toolResult(
            tool: intakeProgressToolName,
            data: Data(
                #"{"question_id":"onset","outcome":"answered","position":\#(position),"total":\#(total)}"#.utf8
            )
        )
    }

    // MARK: - The appointment link

    func testTheFirstTurnSendsTheAppointmentAndNoConversationId() async {
        let service = StubIntakeService()
        service.script = [.token("Hi"), .done(TurnDone(status: .ok, conversationId: 34))]
        let vm = makeVM(service, appointmentId: 501)

        vm.begin()
        await wait { !vm.isTurnInFlight }

        XCTAssertEqual(service.calls.count, 1)
        XCTAssertNil(service.calls[0].conversationId)
        XCTAssertEqual(service.calls[0].appointmentId, 501)
    }

    func testResumingSendsTheConversationIdAndDropsTheAppointment() async {
        let service = StubIntakeService()
        service.script = [.token("Hi"), .done(TurnDone(status: .ok, conversationId: 34))]
        let vm = makeVM(service)

        vm.begin()
        await wait { !vm.isTurnInFlight }

        service.script = [.token("Next"), .done(TurnDone(status: .ok, conversationId: 34))]
        vm.send("It started on Tuesday.")
        await wait { service.calls.count == 2 }

        // The server ignores `appointment_id` on resume, and sending it anyway
        // would imply the client could re-point an intake at another appointment.
        XCTAssertEqual(service.calls[1].conversationId, 34)
        XCTAssertNil(service.calls[1].appointmentId)
    }

    // MARK: - Resumption across screens

    func testAnInterruptedIntakeResumesInsteadOfStartingASecondOne() async {
        let service = StubIntakeService()
        service.script = [.token("Hi"), .done(TurnDone(status: .ok, conversationId: 34))]
        let first = makeVM(service)

        first.begin()
        await wait { !first.isTurnInFlight }
        first.endSession()

        // A fresh VM is what re-entering the screen produces.
        let second = makeVM(service)
        service.script = [.token("Welcome back"), .done(TurnDone(status: .ok, conversationId: 34))]
        second.send("carrying on")
        await wait { service.calls.count == 2 }

        XCTAssertEqual(service.calls[1].conversationId, 34, "must resume, not restart")
    }

    func testTeardownKeepsTheConversationUnlikeTheChat() async {
        let service = StubIntakeService()
        service.script = [.token("Hi"), .done(TurnDone(status: .ok, conversationId: 34))]
        let vm = makeVM(service)

        vm.begin()
        await wait { !vm.isTurnInFlight }
        vm.endSession()

        service.script = [.token("Still here"), .done(TurnDone(status: .ok, conversationId: 34))]
        vm.send("again")
        await wait { service.calls.count == 2 }

        XCTAssertEqual(service.calls[1].conversationId, 34)
    }

    // MARK: - Completion is terminal

    func testCompletionClosesTheComposerForGood() async {
        let service = StubIntakeService()
        service.script = [
            .token("Thank you."),
            .done(TurnDone(status: .ok, conversationId: 34, conversationStatus: .completed))
        ]
        let vm = makeVM(service)

        vm.begin()
        await wait { vm.isComplete }

        XCTAssertFalse(vm.canSend)
        vm.send("one more thing")
        XCTAssertEqual(service.calls.count, 1, "a completed intake must not send another turn")
    }

    func testACompletedIntakeStaysCompletedOnReturn() async {
        let service = StubIntakeService()
        service.script = [
            .token("Thank you."),
            .done(TurnDone(status: .ok, conversationId: 34, conversationStatus: .completed))
        ]
        let vm = makeVM(service)

        vm.begin()
        await wait { vm.isComplete }

        // Re-opening must not offer to start again: a second summary would
        // silently supersede the one the clinician already has.
        let reopened = makeVM(service)
        XCTAssertTrue(reopened.isComplete)
        XCTAssertFalse(reopened.canSend)
    }

    func testAnEmergencySignpostAlsoEndsTheQuestionnaire() async {
        let service = StubIntakeService()
        service.script = [
            .token("Please seek urgent medical help."),
            .done(TurnDone(
                status: .guardrailBlocked,
                conversationId: 34,
                conversationStatus: .emergencySignposted,
                errorCode: .redFlagKeyword
            ))
        ]
        let vm = makeVM(service)

        vm.begin()
        await wait { vm.isComplete }

        // The intake stopped on a red flag and is never summarised — leaving the
        // composer live would let the patient answer a questionnaire that no
        // longer exists.
        XCTAssertFalse(vm.canSend)
    }

    // MARK: - Progress

    func testProgressCardsAreDroppedRatherThanRenderedAsCards() async {
        // There is no on-screen progress indicator (the questionnaire's length
        // isn't something the patient is shown), so `advance_intake`'s card is
        // simply discarded rather than appearing in the transcript.
        let service = StubIntakeService()
        service.script = [
            progressCard(position: 2),
            .token("Has it got better or worse?"),
            .done(TurnDone(status: .ok, conversationId: 34))
        ]
        let vm = makeVM(service)

        vm.begin()
        await wait { !vm.isTurnInFlight }

        XCTAssertFalse(vm.messages.contains { $0.isToolCard }, "the card must not reach the transcript")
    }

    // MARK: - Start-time failures

    func testAnUnownedAppointmentBlocksTheScreenRatherThanTheTurn() async {
        let service = StubIntakeService()
        service.error = ServiceError.server(message: "Appointment not found.")
        let vm = makeVM(service)

        vm.begin()
        await wait { vm.startupError != nil }

        // Not a conversational failure: no retry is offered, and no orphan bubble
        // is left behind for a turn the server never recorded.
        XCTAssertFalse(vm.canSend)
        XCTAssertNil(vm.retryableMessage)
    }

    func testAnUnavailableBackendBlocksTheScreenWithTemporaryCopy() async {
        let service = StubIntakeService()
        service.error = ServiceError.server(
            message: "Cannot start intake right now. Please try again shortly."
        )
        let vm = makeVM(service)

        vm.begin()
        await wait { vm.startupError != nil }

        XCTAssertTrue(vm.startupError?.contains("few minutes") == true)
    }

    func testAnOrdinaryProviderErrorOffersRetryInsteadOfBlocking() async {
        let service = StubIntakeService()
        service.script = [
            .done(TurnDone(status: .error, conversationId: 34, errorCode: .providerError))
        ]
        let vm = makeVM(service)

        vm.begin()
        await wait { !vm.isTurnInFlight }

        XCTAssertNil(vm.startupError)
        XCTAssertNotNil(vm.retryableMessage)
        XCTAssertEqual(vm.retryCooldownRemaining, 30)
    }

    // MARK: - Turn serialisation

    func testASecondSendIsIgnoredWhileATurnIsInFlight() async {
        let service = StubIntakeService()
        service.script = [.token("…"), .done(TurnDone(status: .ok, conversationId: 34))]
        let vm = makeVM(service)

        vm.begin()
        vm.send("impatient")

        await wait { !vm.isTurnInFlight }
        XCTAssertEqual(service.calls.count, 1)
    }

    // MARK: - Request body

    func testTheRequestOmitsConversationIdRatherThanSendingNull() {
        let start = IntakeTurnRequest(message: "hi", conversationId: nil, appointmentId: 501)
        XCTAssertNil(start.jsonBody["conversation_id"])
        XCTAssertEqual(start.jsonBody["appointment_id"] as? Int, 501)

        let resume = IntakeTurnRequest(message: "hi", conversationId: 34, appointmentId: 501)
        XCTAssertEqual(resume.jsonBody["conversation_id"] as? Int, 34)
        XCTAssertNil(resume.jsonBody["appointment_id"])
    }

    // MARK: - Session store

    func testTheSessionStoreScopesConversationsToTheirAppointment() {
        let store = IntakeSessionStore(defaults: defaults)
        store.save(conversationId: 34, forAppointment: 501)
        store.save(conversationId: 35, forAppointment: 502)

        XCTAssertEqual(store.conversationId(forAppointment: 501), 34)
        XCTAssertEqual(store.conversationId(forAppointment: 502), 35)
        XCTAssertNil(store.conversationId(forAppointment: 503))
    }

    func testSignOutForgetsEveryRememberedIntake() {
        let store = IntakeSessionStore(defaults: defaults)
        store.save(conversationId: 34, forAppointment: 501)
        store.markCompleted(appointmentId: 501)

        store.clearAll()

        // A conversation id belongs to the patient who owns the appointment; the
        // next account must never inherit one.
        XCTAssertNil(store.conversationId(forAppointment: 501))
        XCTAssertFalse(store.isCompleted(appointmentId: 501))
    }
}
