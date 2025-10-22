//
//  SecureStore.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 07/10/25.
//

import Foundation
import KeychainAccess

public protocol SecureStoreProtocol {
    func store(_ value: String, for key: String) throws
    func retrieve(for key: String) throws -> String?
    func delete(for key: String) throws
    func clear() throws
}

public class SecureStore: SecureStoreProtocol {
    private let keychain: Keychain
    
    public init(service: String = "com.broccoli.app") {
        self.keychain = Keychain(service: service)
    }
    
    public func store(_ value: String, for key: String) throws {
        try keychain.set(value, key: key)
    }
    
    public func retrieve(for key: String) throws -> String? {
        return try keychain.get(key)
    }
    
    public func delete(for key: String) throws {
        try keychain.remove(key)
    }
    
    public func clear() throws {
        try keychain.removeAll()
    }
}

// MARK: - Keychain Keys
public extension SecureStore {
    enum Keys {
        public static let accessToken = "access_token"
        public static let refreshToken = "refresh_token"
        public static let userData = "user_data"
        public static let userID = "user_id"
        public static let fcmToken = "fcm_token"
    }
}
