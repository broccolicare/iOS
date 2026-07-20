//
//  ChatEndpoint.swift
//  Broccoli
//
//  Contract: docs/ios-integration-guide.md §4.
//

import Foundation

public enum ChatEndpoint: Endpoint {
    case chatbotTurn(TurnRequest)

    public var path: String {
        switch self {
        case .chatbotTurn:
            return "/chatbot/turn"
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .chatbotTurn:
            return .POST
        }
    }

    public var headers: [String: String]? {
        switch self {
        case .chatbotTurn:
            return ["Accept": "text/event-stream"]
        }
    }

    public var body: [String: Any]? {
        switch self {
        case .chatbotTurn(let request):
            // Omits `conversation_id` entirely when nil — the server distinguishes
            // an absent key (start new) from an explicit null.
            return request.jsonBody
        }
    }
}
