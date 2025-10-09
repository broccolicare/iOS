//
//  BroccoliApp.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 07/10/25.
//

import SwiftUI

@main
struct BroccoliApp: App {

    private let httpClient: any HTTPClientProtocol = HTTPClient()
    private let secureStore: any SecureStoreProtocol = SecureStore()
    let authService: AuthService

    init() {
        self.authService = AuthService(httpClient: httpClient, secureStore: secureStore)
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(\.appTheme, AppTheme.default)
        }
    }
}
