//
//  HTTPClient.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 07/10/25.
//

import Foundation

// Matches server JSON:
// {
//   "message": "The given data was invalid.",
//   "errors": { "password": ["..."], "role": ["..."] },
//   "status": 422
// }
struct ServerErrorResponse: Codable {
    let message: String?
    let errors: [String: [String]]?
    let status: Int?
    
    // join into single readable string (preserving field order lost in dict)
    var combinedMessage: String? {
        if let message = message, !message.isEmpty {
            return message
        }
        if let errors = errors, !errors.isEmpty {
            let all = errors.values.flatMap { $0 }
            if !all.isEmpty { return all.joined(separator: "\n") }
        }
        return nil
    }
}

public protocol HTTPClientProtocol {
    func request<T: Codable>(_ endpoint: Endpoint) async throws -> T
    func request(_ endpoint: Endpoint) async throws -> Data
}

public class HTTPClient: HTTPClientProtocol {
    private let session: URLSession
    private let baseURL: String
    private let secureStore: SecureStore
    
    public init(baseURL: String = AppEnvironment.current.apiBaseURL, session: URLSession = .shared, secureStore: SecureStore = SecureStore()) {
        self.baseURL = baseURL
        self.session = session
        self.secureStore = secureStore
    }
    
    public func request<T: Codable>(_ endpoint: Endpoint) async throws -> T {
        let data = try await request(endpoint)
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    public func request(_ endpoint: Endpoint) async throws -> Data {
        let url = try buildURL(from: endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.headers
        
        // Automatically add Authorization header if token exists in secure storage
        if let token = try? secureStore.retrieve(for: SecureStore.Keys.accessToken) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = endpoint.body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        // Log request details
        logRequest(request: request, body: endpoint.body)
        
        let (data, response) = try await session.data(for: request)
        
        // Log response details
        logResponse(response: response, data: data)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPError.invalidResponse
        }
        
        // 2xx -> success
        if 200...299 ~= httpResponse.statusCode {
            return data
        }
        
        // Non-2xx -> try decode server error payload
        let decoder = JSONDecoder()
        var serverError: ServerErrorResponse? = nil
        if let decoded = try? decoder.decode(ServerErrorResponse.self, from: data) {
            serverError = decoded
        } else {
            // fallback: attempt to parse common patterns or raw string
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                var message: String? = nil
                if let msg = json["message"] as? String { message = msg }
                else if let err = json["error"] as? String { message = err }
                
                var errors: [String: [String]]? = nil
                if let errs = json["errors"] as? [String: Any] {
                    var parsed: [String: [String]] = [:]
                    for (k, v) in errs {
                        if let arr = v as? [String] { parsed[k] = arr }
                        else if let s = v as? String { parsed[k] = [s] }
                    }
                    if !parsed.isEmpty { errors = parsed }
                }
                
                let status = json["status"] as? Int
                serverError = ServerErrorResponse(message: message, errors: errors, status: status)
            } else if let text = String(data: data, encoding: .utf8) {
                serverError = ServerErrorResponse(message: text, errors: nil, status: httpResponse.statusCode)
            }
        }
        
        // Map common status codes to explicit HTTPError cases
        if let serr = serverError {
            switch httpResponse.statusCode {
            case 401:
                throw HTTPError.unauthorized(message: serr.combinedMessage ?? (serr.message ?? "Unauthorized"), statusCode: serr.status ?? httpResponse.statusCode, errors: serr.errors)
            case 422, 403:
                throw HTTPError.validationFailed(message: serr.combinedMessage ?? (serr.message ?? "Validation failed"), statusCode: serr.status ?? httpResponse.statusCode, errors: serr.errors)
            default:
                throw HTTPError.serverError(statusCode: serr.status ?? httpResponse.statusCode, message: serr.combinedMessage ?? serr.message, errors: serr.errors)
            }
        } else {
            // no structured server error available - generic fallback
            switch httpResponse.statusCode {
            case 401:
                throw HTTPError.unauthorized(message: "Unauthorized", statusCode: httpResponse.statusCode, errors: nil)
            case 422:
                throw HTTPError.validationFailed(message: "Validation failed", statusCode: httpResponse.statusCode, errors: nil)
            default:
                throw HTTPError.serverError(statusCode: httpResponse.statusCode, message: nil, errors: nil)
            }
        }
    }
    
    private func buildURL(from endpoint: Endpoint) throws -> URL {
        guard let url = URL(string: baseURL + endpoint.path) else {
            throw HTTPError.invalidURL
        }
        
        guard let queryItems = endpoint.queryItems, !queryItems.isEmpty else {
            return url
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        components?.queryItems = queryItems.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        guard let finalURL = components?.url else {
            throw HTTPError.invalidURL
        }
        
        return finalURL
    }
    
    private func logRequest(request: URLRequest, body: [String: Any]?) {
        #if DEBUG
        var logMessage = "\n--- HTTP Request ---\n"
        if let url = request.url {
            logMessage += "URL: \(url.absoluteString)\n"
        }
        if let method = request.httpMethod {
            logMessage += "Method: \(method)\n"
        }
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            logMessage += "Headers:\n"
            for (key, value) in headers {
                // Mask sensitive headers
//                if key.lowercased().contains("authorization") || key.lowercased().contains("token") {
//                    logMessage += "  \(key): [REDACTED]\n"
//                } else {
                    logMessage += "  \(key): \(value)\n"
//                }
            }
        }
        if let body = body {
            let filteredBody = maskSensitiveData(in: body)
            if let jsonData = try? JSONSerialization.data(withJSONObject: filteredBody, options: [.prettyPrinted]),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                logMessage += "Body:\n\(jsonString)\n"
            } else {
                logMessage += "Body: \(filteredBody)\n"
            }
        }
        logMessage += "--------------------"
        printLog(logMessage)
        #endif
    }
    
    private func logResponse(response: URLResponse?, data: Data) {
        #if DEBUG
        var logMessage = "\n--- HTTP Response ---\n"
        if let httpResponse = response as? HTTPURLResponse {
            logMessage += "Status Code: \(httpResponse.statusCode)\n"
            logMessage += "Headers:\n"
            for (key, value) in httpResponse.allHeaderFields {
                logMessage += "  \(key): \(value)\n"
            }
        } else {
            logMessage += "Response: \(String(describing: response))\n"
        }
        
        if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
           JSONSerialization.isValidJSONObject(jsonObject),
           let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            logMessage += "Body:\n\(prettyString)\n"
        } else if let string = String(data: data, encoding: .utf8) {
            logMessage += "Body:\n\(string)\n"
        } else {
            logMessage += "Body: [Unable to decode data]\n"
        }
        logMessage += "---------------------"
        printLog(logMessage)
        #endif
    }
    
    private func maskSensitiveData(in dictionary: [String: Any]) -> [String: Any] {
        var masked = dictionary
        let sensitiveKeys = ["password", "token", "access_token", "refresh_token", "authorization", "api_key", "apikey", "secret"]
        for key in sensitiveKeys {
            for dictKey in masked.keys {
                if dictKey.lowercased() == key.lowercased() {
                    masked[dictKey] = "[REDACTED]"
                } else if let nestedDict = masked[dictKey] as? [String: Any] {
                    masked[dictKey] = maskSensitiveData(in: nestedDict)
                }
            }
        }
        return masked
    }
    
    private func printLog(_ message: String) {
        #if DEBUG
        print(message)
        #endif
    }
}

public enum HTTPError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    case statusCode(Int)
    
    /// 401
    case unauthorized(message: String, statusCode: Int, errors: [String: [String]]?)
    /// 422
    case validationFailed(message: String, statusCode: Int, errors: [String: [String]]?)
    /// other 4xx/5xx
    case serverError(statusCode: Int, message: String?, errors: [String: [String]]?)
    case other(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response from server"
        case .noData: return "No data from server"
        case .statusCode(let c): return "Server returned status code \(c)"
        case .unauthorized(let message, _, _): return message
        case .validationFailed(let message, _, _): return message
        case .serverError(_, let message, let errors):
            if let msg = message, !msg.isEmpty { return msg }
            if let errs = errors, !errs.isEmpty {
                return errs.values.flatMap { $0 }.joined(separator: "\n")
            }
            return "Server error"
        case .other(let e): return e.localizedDescription
        }
    }
    
    /// convenient accessor for errors dictionary (may be nil)
    public var errors: [String: [String]]? {
        switch self {
        case .unauthorized(_, _, let errors): return errors
        case .validationFailed(_, _, let errors): return errors
        case .serverError(_, _, let errors): return errors
        default: return nil
        }
    }
    
    public var statusCode: Int? {
        switch self {
        case .unauthorized(_, let code, _): return code
        case .validationFailed(_, let code, _): return code
        case .serverError(let code, _, _): return code
        case .statusCode(let c): return c
        default: return nil
        }
    }
}

public enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}
