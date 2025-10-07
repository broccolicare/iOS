//
//  HTTPClient.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 07/10/25.
//

import Foundation

public protocol HTTPClientProtocol {
    func request<T: Codable>(_ endpoint: Endpoint) async throws -> T
    func request(_ endpoint: Endpoint) async throws -> Data
}

public class HTTPClient: HTTPClientProtocol {
    private let session: URLSession
    private let baseURL: String
    
    public init(baseURL: String = AppEnvironment.current.apiBaseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
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
        
        if let body = endpoint.body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw HTTPError.statusCode(httpResponse.statusCode)
        }
        
        return data
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
}

public enum HTTPError: Error {
    case invalidURL
    case invalidResponse
    case statusCode(Int)
    case noData
}

public enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}