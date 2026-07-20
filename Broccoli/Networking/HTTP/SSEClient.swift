//
//  SSEClient.swift
//  Broccoli
//
//  Streaming transport for the Health Assistant chat turn.
//  Contract: docs/ios-integration-guide.md §4, §6, §7.
//

import Foundation

public protocol SSEClientProtocol {
    func stream(_ endpoint: Endpoint) -> AsyncThrowingStream<TurnEvent, Error>
}

public final class SSEClient: SSEClientProtocol {

    private let session: URLSession
    private let baseURL: String
    private let secureStore: SecureStoreProtocol

    public init(
        baseURL: String = AppEnvironment.current.aiBaseURL,
        secureStore: SecureStoreProtocol = SecureStore(),
        session: URLSession? = nil
    ) {
        self.baseURL = baseURL
        self.secureStore = secureStore

        if let session {
            self.session = session
        } else {
            // Own configuration — NOT URLSession.shared.
            //
            // The server runs the entire turn (AI call, guardrails, persistence)
            // to completion before streaming a single byte, and sends no keepalive.
            // There is therefore no intermediate byte to reset an idle timer, so
            // the request timeout must cover the whole worst case: up to 5 tool
            // iterations × 30s AI timeout × retries. The 60s default WILL cut off
            // legitimate turns (guide §4).
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 120
            configuration.timeoutIntervalForResource = 120
            self.session = URLSession(configuration: configuration)
        }
    }

    public func stream(_ endpoint: Endpoint) -> AsyncThrowingStream<TurnEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await run(endpoint, continuation: continuation)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    // MARK: - Private

    private func run(
        _ endpoint: Endpoint,
        continuation: AsyncThrowingStream<TurnEvent, Error>.Continuation
    ) async throws {
        let request = try buildRequest(for: endpoint)

        let (bytes, response) = try await session.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {
            // Non-2xx always means the JSON error envelope, never SSE (guide §6).
            // Read the body and throw before parsing a single line as an event.
            throw try await failure(from: bytes, statusCode: httpResponse.statusCode)
        }

        let parser = SSEParser()

        for try await line in bytes.lines {
            try Task.checkCancellation()
            if let event = parser.consume(line: line) {
                continuation.yield(event)
            }
        }

        // Flush a final event that arrived without a trailing blank line.
        if let event = parser.finish() {
            continuation.yield(event)
        }
    }

    private func buildRequest(for endpoint: Endpoint) throws -> URLRequest {
        guard let url = URL(string: baseURL + endpoint.path) else {
            throw HTTPError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        // Set headers individually. Assigning `allHTTPHeaderFields` replaces the
        // whole dictionary and would clobber Accept / Content-Type / Authorization.
        for (key, value) in endpoint.headers ?? [:] {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

        // Read the token once, at connect. A turn can run for two minutes; there is
        // no point re-reading mid-stream since the request is already authenticated.
        if let token = try? secureStore.retrieve(for: SecureStore.Keys.accessToken) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Echoed in the response headers and stamped on all server logs for this
        // request — log it so a user-reported issue can be matched to server logs.
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Correlation-ID")

        if let body = endpoint.body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return request
    }

    /// Builds the error for a non-2xx response, draining the (small) JSON body.
    private func failure(from bytes: URLSession.AsyncBytes, statusCode: Int) async throws -> Error {
        var data = Data()
        for try await byte in bytes {
            data.append(byte)
        }

        let envelope = try? JSONDecoder().decode(ChatErrorEnvelope.self, from: data)
        let message = envelope?.error.message
        let correlationId = envelope?.error.correlationId

        #if DEBUG
        print("❌ [SSEClient] HTTP \(statusCode) code=\(envelope?.error.code ?? "-") correlation_id=\(correlationId ?? "-")")
        #endif

        switch statusCode {
        case 401:
            // P1-08 — 401 policy.
            //
            // Post .unauthorizedErrorReceived, matching HTTPClient's behaviour, so
            // a chat 401 drives the same app-wide sign-out as any other 401.
            //
            // We deliberately do NOT attempt the guide's "re-authenticate and
            // retry": no token refresh is implemented anywhere in this app
            // (AuthService.refreshToken has zero callers), so there is nothing to
            // refresh with. Silently swallowing the 401 would leave the user
            // staring at a dead composer. Revisit if refresh is ever wired up.
            NotificationCenter.default.post(name: .unauthorizedErrorReceived, object: nil)
            return HTTPError.unauthorized(
                message: message ?? "Unauthorized",
                statusCode: statusCode,
                errors: nil
            )
        case 422:
            return HTTPError.validationFailed(
                message: message ?? "Validation failed",
                statusCode: statusCode,
                errors: nil
            )
        default:
            return HTTPError.serverError(
                statusCode: statusCode,
                message: message,
                errors: nil
            )
        }
    }
}
