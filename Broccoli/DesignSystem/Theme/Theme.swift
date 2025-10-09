//
//  Theme.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 07/10/25.
//

import SwiftUI

public protocol ThemeColors {
    var primary: Color { get }
    var secondary: Color { get }
    var background: Color { get }
    var surface: Color { get }
    var textPrimary: Color { get }
    var textSecondary: Color { get }
    var success: Color { get }
    var warning: Color { get }
    var error: Color { get }
    var border: Color { get }
}

public protocol ThemeTypography {
    var titleXL: Font { get }
    var title: Font { get }
    var subtitle: Font { get }
    var body: Font { get }
    var callout: Font { get }
    var caption: Font { get }
    var button: Font { get }
}

public struct ThemeSpacing {
    public let xs: CGFloat = 4
    public let sm: CGFloat = 8
    public let md: CGFloat = 12
    public let lg: CGFloat = 16
    public let xl: CGFloat = 22
    public let xxl: CGFloat = 32
    public init() {}
}

public protocol AppThemeProtocol {
    var colors: ThemeColors { get }
    var typography: ThemeTypography { get }
    var spacing: ThemeSpacing { get }
    var cornerRadius: CGFloat { get }
    var shadowRadius: CGFloat { get }
}
