//
//  Endpoint.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 07/10/25.
//

import Foundation

public protocol Endpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var queryItems: [String: String]? { get }
    var body: [String: Any]? { get }
}

public extension Endpoint {
    var headers: [String: String]? { nil }
    var queryItems: [String: String]? { nil }
    var body: [String: Any]? { nil }
}
