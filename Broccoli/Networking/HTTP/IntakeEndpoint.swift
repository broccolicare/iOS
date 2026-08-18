//
//  IntakeEndpoint.swift
//  Broccoli
//
//  Contract: docs/ios-integration-guide.md §5.
//

import Foundation

/// The pre-appointment intake turn. Same SSE protocol as `ChatEndpoint`, kept
/// separate because the request carries an appointment and the two flows have
/// different lifecycles — the chat is ephemeral, the intake completes.
public enum IntakeEndpoint: Endpoint {
    case turn(IntakeTurnRequest)

    public var path: String {
        switch self {
        case .turn:
            return "/intake/turn"
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .turn:
            return .POST
        }
    }

    public var headers: [String: String]? {
        switch self {
        case .turn:
            return ["Accept": "text/event-stream"]
        }
    }

    public var body: [String: Any]? {
        switch self {
        case .turn(let request):
            return request.jsonBody
        }
    }
}
