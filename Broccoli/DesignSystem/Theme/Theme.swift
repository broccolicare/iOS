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
    var otpInputBox: Color { get }
    var lightGreen: Color { get }
    var textCallout: Color { get }
    var appointmentCardBlue: Color { get }
    var appointmentCardLightBlue: Color { get }
    var gradientStart: Color { get }
    var gradientEnd: Color { get }
    var profileDetailTextColor: Color { get }
    var profileDetailSectionBackground: Color { get }
}

public protocol ThemeTypography {
    var titleXL: Font { get }
    var title: Font { get }
    var subtitle: Font { get }
    var body: Font { get }
    var callout: Font { get }
    var caption: Font { get }
    var button: Font { get }
    
    
    var regular22: Font { get }
    var regular20: Font { get }
    var regular18: Font { get }
    var regular16: Font { get }
    var regular14: Font { get }
    var regular12: Font { get }
    
    var medium22: Font { get }
    var medium20: Font { get }
    var medium18: Font { get }
    var medium16: Font { get }
    var medium14: Font { get }
    var medium12: Font { get }
    
    var semiBold30: Font { get }
    var semiBold28: Font { get }
    var semiBold22: Font { get }
    var semiBold20: Font { get }
    var semiBold18: Font { get }
    var semiBold16: Font { get }
    var semiBold14: Font { get }
    var semiBold12: Font { get }
    
    var bold28: Font { get }
    var bold30: Font { get }
    var bold22: Font { get }
    var bold20: Font { get }
    var bold18: Font { get }
    var bold16: Font { get }
    var bold14: Font { get }
    var bold12: Font { get }
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
