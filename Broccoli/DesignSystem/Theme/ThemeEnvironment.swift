//
//  ThemeEnvironment.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 07/10/25.
//

import SwiftUI

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue: AppThemeProtocol = AppTheme.default
}

public extension EnvironmentValues {
    var appTheme: AppThemeProtocol {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

public extension View {
    func appTheme(_ theme: AppThemeProtocol) -> some View {
        environment(\.appTheme, theme)
    }
}