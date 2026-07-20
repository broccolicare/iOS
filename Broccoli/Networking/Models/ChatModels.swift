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
    /// Key is always present but the value is always `null` today. The rule to
    /// write now: if non-nil use it, otherwise resolve `serviceHint`.
    public let serviceId: Int?
    /// A *window*, not a commitment. Impossible windows are stripped server-side,
    /// so these are either sane or nil — keep the "form default" path.
    public let dateFrom: String?
    public let dateTo: String?
    /// `morning` / `afternoon` / `evening` / `any`
    public let timePreference: String?
    /// The patient's own words. May be nil even when one was clearly given — it is
    /// dropped server-side if it reads as a clinical interpretation. A nil `reason`
    /// is normal, never an error.
    public let reason: String?

    enum CodingKeys: String, CodingKey {
        case action
        case departmentId = "department_id"
        case isGp = "is_gp"
        case display
        case serviceHint = "service_hint"
        case serviceId = "service_id"
        case dateFrom = "date_from"
        case dateTo = "date_to"
        case timePreference = "time_preference"
        case reason
    }

    public var isSupportedAction: Bool { action == "open_booking" }
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

/// `lookup_appointments`. The list may be empty.
public struct LookupAppointmentsPayload: Decodable, Equatable {
    public let appointments: [ChatAppointment]
}

public struct ChatAppointment: Decodable, Equatable {
    public let id: Int
    /// Free text, not an enum.
    public let specialty: String
    /// ⚠️ No timezone normalisation — **do not display this**. There is nothing in
    /// the payload indicating its zone and Ireland observes DST, so rendering it
    /// risks showing a wrong appointment time. Decoded only for completeness.
    public let scheduledAt: String?
    /// Free text, not an enum.
    public let status: String

    enum CodingKeys: String, CodingKey {
        case id, specialty, status
        case scheduledAt = "scheduled_at"
    }
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
