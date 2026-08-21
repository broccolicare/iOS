//
//  ChatModels.swift
//  Broccoli
//
//  Wire models for the Health Assistant chat turn (POST /chatbot/turn).
//  Contract: docs/ios-integration-guide.md §4, §6.
//

import Foundation

// MARK: - Request (P1-02)

/// One conversational turn. `conversationId` is omitted entirely when nil —
/// the server treats an absent key as "start a new conversation" (guide §4).
public struct TurnRequest: Equatable {
    public let message: String
    public let conversationId: Int?

    public init(message: String, conversationId: Int? = nil) {
        self.message = message
        self.conversationId = conversationId
    }

    /// JSON body. Deliberately omits `conversation_id` rather than sending `null`.
    public var jsonBody: [String: Any] {
        var body: [String: Any] = ["message": message]
        if let conversationId {
            body["conversation_id"] = conversationId
        }
        return body
    }
}

// MARK: - Starters (GET /chatbot/starters)

/// One pre-first-message chip. `label` is shown; `message` is what tapping it
/// sends — kept separate so a chip can read "Book appointment" while sending a
/// fuller prompt.
public struct StarterChip: Codable, Equatable, Identifiable {
    public let label: String
    public let message: String

    /// Chips have no server id and the label is unique within a row.
    public var id: String { label }

    public init(label: String, message: String) {
        self.label = label
        self.message = message
    }
}

/// The chat screen's opening greeting and starter chips, served by the AI backend
/// so copy changes ship without an App Store release.
public struct ChatStarters: Codable, Equatable {
    public let greeting: String
    public let chips: [StarterChip]

    public init(greeting: String, chips: [StarterChip]) {
        self.greeting = greeting
        self.chips = chips
    }

    /// Shown until the fetch lands, and kept if it fails. The screen renders the
    /// instant it appears and must never open empty, so this stays in the bundle
    /// even though the server normally supplies the same copy.
    public static let bundledFallback = ChatStarters(
        greeting: "Hi! I'm your health assistant. I can help you book appointments, set medication reminders, and answer general health questions.",
        chips: [
            StarterChip(label: "Book appointment", message: "Book appointment"),
            StarterChip(label: "My appointments", message: "My appointments"),
            StarterChip(label: "My prescriptions", message: "My prescriptions"),
            StarterChip(label: "Set reminder", message: "Set reminder"),
            StarterChip(label: "Health tips", message: "Health tips")
        ]
    )
}

// MARK: - Turn outcome enums (P1-02)

/// `done.status`. Unknown strings decode to `.unknown` rather than throwing, so a
/// future server value can't break an existing client.
public enum TurnStatus: String, Codable, Equatable {
    case ok
    case error
    case guardrailBlocked = "guardrail_blocked"
    case unknown

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = TurnStatus(rawValue: raw) ?? .unknown
    }
}

/// `done.conversation_status`. `null` on a normal ongoing turn.
/// Unknown strings degrade to `.unknown`.
public enum ConversationStatus: String, Codable, Equatable {
    case completed
    case emergencySignposted = "emergency_signposted"
    case unknown

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = ConversationStatus(rawValue: raw) ?? .unknown
    }
}

// MARK: - Error codes (P1-04)

/// The five codes from guide §6.1, plus `.unknown` for forward compatibility.
public enum ChatErrorCode: String, Codable, Equatable {
    case providerError = "provider_error"
    case inputModeration = "input_moderation"
    case redFlagKeyword = "red_flag_keyword"
    case redFlagClassifier = "red_flag_classifier"
    case outputModeration = "output_moderation"
    case unknown

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = ChatErrorCode(rawValue: raw) ?? .unknown
    }

    /// `provider_error` is the ONLY retryable code — everything else is
    /// content-based, so re-sending the same text reproduces it (guide §6.1).
    ///
    /// Note: retryable does not mean *auto*-retryable. There is no idempotency key
    /// and no server-side dedupe, so a retry must always be user-initiated, with a
    /// backoff of ≥30s (an open circuit breaker is indistinguishable from an
    /// ordinary provider failure and resets after ~30s).
    public var isRetryable: Bool {
        self == .providerError
    }
}

// MARK: - done payload (P1-02)

public struct TurnDone: Decodable, Equatable {
    public let status: TurnStatus
    /// Always present — this is how a brand-new conversation's id is obtained.
    public let conversationId: Int
    public let conversationStatus: ConversationStatus?
    public let errorCode: ChatErrorCode?

    enum CodingKeys: String, CodingKey {
        case status
        case conversationId = "conversation_id"
        case conversationStatus = "conversation_status"
        case errorCode = "error_code"
    }

    public init(
        status: TurnStatus,
        conversationId: Int,
        conversationStatus: ConversationStatus? = nil,
        errorCode: ChatErrorCode? = nil
    ) {
        self.status = status
        self.conversationId = conversationId
        self.conversationStatus = conversationStatus
        self.errorCode = errorCode
    }
}

// MARK: - Stream events (P1-02)

/// One decoded SSE event from a turn.
public enum TurnEvent: Equatable {
    /// A chunk of assistant text. Concatenate in arrival order.
    case token(String)
    /// An inline card. `data` is the raw `data` object, decoded by the tool handler
    /// — the shape depends on `tool` (guide §4.1). Unknown tool names are ignored
    /// downstream rather than here, so the routing rule lives in one place.
    case toolResult(tool: String, data: Data)
    /// The turn's compliance notice, carried separately from the answer text so the
    /// UI renders it as a de-emphasised caption. Zero or one, after the text.
    case disclaimer(String)
    /// Exactly one, last.
    case done(TurnDone)
}

// MARK: - token payload

struct TokenPayload: Decodable {
    let text: String
}

/// Envelope for `event: tool_result`. `data` is kept as raw JSON so the tool
/// router can decode it into the right payload type.
struct ToolResultEnvelope: Decodable {
    let tool: String
    let data: JSONRaw

    /// Captures an arbitrary JSON value and re-encodes it to `Data` on demand.
    struct JSONRaw: Decodable {
        let raw: Data

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let value = try container.decode(AnyJSON.self)
            raw = try JSONSerialization.data(withJSONObject: value.value)
        }
    }
}

/// Minimal `Any`-JSON decoder used only to re-serialise a `tool_result` `data`
/// object without knowing its shape up front.
struct AnyJSON: Decodable {
    let value: Any

    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: AnyCodingKey.self) {
            var dict: [String: Any] = [:]
            for key in container.allKeys {
                dict[key.stringValue] = try container.decode(AnyJSON.self, forKey: key).value
            }
            value = dict
        } else if var container = try? decoder.unkeyedContainer() {
            var array: [Any] = []
            while !container.isAtEnd {
                array.append(try container.decode(AnyJSON.self).value)
            }
            value = array
        } else {
            let container = try decoder.singleValueContainer()
            if container.decodeNil() {
                value = NSNull()
            } else if let bool = try? container.decode(Bool.self) {
                value = bool
            } else if let int = try? container.decode(Int.self) {
                value = int
            } else if let double = try? container.decode(Double.self) {
                value = double
            } else if let string = try? container.decode(String.self) {
                value = string
            } else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Unsupported JSON value"
                )
            }
        }
    }

    struct AnyCodingKey: CodingKey {
        let stringValue: String
        let intValue: Int?
        init?(stringValue: String) { self.stringValue = stringValue; intValue = nil }
        init?(intValue: Int) { self.intValue = intValue; stringValue = String(intValue) }
    }
}

// MARK: - Tool payloads (P1-03)

/// `prepare_booking` (guide §4.1.1). Prefills the existing native booking flow;
/// makes no network call of its own.
///
/// ⚠️ Only `action`, `departmentId`, `isGp` and `display` are guaranteed non-null.
/// Everything else is optional and routinely absent.
public struct PrepareBookingPayload: Decodable, Equatable {
    /// `"open_booking"` today. Any other value → ignore the card entirely.
    public let action: String
    /// 1 GP · 2 specialist · 3 nutritionist · 4 blood test
    public let departmentId: Int
    public let isGp: Bool
    public let display: BookingDisplay

    public let serviceHint: String?
    /// Resolved server-side against the department's real service catalogue when
    /// it could be matched, `null` when it could not — and `null` is the normal
    /// degraded state, not an error. The rule: if non-nil use it, otherwise
    /// resolve `serviceHint` ourselves.
    public let serviceId: Int?
    /// The catalogue name of the resolved service. Non-nil exactly when
    /// `serviceId` is. Display only — never book against a name.
    public let serviceName: String?
    /// A *window*, not a commitment. Impossible windows are stripped server-side,
    /// so these are either sane or nil — keep the "form default" path.
    public let dateFrom: String?
    public let dateTo: String?
    /// `morning` / `afternoon` / `evening` / `any`
    public let timePreference: String?
    /// `HH:mm` — the slot the patient already chose **in chat**, non-nil only once
    /// they picked one from the assistant's time chips.
    ///
    /// ⚠️ Advisory like `slots`: nothing is reserved, so it must be re-checked
    /// against a live fetch before it is shown as a chosen time. It is what lets
    /// the card skip the picker and open the confirmation screen — the human
    /// checkpoint stays exactly where it was.
    public let selectedTime: String?
    /// The patient's own words. May be nil even when one was clearly given — it is
    /// dropped server-side if it reads as a clinical interpretation. A nil `reason`
    /// is normal, never an error.
    public let reason: String?
    /// Times the server found free, at most 8, already filtered to available ones
    /// and ordered by date then time.
    ///
    /// ⚠️ **Advisory, never a reservation.** Nothing holds these — the booking
    /// screen re-fetches and the slot may be gone by the time the user taps. An
    /// empty list is the ordinary degraded state (Laravel outage, unmatched
    /// service, nothing free) and must render as the plain card, not as an error.
    public let slots: [BookingSlot]

    enum CodingKeys: String, CodingKey {
        case action
        case departmentId = "department_id"
        case isGp = "is_gp"
        case display
        case serviceHint = "service_hint"
        case serviceId = "service_id"
        case serviceName = "service_name"
        case dateFrom = "date_from"
        case dateTo = "date_to"
        case timePreference = "time_preference"
        case selectedTime = "selected_time"
        case reason
        case slots
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        action = try c.decode(String.self, forKey: .action)
        departmentId = try c.decode(Int.self, forKey: .departmentId)
        isGp = try c.decode(Bool.self, forKey: .isGp)
        display = try c.decode(BookingDisplay.self, forKey: .display)
        serviceHint = try c.decodeIfPresent(String.self, forKey: .serviceHint)
        serviceId = try c.decodeIfPresent(Int.self, forKey: .serviceId)
        serviceName = try c.decodeIfPresent(String.self, forKey: .serviceName)
        dateFrom = try c.decodeIfPresent(String.self, forKey: .dateFrom)
        dateTo = try c.decodeIfPresent(String.self, forKey: .dateTo)
        timePreference = try c.decodeIfPresent(String.self, forKey: .timePreference)
        // Absent on every card the patient has not picked a time on, and on any
        // server older than the in-chat time step — same meaning either way.
        selectedTime = try c.decodeIfPresent(String.self, forKey: .selectedTime)
        reason = try c.decodeIfPresent(String.self, forKey: .reason)
        // Absent on cards emitted before slots existed, and on any future server
        // that drops the key — same meaning as an empty list, so don't fail.
        slots = try c.decodeIfPresent([BookingSlot].self, forKey: .slots) ?? []
    }

    public var isSupportedAction: Bool { action == "open_booking" }
}

/// One offered time on a booking card.
///
/// Every string here is the server's or Laravel's own rendering, passed through
/// untouched: `displayTime` is what the native booking screen shows for the same
/// slot, so chat and the form can never disagree about it. Format nothing here.
public struct BookingSlot: Decodable, Equatable, Identifiable, Hashable {
    /// `yyyy-MM-dd`, in the clinic's timezone.
    public let date: String
    /// e.g. `"Thursday 23 July"` — pre-built copy, do not re-derive from `date`.
    public let displayDate: String
    /// `morning` / `afternoon` / `evening`. Feeds `time_slot` on the booking request.
    public let period: String
    /// `HH:mm`. **This is what you book with** — it matches `TimeSlot.time` from
    /// `/api/time-slots`, which is what `BookingGlobalViewModel.selectedTimeSlot`
    /// holds.
    public let time: String
    /// e.g. `"2:00 PM"`. Display only.
    public let displayTime: String
    /// Laravel's per-slot price under dynamic pricing. A string on purpose —
    /// never parse it into a `Double` to re-format it.
    public let price: String?
    public let currency: String?

    public var id: String { "\(date)T\(time)" }

    enum CodingKeys: String, CodingKey {
        case date, period, time, price, currency
        case displayDate = "display_date"
        case displayTime = "display_time"
    }
}

public struct BookingDisplay: Decodable, Equatable {
    public let title: String
    public let cta: String
    public let subtitle: String?
}

/// `create_medication_reminder`.
///
/// ⚠️ Create-only. There is no list, cancel, update or delete endpoint — a reminder
/// created via chat cannot be viewed or cancelled through this API at all. Word any
/// confirmation UI so it does not imply in-app management.
public struct MedicationReminderPayload: Decodable, Equatable {
    public let id: Int
    /// Free text forwarded verbatim from Laravel — not an enum. Never switch
    /// exhaustively on it.
    public let status: String
}

/// `lookup_appointments` — the two lists behind My Appointments' tabs, from the
/// same `GET /bookings?type=active|past` route that screen calls. Either list
/// may be empty; both empty is a normal answer, not a failure.
public struct LookupAppointmentsPayload: Decodable, Equatable {
    public let upcoming: [ChatAppointment]
    public let history: [ChatAppointment]

    /// Absent lists decode as empty — the server sends both today, but a card
    /// missing one is still worth rendering rather than dropping entirely.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        upcoming = try container.decodeIfPresent([ChatAppointment].self, forKey: .upcoming) ?? []
        history = try container.decodeIfPresent([ChatAppointment].self, forKey: .history) ?? []
    }

    public init(upcoming: [ChatAppointment], history: [ChatAppointment]) {
        self.upcoming = upcoming
        self.history = history
    }

    enum CodingKeys: String, CodingKey {
        case upcoming, history
    }
}

public struct ChatAppointment: Decodable, Equatable {
    /// The booking id — what a tapped row fetches and opens the detail screen with.
    public let id: Int
    /// Service name (falling back to the department server-side). Free text.
    public let specialty: String
    /// `yyyy-MM-dd`, and `HH:mm(:ss)` — **kept as Laravel's own strings, in the
    /// clinic's timezone**. They are displayed as sent and never turned into a
    /// `Date` in the device's zone: Ireland observes DST, and re-interpreting a
    /// clinic-local time is how a patient gets told the wrong appointment time.
    public let date: String?
    public let time: String?
    /// Free text, not an enum.
    public let status: String
    /// Nil until a doctor is assigned.
    public let doctor: String?
    public let bookingNumber: String?

    enum CodingKeys: String, CodingKey {
        case id, specialty, date, time, status, doctor
        case bookingNumber = "booking_number"
    }
}

/// `lookup_prescriptions`. The prescriptions twin of `LookupAppointmentsPayload`:
/// the two lists behind My Prescriptions' tabs — `active` (orders still in
/// flight) and `history`.
public struct LookupPrescriptionsPayload: Decodable, Equatable {
    public let active: [ChatPrescription]
    public let history: [ChatPrescription]

    /// Absent lists decode as empty — the server sends both today, but a card
    /// missing one is still worth rendering rather than dropping entirely.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        active = try container.decodeIfPresent([ChatPrescription].self, forKey: .active) ?? []
        history = try container.decodeIfPresent([ChatPrescription].self, forKey: .history) ?? []
    }

    public init(active: [ChatPrescription], history: [ChatPrescription]) {
        self.active = active
        self.history = history
    }

    enum CodingKeys: String, CodingKey {
        case active, history
    }
}

public struct ChatPrescription: Decodable, Equatable {
    /// The prescription order id. Nothing fetches by it today — the card taps
    /// through to the My Prescriptions screen, which loads the lists itself —
    /// but it is what keeps the rows uniquely identified.
    public let id: Int
    /// Treatment name (falling back to its category server-side). Free text.
    public let treatment: String
    /// Free text, not an enum: `pending`, `doctor_assigned`, `approved`, `sent`,
    /// `completed`, `rejected`, … Rendered through `PrescriptionStatusBadge`,
    /// which already has a `default` for anything it doesn't recognise.
    public let status: String
    public let paymentStatus: String?
    /// Money as the server sent it — displayed, never parsed into a number.
    public let amount: String?
    /// `"yyyy-MM-dd HH:mm:ss"`, and `"yyyy-MM-dd"` — **kept as Laravel's own
    /// strings, in the clinic's timezone**, for the same reason as
    /// `ChatAppointment.date`: re-reading a clinic-local stamp in the device's
    /// zone is how a patient gets told the wrong date.
    public let orderedOn: String?
    public let validUntil: String?
    /// Nil until a doctor is assigned / a pharmacy is chosen.
    public let doctor: String?
    public let pharmacy: String?

    enum CodingKeys: String, CodingKey {
        case id, treatment, status, amount, doctor, pharmacy
        case paymentStatus = "payment_status"
        case orderedOn = "ordered_on"
        case validUntil = "valid_until"
    }
}

/// `offer_quick_replies` (BIC-1.5). Tappable answer chips for the question the
/// assistant is about to ask; the tapped label is sent verbatim as the next
/// `message`. The booking flow uses it for the care type ("GP" / "Specialist" /
/// "Nutritionist" / "Blood test") and time of day ("Morning" / "Afternoon" /
/// "Evening" / "Any time"). Shape: `{"options": ["…", "…"]}`.
public struct QuickRepliesPayload: Decodable, Equatable {
    /// 2–6 short labels, already trimmed/clamped server-side.
    public let options: [String]
}

// MARK: - Non-streaming error envelope (guide §6)

/// Returned as `application/json` on any non-2xx, *never* as SSE.
struct ChatErrorEnvelope: Decodable {
    let error: Payload

    struct Payload: Decodable {
        let code: String?
        let message: String?
        let correlationId: String?

        enum CodingKeys: String, CodingKey {
            case code, message
            case correlationId = "correlation_id"
        }
    }
}
