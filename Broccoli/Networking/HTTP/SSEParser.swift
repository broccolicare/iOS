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
            // Spec-compliant streams separate events with a blank line, which
            // `flush`es above. This server does NOT (it streams event/data pairs
            // back-to-back with no blank line), so without this a whole turn's
            // events accumulate into one buffer and fail to decode as a single
            // event. Treat the start of a new `event:` as a boundary: dispatch the
            // event already buffered before beginning the next one.
            let pending = dataLines.isEmpty ? nil : flush()
            eventName = value
            return pending
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
            do {
                let token = try JSONDecoder().decode(TokenPayload.self, from: data)
                return .token(token.text)
            } catch {
                logDecodeFailure(event: "token", payload: payload, error: error)
                return nil
            }

        case "tool_result":
            do {
                let envelope = try JSONDecoder().decode(ToolResultEnvelope.self, from: data)
                return .toolResult(tool: envelope.tool, data: envelope.data.raw)
            } catch {
                logDecodeFailure(event: "tool_result", payload: payload, error: error)
                return nil
            }

        case "done":
            do {
                let done = try JSONDecoder().decode(TurnDone.self, from: data)
                return .done(done)
            } catch {
                logDecodeFailure(event: "done", payload: payload, error: error)
                return nil
            }

        default:
            // Unknown event name — ignore, so the server can add events without a
            // client release.
            #if DEBUG
            print("⚠️ [SSEParser] ignored unknown event=\"\(eventName)\" payload=\(payload)")
            #endif
            return nil
        }
    }

    /// A decode failure here means the wire shape diverged from the client's model
    /// for a *known* event — the single most likely reason a 200 turn renders
    /// nothing. Log the event, the raw payload, and the exact mismatch so it can be
    /// handed straight to the backend team.
    private func logDecodeFailure(event: String, payload: String, error: Error) {
        #if DEBUG
        print("❌ [SSEParser] failed to decode event=\"\(event)\": \(error)\n   payload: \(payload)")
        #endif
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
