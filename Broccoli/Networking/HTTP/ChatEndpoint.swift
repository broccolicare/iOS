//
//  ChatEndpoint.swift
//  Broccoli
//
//  Contract: docs/ios-integration-guide.md §4.
//

import Foundation

public enum ChatEndpoint: Endpoint {
    case chatbotTurn(TurnRequest)
    /// Greeting + starter chips for the pre-first-message screen. Plain JSON, not SSE.
    case starters

    public var path: String {
        switch self {
        case .chatbotTurn:
            return "/chatbot/turn"
        case .starters:
            return "/chatbot/starters"
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .chatbotTurn:
            return .POST
        case .starters:
            return .GET
        }
    }

    public var headers: [String: String]? {
        switch self {
        case .chatbotTurn:
            return ["Accept": "text/event-stream"]
        case .starters:
            return ["Accept": "application/json"]
        }
    }

    public var body: [String: Any]? {
        switch self {
        case .chatbotTurn(let request):
            // Omits `conversation_id` entirely when nil — the server distinguishes
            // an absent key (start new) from an explicit null.
            return request.jsonBody
        case .starters:
            return nil
        }
    }
}
