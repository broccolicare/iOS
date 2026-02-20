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
    public let stripePublishableKey: String
    public let agoraAppId: String
    
    public init(
        apiBaseURL: String,
        isDebug: Bool = true,
        enableLogging: Bool = true,
        stripePublishableKey: String = "",
        agoraAppId: String = ""
    ) {
        self.apiBaseURL = apiBaseURL
        self.isDebug = isDebug
        self.enableLogging = enableLogging
        self.stripePublishableKey = stripePublishableKey
        self.agoraAppId = agoraAppId
    }
    
    public static let development = AppEnvironment(
        apiBaseURL: "https://admin.broccolicare.ie/api",
        isDebug: true,
        enableLogging: true,
        stripePublishableKey: "pk_test_51RLrz6PP2Ocb3YbLOlUl6nSIshmI0oFC2tJOXM2duC2EPMb4UwXpVq1hQMnlgNAnrJqjZyrxkpAOx3Abl52orNzT00gKilZf8i", // Replace with pk_test_ key from Stripe Dashboard
        agoraAppId: "4fa50bc791c84b3fb63717186dbc3ade" // Replace with your Agora App ID from console
    )
    
    public static let staging = AppEnvironment(
        apiBaseURL: "https://admin.broccolicare.ie/api",
        isDebug: false,
        enableLogging: true,
        stripePublishableKey: "pk_test_51RLrz6PP2Ocb3YbLOlUl6nSIshmI0oFC2tJOXM2duC2EPMb4UwXpVq1hQMnlgNAnrJqjZyrxkpAOx3Abl52orNzT00gKilZf8i", // Replace with pk_test_ key
        agoraAppId: "4fa50bc791c84b3fb63717186dbc3ade" // Replace with your Agora App ID
    )
    
    public static let production = AppEnvironment(
        apiBaseURL: "https://admin.broccolicare.ie/api",
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
