//
//  FollowUpEndpoint.swift
//  Broccoli
//
//  Post-appointment follow-up check-in. Same SSE protocol as Intake/Chat, kept
//  separate because it is scoped to a booking and completes server-side.
//

import Foundation

public enum FollowUpEndpoint: Endpoint {
    case turn(FollowUpTurnRequest)

    public var path: String {
        switch self {
        case .turn:
            return "/followup/turn"
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
