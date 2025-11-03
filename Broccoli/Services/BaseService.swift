//
//  BaseService.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 16/10/25.
//

import Foundation

/// Base service class that provides common functionality for all service classes
open class BaseService {
    
    public init() {}
    
    // MARK: - Protected Error Handling
    
    /// Centralized error handling for all service classes
    /// Maps HTTPError to ServiceError with readable messages
    public func handleServiceError<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch let httpError as HTTPError {
            // Map HTTPError to ServiceError with readable messages
            switch httpError {
            case .unauthorized(let msg, _, _):
                throw ServiceError.unauthorized(message: msg)
            case .validationFailed(let msg, let status, let errs):
                let message = (errs != nil) ? errs?.values.flatMap { $0 }.joined(separator: "\n") : msg
                throw ServiceError.validation(message: message ?? "Validation failed with status \(status)")
            case .serverError(let status, let msg, let errs):
                let message = msg ?? errs?.values.flatMap { $0 }.joined(separator: "\n") ?? "Server returned status \(status)"
                throw ServiceError.server(message: message)
            case .statusCode(let code):
                throw ServiceError.unknown(message: "Server returned status \(code)")
            default:
                throw ServiceError.unknown(message: httpError.localizedDescription)
            }
        } catch {
            // Other errors (decoding, network), rethrow as unknown
            throw ServiceError.unknown(message: error.localizedDescription)
        }
    }
    
    /// Centralized error handling for operations that don't return a value
//    public func handleServiceErrorVoid(_ operation: () async throws -> Void) async throws {
//        do {
//            try await operation()
//        } catch let httpError as HTTPError {
//            // Map HTTPError to ServiceError with readable messages
//            switch httpError {
//            case .unauthorized(let msg, _, _):
//                throw ServiceError.unauthorized(message: msg)
//            case .validationFailed(let msg, let status, let errs):
//                let message = (errs != nil) ? errs?.values.flatMap { $0 }.joined(separator: "\n") : msg
//                throw ServiceError.validation(message: message ?? "Validation failed with status \(status)")
//            case .serverError(let status, let msg, let errs):
//                let message = msg ?? errs?.values.flatMap { $0 }.joined(separator: "\n") ?? "Server returned status \(status)"
//                throw ServiceError.server(message: message)
//            case .statusCode(let code):
//                throw ServiceError.unknown(message: "Server returned status \(code)")
//            default:
//                throw ServiceError.unknown(message: httpError.localizedDescription)
//            }
//        } catch {
//            // Other errors (decoding, network), rethrow as unknown
//            throw ServiceError.unknown(message: error.localizedDescription)
//        }
//    }
}
