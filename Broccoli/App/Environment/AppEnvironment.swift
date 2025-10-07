//
//  AppEnvironment.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 07/10/25.
//

import Foundation

public struct AppEnvironment {
    public let apiBaseURL: String
    public let isDebug: Bool
    public let enableLogging: Bool
    
    public init(
        apiBaseURL: String,
        isDebug: Bool = true,
        enableLogging: Bool = true
    ) {
        self.apiBaseURL = apiBaseURL
        self.isDebug = isDebug
        self.enableLogging = enableLogging
    }
    
    public static let development = AppEnvironment(
        apiBaseURL: "https://api-dev.broccoli.com",
        isDebug: true,
        enableLogging: true
    )
    
    public static let staging = AppEnvironment(
        apiBaseURL: "https://api-staging.broccoli.com",
        isDebug: false,
        enableLogging: true
    )
    
    public static let production = AppEnvironment(
        apiBaseURL: "https://api.broccoli.com",
        isDebug: false,
        enableLogging: false
    )
    
    public static let current: AppEnvironment = {
        #if DEBUG
        return .development
        #elseif STAGING
        return .staging
        #else
        return .production
        #endif
    }()
}