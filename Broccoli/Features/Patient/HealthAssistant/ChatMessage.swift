//
//  ChatMessage.swift
//  Broccoli
//
//  P3-02 — one entry in the chat transcript.
//

import Foundation

/// A single transcript entry.
///
/// `id` is assigned once, at construction, and never changes — including while an
/// assistant message is still streaming. Token chunks mutate `kind` in place on the
/// existing element rather than replacing it, so `ForEach` sees a stable identity
/// and doesn't tear down and rebuild the bubble on every chunk.
struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    var kind: Kind

    init(id: UUID = UUID(), kind: Kind) {
        self.id = id
        self.kind = kind
    }

    enum Kind: Equatable {
        case user(String)
        /// Accumulated assistant text. Empty while awaiting the first token.
        case assistant(String)
        /// An inline card from a `tool_result` event. Rendered in Phase 4.
        case toolCard(ChatToolCard)
        /// Client-generated line — transport failures, turn errors. Never from the
        /// server, so it is styled distinctly from an assistant reply.
        case systemNotice(String)
    }

    // MARK: - Convenience

    static func user(_ text: String) -> ChatMessage { ChatMessage(kind: .user(text)) }
    static func assistant(_ text: String) -> ChatMessage { ChatMessage(kind: .assistant(text)) }
    static func systemNotice(_ text: String) -> ChatMessage { ChatMessage(kind: .systemNotice(text)) }

    /// The accumulated text when this is an assistant message, else nil.
    var assistantText: String? {
        if case .assistant(let text) = kind { return text }
        return nil
    }

    var isToolCard: Bool {
        if case .toolCard = kind { return true }
        return false
    }
}

/// A `tool_result` event held until Phase 4 renders it.
///
/// The payload stays as raw JSON here: routing on `tool` and decoding into the
/// matching payload type is P4-01's job, deliberately kept in one place so an
/// unknown tool name has exactly one no-op path.
struct ChatToolCard: Identifiable, Equatable {
    let id: UUID
    let tool: String
    let data: Data

    init(id: UUID = UUID(), tool: String, data: Data) {
        self.id = id
        self.tool = tool
        self.data = data
    }
}
