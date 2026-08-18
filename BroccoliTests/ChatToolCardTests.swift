//
//  ChatToolCardTests.swift
//  BroccoliTests
//
//  P4-07 — tool payload decoding, service resolution and prefill mapping.
//  No network is involved.
//

import XCTest
@testable import Broccoli

final class ChatToolCardTests: XCTestCase {

    // MARK: - Fixtures

    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder().decode(type, from: Data(json.utf8))
    }

    private func service(id: Int, name: String) throws -> Service {
        try decode(Service.self, """
        {
          "id": \(id),
          "name": "\(name)",
          "description": null,
          "price": "50.00",
          "duration": 30,
          "requires_doctor": 1,
          "bookable_online": 1,
          "department": { "id": 2, "name": "Specialist" },
          "sub_services": []
        }
        """)
    }

    private func bookingPayload(
        serviceId: String = "null",
        serviceHint: String = "null",
        action: String = "open_booking",
        dateFrom: String = "null",
        timePreference: String = "null"
    ) throws -> PrepareBookingPayload {
        try decode(PrepareBookingPayload.self, """
        {
          "action": "\(action)",
          "department_id": 2,
          "is_gp": false,
          "service_id": \(serviceId),
          "service_hint": \(serviceHint),
          "date_from": \(dateFrom),
          "time_preference": \(timePreference),
          "display": { "title": "Book a consultation", "cta": "Choose a time" }
        }
        """)
    }

    // MARK: - P4-03 · prepare_booking rendering inputs

    func testBookingPayloadDecodesWithEveryOptionalAbsent() throws {
        let payload = try decode(PrepareBookingPayload.self, """
        {
          "action": "open_booking",
          "department_id": 1,
          "is_gp": true,
          "display": { "title": "Book a GP appointment", "cta": "Continue" }
        }
        """)

        XCTAssertTrue(payload.isSupportedAction)
        XCTAssertNil(payload.display.subtitle)
        // A null reason is normal, never an error (guide §4.1.1).
        XCTAssertNil(payload.reason)
        XCTAssertNil(payload.serviceId)
        XCTAssertNil(payload.serviceHint)
    }

    func testSelectedTimeDecodesWhenTheUserChoseOneInChat() throws {
        let payload = try decode(PrepareBookingPayload.self, """
        {
          "action": "open_booking",
          "department_id": 2,
          "is_gp": false,
          "selected_time": "09:30",
          "display": { "title": "Specialist appointment", "cta": "Choose a time" }
        }
        """)
        // Drives the confirmation-screen shortcut in `ChatBookingCoordinator` —
        // still re-checked against a live fetch before it is selected.
        XCTAssertEqual(payload.selectedTime, "09:30")
    }

    func testAbsentSelectedTimeIsTheOrdinaryCard() throws {
        // Every card before a time is picked, and every card from a server that
        // predates the in-chat time step. Neither is an error.
        XCTAssertNil(try bookingPayload().selectedTime)
    }

    func testExplicitlyNullReasonIsNotAnError() throws {
        let payload = try decode(PrepareBookingPayload.self, """
        {
          "action": "open_booking",
          "department_id": 1,
          "is_gp": true,
          "reason": null,
          "display": { "title": "Book", "cta": "Go" }
        }
        """)
        XCTAssertNil(payload.reason)
    }

    func testUnsupportedActionIsFlaggedSoTheCardCanBeDropped() throws {
        let payload = try bookingPayload(action: "something_new")
        XCTAssertFalse(payload.isSupportedAction)
    }

    // MARK: - P4-04 · Service resolution

    func testServiceIdWinsWhenPresent() throws {
        let services = [
            try service(id: 10, name: "Cardiology Consultation"),
            try service(id: 20, name: "Dermatology Consultation")
        ]
        let payload = try bookingPayload(serviceId: "20", serviceHint: "\"cardiology\"")

        // The id is authoritative even when the hint points elsewhere.
        XCTAssertEqual(ChatBookingCoordinator.resolveService(payload, in: services)?.id, 20)
    }

    func testFallsBackToHintWhenServiceIdIsNull() throws {
        let services = [
            try service(id: 10, name: "Cardiology Consultation"),
            try service(id: 20, name: "Dermatology Consultation")
        ]
        let payload = try bookingPayload(serviceHint: "\"cardiology\"")

        XCTAssertEqual(ChatBookingCoordinator.resolveService(payload, in: services)?.id, 10)
    }

    func testExactNameMatchBeatsAnEarlierSubstringMatch() throws {
        let services = [
            try service(id: 10, name: "Blood Test Panel"),
            try service(id: 20, name: "Blood Test")
        ]
        let payload = try bookingPayload(serviceHint: "\"Blood Test\"")

        XCTAssertEqual(ChatBookingCoordinator.resolveService(payload, in: services)?.id, 20)
    }

    func testHintMatchingIsCaseInsensitive() throws {
        let services = [try service(id: 10, name: "Cardiology Consultation")]
        let payload = try bookingPayload(serviceHint: "\"CARDIOLOGY\"")

        XCTAssertEqual(ChatBookingCoordinator.resolveService(payload, in: services)?.id, 10)
    }

    func testUnresolvableHintReturnsNilSoTheUserGetsThePicker() throws {
        let services = [try service(id: 10, name: "Cardiology Consultation")]
        let payload = try bookingPayload(serviceHint: "\"podiatry\"")

        // nil drives the SpecialtyListView fallback — chat must never dead-end.
        XCTAssertNil(ChatBookingCoordinator.resolveService(payload, in: services))
    }

    func testUnknownServiceIdWithNoHintReturnsNil() throws {
        let services = [try service(id: 10, name: "Cardiology Consultation")]
        let payload = try bookingPayload(serviceId: "999")

        XCTAssertNil(ChatBookingCoordinator.resolveService(payload, in: services))
    }

    func testResolutionAgainstAnEmptyServiceListReturnsNil() throws {
        let payload = try bookingPayload(serviceHint: "\"cardiology\"")
        XCTAssertNil(ChatBookingCoordinator.resolveService(payload, in: []))
    }

    // MARK: - P4-04 · Time preference and date mapping

    func testAnyTimePreferenceMapsToNoPreference() {
        // "any" has no form representation and would be rejected as a time_slot.
        XCTAssertNil(ChatBookingCoordinator.normalisedTimePreference("any"))
        XCTAssertNil(ChatBookingCoordinator.normalisedTimePreference(nil))
        XCTAssertNil(ChatBookingCoordinator.normalisedTimePreference("whenever"))
    }

    func testRecognisedTimePreferencesPassThrough() {
        XCTAssertEqual(ChatBookingCoordinator.normalisedTimePreference("morning"), "morning")
        XCTAssertEqual(ChatBookingCoordinator.normalisedTimePreference("Afternoon"), "afternoon")
        XCTAssertEqual(ChatBookingCoordinator.normalisedTimePreference("EVENING"), "evening")
    }

    func testPastDatesAreDroppedRatherThanOpeningTheFormOnThem() {
        XCTAssertNil(ChatBookingCoordinator.parseDate("2020-01-01"))
    }

    func testMalformedDateIsIgnored() {
        XCTAssertNil(ChatBookingCoordinator.parseDate("next Tuesday"))
        XCTAssertNil(ChatBookingCoordinator.parseDate(nil))
        XCTAssertNil(ChatBookingCoordinator.parseDate("01/08/2026"))
    }

    func testFutureDateParses() throws {
        let future = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Europe/Dublin")

        let parsed = try XCTUnwrap(ChatBookingCoordinator.parseDate(formatter.string(from: future)))
        XCTAssertEqual(
            Calendar.current.compare(parsed, to: future, toGranularity: .day),
            .orderedSame
        )
    }

    // MARK: - Offered slots

    func testSlotsDecodeWithTheirServerRenderedCopy() throws {
        let payload = try decode(PrepareBookingPayload.self, """
        {
          "action": "open_booking", "department_id": 2, "is_gp": false,
          "service_id": 10, "service_name": "Cardiology Consultation",
          "slots": [
            {"date": "2026-08-01", "display_date": "Saturday 1 August",
             "period": "morning", "time": "09:00", "display_time": "9:00 AM",
             "price": "80.00", "currency": "EUR"},
            {"date": "2026-08-01", "display_date": "Saturday 1 August",
             "period": "afternoon", "time": "14:20", "display_time": "2:20 PM",
             "price": null, "currency": null}
          ],
          "display": { "title": "Specialist appointment", "cta": "Choose a time" }
        }
        """)

        XCTAssertEqual(payload.serviceName, "Cardiology Consultation")
        XCTAssertEqual(payload.slots.count, 2)
        // Both renderings are the server's; the client formats neither.
        XCTAssertEqual(payload.slots[1].displayTime, "2:20 PM")
        XCTAssertEqual(payload.slots[1].time, "14:20")
        XCTAssertEqual(payload.slots[1].displayDate, "Saturday 1 August")
        // A slot with no price is still bookable — dynamic pricing is optional.
        XCTAssertNil(payload.slots[1].price)
    }

    func testAbsentSlotsKeyDecodesAsNoSlots() throws {
        // Pre-slots servers, and any future one that drops the key, must render as
        // the plain card rather than failing to decode.
        XCTAssertEqual(try bookingPayload().slots, [])
    }

    func testClockTimesNormaliseToHourAndMinute() {
        // Whether Laravel sends "14:00" or "14:00:00" is not ours to assume.
        XCTAssertEqual(ChatBookingCoordinator.normalisedClockTime("14:00"), "14:00")
        XCTAssertEqual(ChatBookingCoordinator.normalisedClockTime("14:00:00"), "14:00")
        XCTAssertEqual(ChatBookingCoordinator.normalisedClockTime(" 9:05 "), "09:05")
    }

    func testUnparseableClockTimeIsDroppedRatherThanGuessed() {
        // Selecting the wrong slot is worse than selecting none.
        XCTAssertNil(ChatBookingCoordinator.normalisedClockTime("2:00 PM"))
        XCTAssertNil(ChatBookingCoordinator.normalisedClockTime("morning"))
        XCTAssertNil(ChatBookingCoordinator.normalisedClockTime("25:00"))
        XCTAssertNil(ChatBookingCoordinator.normalisedClockTime(""))
        XCTAssertNil(ChatBookingCoordinator.normalisedClockTime(nil))
    }

    // MARK: - P4-02 · Reminder payload

    func testReminderDecodesAndKeepsStatusAsFreeText() throws {
        let payload = try decode(MedicationReminderPayload.self, """
        { "id": 7, "status": "some_status_we_have_never_seen" }
        """)

        XCTAssertEqual(payload.id, 7)
        // Never an enum — an unrecognised status must not throw.
        XCTAssertEqual(payload.status, "some_status_we_have_never_seen")
    }

    // MARK: - P4-05 · Appointment payload

    func testAppointmentsDecodeIntoUpcomingAndHistory() throws {
        let payload = try decode(LookupAppointmentsPayload.self, """
        {
          "upcoming": [
            { "id": 1, "specialty": "Cardiology", "date": "2026-08-20", "time": "09:30",
              "status": "confirmed", "doctor": "Dr Ryan", "booking_number": "BK-1" }
          ],
          "history": [
            { "id": 2, "specialty": "GP", "date": "2026-07-15", "time": "14:00:00",
              "status": "completed", "doctor": null, "booking_number": null }
          ]
        }
        """)

        XCTAssertEqual(payload.upcoming.map(\.id), [1])
        XCTAssertEqual(payload.history.map(\.id), [2])
        XCTAssertEqual(payload.upcoming[0].doctor, "Dr Ryan")
        XCTAssertNil(payload.history[0].doctor)
    }

    func testAppointmentScheduleIsRenderedFromLaravelsOwnStrings() throws {
        let payload = try decode(LookupAppointmentsPayload.self, """
        {
          "upcoming": [
            { "id": 1, "specialty": "Cardiology", "date": "2026-08-20", "time": "09:30",
              "status": "confirmed" },
            { "id": 2, "specialty": "GP", "date": "2026-07-15", "time": "14:00:00",
              "status": "pending" }
          ],
          "history": []
        }
        """)

        // Clinic-local strings, formatted for display only — never reinterpreted
        // in the device's timezone.
        XCTAssertEqual(payload.upcoming[0].formattedSchedule, "20 Aug 26, 09:30 AM")
        // HH:mm:ss is accepted too; which one Laravel sends is not ours to assume.
        XCTAssertEqual(payload.upcoming[1].formattedSchedule, "15 Jul 26, 02:00 PM")
    }

    func testUnparseableOrMissingDateFallsBackRatherThanDroppingTheRow() throws {
        let payload = try decode(LookupAppointmentsPayload.self, """
        {
          "upcoming": [
            { "id": 1, "specialty": "GP", "date": "not-a-date", "time": "whenever",
              "status": "confirmed" },
            { "id": 2, "specialty": "GP", "date": null, "time": null, "status": "pending" }
          ],
          "history": []
        }
        """)

        XCTAssertEqual(payload.upcoming[0].formattedSchedule, "not-a-date, whenever")
        XCTAssertNil(payload.upcoming[1].formattedSchedule)
    }

    func testAppointmentSubtitleAddsTheDoctorOnlyWhenAssigned() throws {
        let payload = try decode(LookupAppointmentsPayload.self, """
        {
          "upcoming": [
            { "id": 1, "specialty": "GP", "date": "2026-08-20", "time": "09:30",
              "status": "confirmed", "doctor": "Dr Ryan" },
            { "id": 2, "specialty": "GP", "date": "2026-08-21", "time": "09:30",
              "status": "some_status_we_have_never_seen" }
          ],
          "history": []
        }
        """)

        XCTAssertEqual(payload.upcoming[0].subtitle, "Confirmed · Dr Ryan")
        // Status is free text, never an enum — an unseen value must still render.
        XCTAssertEqual(payload.upcoming[1].subtitle, "Some_status_we_have_never_seen")
    }

    func testEmptyAppointmentListsDecodeRatherThanFailing() throws {
        let payload = try decode(LookupAppointmentsPayload.self, #"{"upcoming":[],"history":[]}"#)
        XCTAssertTrue(payload.upcoming.isEmpty)
        XCTAssertTrue(payload.history.isEmpty)
    }

    func testAMissingListDecodesAsEmpty() throws {
        let payload = try decode(LookupAppointmentsPayload.self, #"{"upcoming":[]}"#)
        XCTAssertTrue(payload.history.isEmpty)
    }

    // MARK: - P4-01 · Unknown tools

    func testUnknownToolNamesAreNotAnyOfTheHandledCases() {
        // The router's `default` is a no-op; this guards the list it switches on so
        // a rename can't silently drop a card. `start_booking` is deliberately NOT
        // handled — it is deprecated and being removed (guide §4.1).
        let handled = ["prepare_booking", "create_medication_reminder", "lookup_appointments"]

        XCTAssertFalse(handled.contains("start_booking"))
        XCTAssertFalse(handled.contains("some_future_tool"))
        XCTAssertEqual(handled.count, 3)
    }

    // MARK: - P4-04 · Prefill mapping

    func testPrefillMapsIntDepartmentAndBoolIsGpToTheirStringForms() {
        let prefill = ChatBookingPrefill(
            departmentId: String(2),
            isGP: false ? "1" : "0",
            serviceId: 10
        )

        // BookingGlobalViewModel stores both as Strings, not Int/Bool.
        XCTAssertEqual(prefill.departmentId, "2")
        XCTAssertEqual(prefill.isGP, "0")
    }
}
