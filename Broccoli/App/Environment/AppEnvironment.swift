//
//  AppEnvironment.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 07/10/25.
//

import Foundation

public struct AppEnvironment {
    public let apiBaseURL: String
    /// Base URL for the AI backend (Health Assistant chat). A different host to
    /// `apiBaseURL` — the AI service is a separate deployment from Laravel.
    ///
    /// ⚠️ The hostname is `aiapp` — singular. `aiapps.broccolicare.ie` is not a
    /// configured server_name and does not resolve in DNS.
    public let aiBaseURL: String
    public let isDebug: Bool
    public let enableLogging: Bool
    public let stripePublishableKey: String
    public let agoraAppId: String

    public init(
        apiBaseURL: String,
        aiBaseURL: String,
        isDebug: Bool = true,
        enableLogging: Bool = true,
        stripePublishableKey: String = "",
        agoraAppId: String = ""
    ) {
        self.apiBaseURL = apiBaseURL
        self.aiBaseURL = aiBaseURL
        self.isDebug = isDebug
        self.enableLogging = enableLogging
        self.stripePublishableKey = stripePublishableKey
        self.agoraAppId = agoraAppId
    }
    
    public static let development = AppEnvironment(
        apiBaseURL: "https://admin.broccolicare.ie/api",
        aiBaseURL: "https://aiapp.broccolicare.ie",
        isDebug: true,
        enableLogging: true,
        stripePublishableKey: "pk_test_51RLrz6PP2Ocb3YbLOlUl6nSIshmI0oFC2tJOXM2duC2EPMb4UwXpVq1hQMnlgNAnrJqjZyrxkpAOx3Abl52orNzT00gKilZf8i", // Replace with pk_test_ key from Stripe Dashboard
        agoraAppId: "4fa50bc791c84b3fb63717186dbc3ade" // Replace with your Agora App ID from console
    )
    
    public static let staging = AppEnvironment(
        apiBaseURL: "https://admin.broccolicare.ie/api",
        aiBaseURL: "https://aiapp.broccolicare.ie",
        isDebug: false,
        enableLogging: true,
        stripePublishableKey: "pk_test_51RLrz6PP2Ocb3YbLOlUl6nSIshmI0oFC2tJOXM2duC2EPMb4UwXpVq1hQMnlgNAnrJqjZyrxkpAOx3Abl52orNzT00gKilZf8i", // Replace with pk_test_ key
        agoraAppId: "4fa50bc791c84b3fb63717186dbc3ade" // Replace with your Agora App ID
    )
    
    public static let production = AppEnvironment(
        apiBaseURL: "https://admin.broccolicare.ie/api",
        // ⚠️ Placeholder: intentionally the staging host. A dedicated production
        // host must be issued before public release (questions doc Q4).
        aiBaseURL: "https://aiapp.broccolicare.ie",
        isDebug: false,
        enableLogging: false,
        stripePublishableKey: "pk_test_51RLrz6PP2Ocb3YbLOlUl6nSIshmI0oFC2tJOXM2duC2EPMb4UwXpVq1hQMnlgNAnrJqjZyrxkpAOx3Abl52orNzT00gKilZf8i", // Replace with pk_live_ key for production
        agoraAppId: "4fa50bc791c84b3fb63717186dbc3ade" // Replace with your Agora App ID
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
