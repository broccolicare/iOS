//
//  ChatSSETests.swift
//  BroccoliTests
//
//  Covers P1-06 (SSE parser), P1-03 (tool payload decoding), P1-04 (retry policy)
//  and P1-05 (endpoint body). No network is involved in any of these.
//

import XCTest
@testable import Broccoli

final class ChatSSETests: XCTestCase {

    // MARK: - Helpers

    /// Drives the parser over a line sequence exactly as `SSEClient` does:
    /// consume every line, then flush once at stream end.
    private func parse(_ lines: [String]) -> [TurnEvent] {
        let parser = SSEParser()
        var events: [TurnEvent] = []
        for line in lines {
            if let event = parser.consume(line: line) { events.append(event) }
        }
        if let event = parser.finish() { events.append(event) }
        return events
    }

    // MARK: - P1-06 · SSE parser

    func testParsesOrderedTokenStreamEndingInDone() {
        let events = parse([
            "event: token",
            #"data: {"text": "You"}"#,
            "",
            "event: token",
            #"data: {"text": " should"}"#,
            "",
            "event: done",
            #"data: {"status": "ok", "conversation_id": 12, "conversation_status": null, "error_code": null}"#,
            "",
        ])

        XCTAssertEqual(events.count, 3)
        XCTAssertEqual(events[0], .token("You"))
        XCTAssertEqual(events[1], .token(" should"))

        guard case .done(let done) = events[2] else { return XCTFail("expected done") }
        XCTAssertEqual(done.status, .ok)
        XCTAssertEqual(done.conversationId, 12)
        XCTAssertNil(done.conversationStatus)
        XCTAssertNil(done.errorCode)
    }

    /// Regression: the live `aiapp` server streams event/data pairs back-to-back
    /// with NO blank line between them (non-spec, but this is what it sends). The
    /// parser must still dispatch each event on the next `event:` boundary rather
    /// than merging the whole turn into one undecodable buffer.
    func testParsesConsecutiveEventsWithoutBlankSeparators() {
        let events = parse([
            "event: token",
            #"data: {"text": "Could you provide a few details?"}"#,
            "event: token",
            #"data: {"text": "\n\nThis is an AI assistant, not a clinician."}"#,
            "event: done",
            #"data: {"status": "ok", "conversation_id": 7, "conversation_status": null, "error_code": null}"#,
        ])

        XCTAssertEqual(events.count, 3)
        XCTAssertEqual(events[0], .token("Could you provide a few details?"))
        XCTAssertEqual(events[1], .token("\n\nThis is an AI assistant, not a clinician."))

        guard case .done(let done) = events[2] else { return XCTFail("expected done") }
        XCTAssertEqual(done.status, .ok)
        XCTAssertEqual(done.conversationId, 7)
    }

    func testToolResultArrivesBeforeTokensAndKeepsRawData() {
        let events = parse([
            "event: tool_result",
            #"data: {"tool": "lookup_appointments", "data": {"scope": "upcoming", "upcoming": [{"id": 1, "specialty": "GP", "date": "2026-08-01", "time": "09:00", "status": "confirmed"}]}}"#,
            "",
            "event: token",
            #"data: {"text": "Here they are"}"#,
            "",
        ])

        XCTAssertEqual(events.count, 2)
        guard case .toolResult(let tool, let data) = events[0] else {
            return XCTFail("expected tool_result first")
        }
        XCTAssertEqual(tool, "lookup_appointments")

        let payload = try? JSONDecoder().decode(LookupAppointmentsPayload.self, from: data)
        XCTAssertEqual(payload?.scope, .upcoming)
        XCTAssertEqual(payload?.appointments.count, 1)
        XCTAssertEqual(payload?.appointments.first?.specialty, "GP")
        XCTAssertEqual(payload?.history.count, 0)
        XCTAssertEqual(events[1], .token("Here they are"))
    }

    func testDisclaimerEventParsesToItsOwnCase() {
        let events = parse([
            "event: token",
            #"data: {"text": "What type of appointment would you like?"}"#,
            "event: disclaimer",
            #"data: {"text": "This is an AI assistant, not a clinician."}"#,
            "event: done",
            #"data: {"status": "ok", "conversation_id": 7, "conversation_status": null, "error_code": null}"#,
        ])

        XCTAssertEqual(events.count, 3)
        XCTAssertEqual(events[0], .token("What type of appointment would you like?"))
        XCTAssertEqual(events[1], .disclaimer("This is an AI assistant, not a clinician."))
        guard case .done = events[2] else { return XCTFail("expected done") }
    }

    func testUnknownEventNamesAreIgnored() {
        let events = parse([
            "event: some_future_event",
            #"data: {"whatever": true}"#,
            "",
            "event: token",
            #"data: {"text": "hi"}"#,
            "",
        ])

        XCTAssertEqual(events, [.token("hi")])
    }

    func testMultipleDataLinesJoinWithNewline() {
        // Per the SSE spec, consecutive `data:` lines are joined with "\n" — and a
        // continuation line must itself carry the `data:` prefix. Split here at a
        // point where the injected newline is JSON whitespace, since a literal
        // newline inside a JSON string would be invalid JSON.
        let events = parse([
            "event: token",
            #"data: {"text":"#,
            #"data:  "split payload"}"#,
            "",
        ])

        XCTAssertEqual(events, [.token("split payload")])
    }

    func testContinuationLineWithoutDataPrefixIsIgnored() {
        // A bare continuation line is an unrecognised field per the spec, so the
        // payload stays truncated and no event is emitted.
        let events = parse([
            "event: token",
            #"data: {"text": "line one"#,
            #"line two"}"#,
            "",
        ])

        XCTAssertEqual(events, [])
    }

    func testFlushesFinalEventWithoutTrailingBlankLine() {
        let events = parse([
            "event: done",
            #"data: {"status": "ok", "conversation_id": 7, "conversation_status": null, "error_code": null}"#,
            // no trailing blank line — the stream just ends
        ])

        XCTAssertEqual(events.count, 1)
        guard case .done(let done) = events[0] else { return XCTFail("expected done") }
        XCTAssertEqual(done.conversationId, 7)
    }

    func testCommentLinesAreIgnored() {
        let events = parse([
            ": this is a keepalive comment",
            "event: token",
            ": another comment mid-event",
            #"data: {"text": "hi"}"#,
            "",
        ])

        XCTAssertEqual(events, [.token("hi")])
    }

    func testTruncatedStreamEmitsCompleteEventsOnly() {
        // The first event completed; the second was cut off mid-payload.
        let events = parse([
            "event: token",
            #"data: {"text": "partial reply"}"#,
            "",
            "event: token",
            #"data: {"text": "cut o"#,
        ])

        XCTAssertEqual(events, [.token("partial reply")])
    }

    func testFieldValueParsingToleratesMissingSpaceAndPreservesOthers() {
        // "data:{...}" (no space) must parse, and only ONE leading space is stripped.
        let events = parse([
            "event:token",
            #"data:{"text": "  padded"}"#,
            "",
        ])

        XCTAssertEqual(events, [.token("  padded")])
    }

    func testMalformedJSONDoesNotEmitAnEventOrBreakTheStream() {
        let events = parse([
            "event: token",
            "data: {not json at all",
            "",
            "event: token",
            #"data: {"text": "recovered"}"#,
            "",
        ])

        XCTAssertEqual(events, [.token("recovered")])
    }

    // MARK: - P1-02 · done decoding & unknown-value tolerance

    func testGuardrailBlockedDoneDecodes() {
        let json = #"""
        {"status": "guardrail_blocked", "conversation_id": 3,
         "conversation_status": "emergency_signposted", "error_code": "red_flag_keyword"}
        """#
        let done = try? JSONDecoder().decode(TurnDone.self, from: Data(json.utf8))

        XCTAssertEqual(done?.status, .guardrailBlocked)
        XCTAssertEqual(done?.conversationStatus, .emergencySignposted)
        XCTAssertEqual(done?.errorCode, .redFlagKeyword)
    }

    func testUnknownStatusStringsDegradeInsteadOfThrowing() {
        let json = #"""
        {"status": "something_new", "conversation_id": 9,
         "conversation_status": "also_new", "error_code": "brand_new_code"}
        """#
        let done = try? JSONDecoder().decode(TurnDone.self, from: Data(json.utf8))

        XCTAssertNotNil(done, "unknown enum values must not throw")
        XCTAssertEqual(done?.status, .unknown)
        XCTAssertEqual(done?.conversationStatus, .unknown)
        XCTAssertEqual(done?.errorCode, .unknown)
        XCTAssertEqual(done?.conversationId, 9)
    }

    // MARK: - P1-04 · retry policy

    func testOnlyProviderErrorIsRetryable() {
        let all: [ChatErrorCode] = [
            .providerError, .inputModeration, .redFlagKeyword,
            .redFlagClassifier, .outputModeration, .unknown,
        ]
        let retryable = all.filter(\.isRetryable)

        XCTAssertEqual(retryable, [.providerError],
                       "provider_error must be the only retryable code (guide §6.1)")
    }

    // MARK: - P1-03 · tool payload decoding

    func testPrepareBookingDecodesWithEveryOptionalAbsent() {
        let json = #"""
        {"action": "open_booking", "department_id": 4, "is_gp": false,
         "display": {"title": "Blood test", "cta": "Choose a time"}}
        """#
        let payload = try? JSONDecoder().decode(PrepareBookingPayload.self, from: Data(json.utf8))

        XCTAssertNotNil(payload, "all-optionals-absent must decode")
        XCTAssertEqual(payload?.departmentId, 4)
        XCTAssertEqual(payload?.isGp, false)
        XCTAssertEqual(payload?.display.title, "Blood test")
        XCTAssertNil(payload?.display.subtitle)
        XCTAssertNil(payload?.serviceHint)
        XCTAssertNil(payload?.serviceId)
        XCTAssertNil(payload?.dateFrom)
        XCTAssertNil(payload?.reason)
        XCTAssertNil(payload?.serviceName)
        XCTAssertEqual(payload?.slots, [], "an absent `slots` key means no times, not a decode failure")
        XCTAssertEqual(payload?.isSupportedAction, true)
    }

    func testPrepareBookingDecodesWithEveryFieldPresent() {
        let json = #"""
        {"action": "open_booking", "department_id": 4, "is_gp": false,
         "service_hint": "full blood count", "service_id": 12,
         "service_name": "Full Blood Count",
         "date_from": "2026-07-27", "date_to": "2026-08-03",
         "time_preference": "morning", "reason": "Follow-up bloods requested by GP",
         "slots": [{"date": "2026-07-27", "display_date": "Monday 27 July",
                    "period": "morning", "time": "09:00", "display_time": "9:00 AM",
                    "price": "45.00", "currency": "EUR"}],
         "display": {"title": "Blood test", "subtitle": "Mornings, week of 27 July",
                     "cta": "Choose a time"}}
        """#
        let payload = try? JSONDecoder().decode(PrepareBookingPayload.self, from: Data(json.utf8))

        XCTAssertEqual(payload?.serviceHint, "full blood count")
        XCTAssertEqual(payload?.serviceId, 12, "the server now resolves the service itself")
        XCTAssertEqual(payload?.serviceName, "Full Blood Count")
        XCTAssertEqual(payload?.dateFrom, "2026-07-27")
        XCTAssertEqual(payload?.timePreference, "morning")
        XCTAssertEqual(payload?.reason, "Follow-up bloods requested by GP")
        XCTAssertEqual(payload?.display.subtitle, "Mornings, week of 27 July")
        XCTAssertEqual(payload?.slots.count, 1)
        XCTAssertEqual(payload?.slots.first?.time, "09:00", "`time` is what the form books with")
        XCTAssertEqual(payload?.slots.first?.displayTime, "9:00 AM")
        XCTAssertEqual(payload?.slots.first?.price, "45.00", "price stays a string, never a Double")
    }

    /// `service_id` null with a hint present is the ordinary degraded card — the
    /// server's own match failed, or Laravel was unreachable. It must still decode
    /// and still be actionable via the hint.
    func testPrepareBookingDecodesUnresolvedService() {
        let json = #"""
        {"action": "open_booking", "department_id": 2, "is_gp": false,
         "service_hint": "dermatology", "service_id": null, "service_name": null,
         "slots": [],
         "display": {"title": "Specialist appointment", "cta": "Choose a time"}}
        """#
        let payload = try? JSONDecoder().decode(PrepareBookingPayload.self, from: Data(json.utf8))

        XCTAssertNotNil(payload)
        XCTAssertNil(payload?.serviceId)
        XCTAssertNil(payload?.serviceName)
        XCTAssertEqual(payload?.slots, [], "no slots is the normal degraded state, not an error")
        XCTAssertEqual(payload?.serviceHint, "dermatology")
    }

    func testPrepareBookingTolerantOfUnknownKeys() {
        let json = #"""
        {"action": "open_booking", "department_id": 1, "is_gp": true,
         "display": {"title": "GP visit", "cta": "Book", "future_key": 1},
         "a_field_added_later": {"nested": [1, 2, 3]}}
        """#
        XCTAssertNotNil(try? JSONDecoder().decode(PrepareBookingPayload.self, from: Data(json.utf8)))
    }

    func testUnsupportedBookingActionIsFlagged() {
        let json = #"""
        {"action": "open_something_else", "department_id": 1, "is_gp": true,
         "display": {"title": "x", "cta": "y"}}
        """#
        let payload = try? JSONDecoder().decode(PrepareBookingPayload.self, from: Data(json.utf8))

        XCTAssertEqual(payload?.isSupportedAction, false, "an unknown action means ignore the card")
    }

    func testEmptyAppointmentListDecodes() {
        let json = #"{"upcoming": [], "history": []}"#
        let payload = try? JSONDecoder().decode(LookupAppointmentsPayload.self, from: Data(json.utf8))

        XCTAssertEqual(payload?.upcoming.count, 0)
        XCTAssertEqual(payload?.history.count, 0)
    }

    func testMedicationReminderDecodesWithFreeTextStatus() {
        let json = #"{"id": 88, "status": "whatever_laravel_sends"}"#
        let payload = try? JSONDecoder().decode(MedicationReminderPayload.self, from: Data(json.utf8))

        XCTAssertEqual(payload?.id, 88)
        XCTAssertEqual(payload?.status, "whatever_laravel_sends")
    }

    // MARK: - BIC-1.5 · offer_quick_replies (booking chips)

    func testQuickRepliesToolResultParsesAndDecodesOptions() {
        // The booking flow's care-type step: a tool_result carrying tappable labels.
        let events = parse([
            "event: tool_result",
            #"data: {"tool": "offer_quick_replies", "data": {"options": ["GP", "Specialist", "Nutritionist", "Blood test"]}}"#,
            "event: token",
            #"data: {"text": "Which type of appointment do you need?"}"#,
        ])

        XCTAssertEqual(events.count, 2)
        guard case .toolResult(let tool, let data) = events[0] else {
            return XCTFail("expected tool_result first")
        }
        XCTAssertEqual(tool, "offer_quick_replies")

        let payload = try? JSONDecoder().decode(QuickRepliesPayload.self, from: data)
        XCTAssertEqual(payload?.options, ["GP", "Specialist", "Nutritionist", "Blood test"])
        XCTAssertEqual(events[1], .token("Which type of appointment do you need?"))
    }

    func testQuickRepliesPayloadDecodesTimeOfDayOptions() {
        let json = #"{"options": ["Morning", "Afternoon", "Evening", "Any time"]}"#
        let payload = try? JSONDecoder().decode(QuickRepliesPayload.self, from: Data(json.utf8))

        XCTAssertEqual(payload?.options, ["Morning", "Afternoon", "Evening", "Any time"])
    }

    // MARK: - P1-05 · endpoint

    func testTurnRequestOmitsConversationIdWhenNil() {
        let body = ChatEndpoint.chatbotTurn(TurnRequest(message: "hello")).body

        XCTAssertEqual(body?["message"] as? String, "hello")
        XCTAssertFalse(body?.keys.contains("conversation_id") ?? true,
                       "the key must be absent entirely, not null")
    }

    func testTurnRequestIncludesConversationIdWhenPresent() {
        let endpoint = ChatEndpoint.chatbotTurn(TurnRequest(message: "hi", conversationId: 12))

        XCTAssertEqual(endpoint.path, "/chatbot/turn")
        XCTAssertEqual(endpoint.method, .POST)
        XCTAssertEqual(endpoint.body?["conversation_id"] as? Int, 12)
        XCTAssertEqual(endpoint.headers?["Accept"], "text/event-stream")
    }
}
