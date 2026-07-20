//
//  SSEParser.swift
//  Broccoli
//
//  Line-oriented Server-Sent Events parser.
//
//  Deliberately separate from the transport (`SSEClient`) so every edge case is
//  unit-testable with no network involved. Feed it lines; it emits `TurnEvent`s.
//

import Foundation

/// Accumulates `event:` / `data:` lines into events, flushing on a blank line
/// (and once more at stream end, for a stream that ends without a trailing blank).
///
/// Not thread-safe — drive it from a single consumer, as `SSEClient` does.
public final class SSEParser {

    private var eventName: String?
    private var dataLines: [String] = []

    public init() {}

    /// Feed one line from the stream. Returns a decoded event when this line
    /// completes one, otherwise nil.
    public func consume(line: String) -> TurnEvent? {
        // A line starting with ':' is a comment (used for keepalives). Ignore.
        // Note: this server sends no keepalives — the socket is silent until the
        // whole turn completes — but the spec allows them.
        if line.hasPrefix(":") {
            return nil
        }

        // Blank line terminates the current event.
        if line.isEmpty {
            return flush()
        }

        if let value = value(of: "event", in: line) {
            eventName = value
        } else if let value = value(of: "data", in: line) {
            dataLines.append(value)
        }
        // Any other field (`id:`, `retry:`, unrecognised) is ignored.

        return nil
    }

    /// Flush whatever is buffered. Call once when the stream ends, to handle a
    /// final event that arrived without a trailing blank line (or a truncated
    /// stream that still delivered a complete event).
    public func finish() -> TurnEvent? {
        flush()
    }

    // MARK: - Private

    private func flush() -> TurnEvent? {
        defer {
            eventName = nil
            dataLines = []
        }

        guard !dataLines.isEmpty, let eventName else { return nil }

        // Per the SSE spec, multiple `data:` lines join with "\n".
        let payload = dataLines.joined(separator: "\n")
        guard let data = payload.data(using: .utf8) else { return nil }

        switch eventName {
        case "token":
            guard let token = try? JSONDecoder().decode(TokenPayload.self, from: data) else {
                return nil
            }
            return .token(token.text)

        case "tool_result":
            guard let envelope = try? JSONDecoder().decode(ToolResultEnvelope.self, from: data) else {
                return nil
            }
            return .toolResult(tool: envelope.tool, data: envelope.data.raw)

        case "done":
            guard let done = try? JSONDecoder().decode(TurnDone.self, from: data) else {
                return nil
            }
            return .done(done)

        default:
            // Unknown event name — ignore, so the server can add events without a
            // client release.
            return nil
        }
    }

    /// Parses `field: value`, tolerating both `field:value` and `field: value`.
    /// Returns nil if `line` is not this field.
    private func value(of field: String, in line: String) -> String? {
        guard line.hasPrefix(field + ":") else { return nil }
        var value = String(line.dropFirst(field.count + 1))
        // The spec strips a single leading space, and only one.
        if value.hasPrefix(" ") {
            value = String(value.dropFirst())
        }
        return value
    }
}
