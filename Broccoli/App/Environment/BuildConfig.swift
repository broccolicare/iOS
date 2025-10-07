//
//  BuildConfig.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 07/10/25.
//

import Foundation

public struct BuildConfig {
    public let googleClientId: String
    public let facebookAppId: String
    public let apiKey: String
    public let bundleId: String
    
    public init(
        googleClientId: String = "",
        facebookAppId: String = "",
        apiKey: String = "",
        bundleId: String = ""
    ) {
        self.googleClientId = googleClientId
        self.facebookAppId = facebookAppId
        self.apiKey = apiKey
        self.bundleId = bundleId
    }
    
    public static let current = BuildConfig(
        googleClientId: Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String ?? "",
        facebookAppId: Bundle.main.object(forInfoDictionaryKey: "FACEBOOK_APP_ID") as? String ?? "",
        apiKey: Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String ?? "",
        bundleId: Bundle.main.bundleIdentifier ?? ""
    )
}