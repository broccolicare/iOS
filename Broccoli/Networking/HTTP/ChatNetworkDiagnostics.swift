//
//  ChatNetworkDiagnostics.swift
//  Broccoli
//
//  Captures a full request/response trace for AI-backend (aiapp) calls so a
//  failure can be handed to the backend team verbatim.
//
//  Motivation: the chat transport sends the same `access_token` that Laravel
//  (admin.broccolicare.ie) issued to a *different* host (aiapp.broccolicare.ie).
//  When that host answers 401 the app signs the user out, and the existing
//  one-line log ("HTTP 401 code=unauthorized") is not enough for anyone to tell
//  whether the token was missing, expired, or simply not valid for that issuer.
//

import Foundation
import CryptoKit

/// A single captured exchange, formatted for pasting into a bug report.
public struct ChatNetworkTrace {
    public let timestamp: Date
    public let correlationId: String
    public let method: String
    public let url: String
    public let requestHeaders: [String: String]
    public let requestBody: String?
    public let statusCode: Int
    public let responseHeaders: [String: String]
    public let responseBody: String?
    public let tokenInfo: String

    /// Plain-text report. Safe to share: the bearer token itself is never
    /// included, only a fingerprint and its (public) JWT claims.
    public var formatted: String {
        var out = ""
        out += "===== BROCCOLI AI BACKEND TRACE =====\n"
        out += "time            : \(ISO8601DateFormatter().string(from: timestamp))\n"
        out += "correlation_id  : \(correlationId)\n"
        out += "app version     : \(ChatNetworkDiagnostics.appVersion)\n"
        out += "\n--- REQUEST ---\n"
        out += "\(method) \(url)\n"
        for (key, value) in requestHeaders.sorted(by: { $0.key < $1.key }) {
            out += "\(key): \(value)\n"
        }
        if let requestBody {
            out += "\nbody:\n\(requestBody)\n"
        }
        out += "\n--- TOKEN ---\n\(tokenInfo)\n"
        out += "\n--- RESPONSE ---\n"
        out += "HTTP \(statusCode)\n"
        for (key, value) in responseHeaders.sorted(by: { $0.key < $1.key }) {
            out += "\(key): \(value)\n"
        }
        out += "\nbody:\n\(responseBody ?? "<empty>")\n"
        out += "=====================================\n"
        return out
    }
}

public enum ChatNetworkDiagnostics {

    /// The most recent captured exchange, so a "copy diagnostics" affordance or
    /// a breakpoint can retrieve it after the fact.
    public private(set) static var lastTrace: ChatNetworkTrace?

    /// Header values that must never be printed in full.
    private static let sensitiveHeaders: Set<String> = ["authorization", "cookie", "set-cookie"]

    static var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }

    /// Records an exchange and prints it. Gated on `enableLogging` so release
    /// builds stay silent.
    public static func capture(
        request: URLRequest,
        correlationId: String,
        token: String?,
        statusCode: Int,
        response: HTTPURLResponse?,
        responseBody: Data
    ) {
        guard AppEnvironment.current.enableLogging else { return }

        var headers: [String: String] = [:]
        for (key, value) in request.allHTTPHeaderFields ?? [:] {
            headers[key] = sensitiveHeaders.contains(key.lowercased())
                ? redact(value)
                : value
        }

        var responseHeaders: [String: String] = [:]
        for (key, value) in response?.allHeaderFields ?? [:] {
            guard let key = key as? String, let value = value as? String else { continue }
            responseHeaders[key] = sensitiveHeaders.contains(key.lowercased())
                ? redact(value)
                : value
        }

        let trace = ChatNetworkTrace(
            timestamp: Date(),
            correlationId: correlationId,
            method: request.httpMethod ?? "?",
            url: request.url?.absoluteString ?? "?",
            requestHeaders: headers,
            requestBody: request.httpBody.flatMap { prettyJSON($0) },
            statusCode: statusCode,
            responseHeaders: responseHeaders,
            responseBody: prettyJSON(responseBody) ?? String(data: responseBody, encoding: .utf8),
            tokenInfo: describe(token: token)
        )

        lastTrace = trace
        print(trace.formatted)
    }

    // MARK: - Token inspection

    /// Describes the bearer token without ever revealing it: enough for the
    /// backend team to match it against their store and to see whether it is
    /// even the shape they expect.
    static func describe(token: String?) -> String {
        guard let token, !token.isEmpty else {
            return "NO TOKEN — nothing was sent in the Authorization header."
        }

        var out = ""
        out += "length      : \(token.count)\n"
        out += "fingerprint : sha256:\(sha256Prefix(token))\n"
        out += "preview     : \(redact(token))\n"

        let segments = token.split(separator: ".", omittingEmptySubsequences: false)
        guard segments.count == 3 else {
            // Laravel Sanctum personal-access tokens look like "17|abc123..."
            let kind = token.contains("|") ? "Laravel Sanctum personal access token" : "opaque"
            out += "format      : \(kind) (NOT a JWT — \(segments.count) dot-segments)\n"
            out += "note        : aiapp must be able to validate this token type.\n"
            return out
        }

        out += "format      : JWT\n"
        if let header = decodeJWTSegment(segments[0]) {
            out += "header      : \(header)\n"
        }
        guard let claims = decodeJWTSegmentJSON(segments[1]) else {
            out += "claims      : <undecodable>\n"
            return out
        }

        for key in ["iss", "aud", "sub", "iat", "exp", "nbf"] {
            guard let value = claims[key] else { continue }
            if key == "exp" || key == "iat" || key == "nbf", let seconds = numeric(value) {
                let date = Date(timeIntervalSince1970: seconds)
                out += "\(key.padding(toLength: 12, withPad: " ", startingAt: 0)): \(seconds) — \(ISO8601DateFormatter().string(from: date))\n"
            } else {
                out += "\(key.padding(toLength: 12, withPad: " ", startingAt: 0)): \(value)\n"
            }
        }

        if let exp = claims["exp"].flatMap(numeric) {
            let remaining = exp - Date().timeIntervalSince1970
            out += remaining <= 0
                ? "⚠️ EXPIRED \(Int(-remaining))s ago — the 401 is expected.\n"
                : "valid for   : \(Int(remaining))s more — token was NOT expired at send time.\n"
        }

        return out
    }

    // MARK: - Helpers

    private static func numeric(_ value: Any) -> TimeInterval? {
        if let d = value as? TimeInterval { return d }
        if let i = value as? Int { return TimeInterval(i) }
        if let s = value as? String { return TimeInterval(s) }
        return nil
    }

    private static func decodeJWTSegment(_ segment: Substring) -> String? {
        decodeJWTSegmentJSON(segment).map { "\($0)" }
    }

    private static func decodeJWTSegmentJSON(_ segment: Substring) -> [String: Any]? {
        var base64 = String(segment)
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        // Base64URL drops the padding that Foundation's decoder requires.
        while base64.count % 4 != 0 { base64 += "=" }

        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return json
    }

    private static func sha256Prefix(_ value: String) -> String {
        let digest = SHA256.hash(data: Data(value.utf8))
        return digest.map { String(format: "%02x", $0) }.joined().prefix(16).description
    }

    /// Shows only enough of a secret to correlate it, never enough to use it.
    private static func redact(_ value: String) -> String {
        let bare = value.hasPrefix("Bearer ") ? String(value.dropFirst(7)) : value
        guard bare.count > 16 else { return "<redacted \(bare.count) chars>" }
        return "\(bare.prefix(6))…\(bare.suffix(4)) (\(bare.count) chars)"
    }

    private static func prettyJSON(_ data: Data) -> String? {
        guard !data.isEmpty,
              let object = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(
                withJSONObject: object,
                options: [.prettyPrinted, .sortedKeys]
              )
        else { return nil }
        return String(data: pretty, encoding: .utf8)
    }
}
