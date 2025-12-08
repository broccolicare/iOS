import SwiftUI

extension Font {
    static public func safeCustom(_ name: String, size: CGFloat) -> Font {
        if UIFont(name: name, size: size) == nil {
            print("⚠️ Font '\(name)' not found — falling back to system font")
            return .system(size: size)
        }
        return .custom(name, size: size)
    }
}

public struct AppColors: ThemeColors {
    public var orderConfirmationBorderColor: Color
    
    public var monthSwitcherBackgroundColor: Color
    public var profileDetailSectionBackground: Color
    public var profileDetailTextColor: Color
    public var gradientStart: Color
    public var gradientEnd: Color
    public var appointmentCardBlue: Color
    public var appointmentCardLightBlue: Color
    public var otpInputBox: Color
    public let primary: Color
    public let secondary: Color
    public let background: Color
    public let surface: Color
    public let textPrimary: Color
    public let textSecondary: Color
    public let success: Color
    public let warning: Color
    public let error: Color
    public let border: Color
    public let lightGreen: Color
    public let textCallout: Color

    public init(
        primary: Color = Color("Primary"),
        secondary: Color = Color("Secondary"),
        background: Color = Color("Background"),
        surface: Color = Color("Surface"),
        textPrimary: Color = Color("TextPrimary"),
        textSecondary: Color = Color("TextSecondary"),
        success: Color = Color("Success"),
        warning: Color = Color("Warning"),
        error: Color = Color("Error"),
        border: Color = Color("Border"),
        otpInputBox: Color = Color("OtpInputBox"),
        lightGreen: Color = Color("LightGreen"),
        textCallout: Color = Color("TextCallout"),
        appointmentCardBlue: Color = Color("AppointmentCardBlue"),
        appointmentCardLightBlue: Color = Color("AppointmentCardLightBlue"),
        gradientStart: Color = Color("GradientStart"),
        gradientEnd: Color = Color("GradientEnd"),
        profileDetailTextColor: Color = Color("ProfileDetailTextColor"),
        profileDetailSectionBackground: Color = Color("ProfileDetailSectionBackground"),
        monthSwitcherBackgroundColor: Color = Color("MonthSwitcherBackground"),
        orderConfirmationBorderColor: Color = Color("OrderConfirmationBorderColor")
    ) {
        self.primary = primary
        self.secondary = secondary
        self.background = background
        self.surface = surface
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.success = success
        self.warning = warning
        self.error = error
        self.border = border
        self.otpInputBox = otpInputBox
        self.lightGreen = lightGreen
        self.textCallout = textCallout
        self.appointmentCardBlue = appointmentCardBlue
        self.appointmentCardLightBlue = appointmentCardLightBlue
        self.gradientStart = gradientStart
        self.gradientEnd = gradientEnd
        self.profileDetailTextColor = profileDetailTextColor
        self.profileDetailSectionBackground = profileDetailSectionBackground
        self.monthSwitcherBackgroundColor = monthSwitcherBackgroundColor
        self.orderConfirmationBorderColor = orderConfirmationBorderColor
    }
}

public struct AppTypography: ThemeTypography {
    
    public var extraBold28: Font
    public var extraBold30: Font
    public var extraBold24: Font
    public var extraBold22: Font
    public var extraBold20: Font
    public var extraBold18: Font
    public var extraBold16: Font
    public var extraBold14: Font
    public var extraBold12: Font
    
    public var regular32: Font
    public var regular30: Font
    public var regular28: Font
    public var regular26: Font
    public var regular24: Font
    public var regular22: Font
    public var regular20: Font
    public var regular18: Font
    public var regular16: Font
    public var regular14: Font
    public var regular12: Font
    
    public var medium32: Font
    public var medium30: Font
    public var medium28: Font
    public var medium26: Font
    public var medium24: Font
    public var medium22: Font
    public var medium20: Font
    public var medium18: Font
    public var medium16: Font
    public var medium14: Font
    public var medium12: Font
    
    public var semiBold32: Font
    public var semiBold30: Font
    public var semiBold28: Font
    public var semiBold26: Font
    public var semiBold24: Font
    public var semiBold22: Font
    public var semiBold20: Font
    public var semiBold18: Font
    public var semiBold16: Font
    public var semiBold14: Font
    public var semiBold12: Font
    
    public var bold34: Font
    public var bold32: Font
    public var bold30: Font
    public var bold28: Font
    public var bold26: Font
    public var bold24: Font
    public let bold22: Font
    public var bold20: Font
    public var bold18: Font
    public var bold16: Font
    public var bold14: Font
    public var bold12: Font
    
    public let titleXL: Font
    public let title: Font
    public let subtitle: Font
    public let body: Font
    public let callout: Font
    public let caption: Font
    public let button: Font
    

    public init(
        titleXL: Font = Font.safeCustom("Figtree-Bold", size: 34),
        title: Font = Font.custom("Figtree-Medium", size: 30),
        subtitle: Font = Font.custom("Figtree-Medium", size: 20),
        body: Font = Font.custom("Figtree-Regular", size: 16),
        callout: Font = Font.custom("Figtree-Regular", size: 14),
        caption: Font = Font.custom("Figtree-Regular", size: 12),
        button: Font = Font.custom("Figtree-Bold", size: 16),
        
        bold34: Font = Font.custom("Figtree-ExtraBold", size: 34),
        bold32: Font = Font.custom("Figtree-ExtraBold", size: 32),
        bold30: Font = Font.custom("Figtree-ExtraBold", size: 30),
        bold28: Font = Font.custom("Figtree-ExtraBold", size: 28),
        bold26: Font = Font.custom("Figtree-ExtraBold", size: 26),
        bold24: Font = Font.custom("Figtree-ExtraBold", size: 24),
        bold22: Font = Font.custom("Figtree-ExtraBold", size: 22),
        bold20: Font = Font.custom("Figtree-ExtraBold", size: 20),
        bold18: Font = Font.custom("Figtree-ExtraBold", size: 18),
        bold16: Font = Font.custom("Figtree-ExtraBold", size: 16),
        bold14: Font = Font.custom("Figtree-ExtraBold", size: 14),
        bold12: Font = Font.custom("Figtree-ExtraBold", size: 12),
        
        extraBold30: Font = Font.custom("Figtree-Bold", size: 30),
        extraBold28: Font = Font.custom("Figtree-Bold", size: 28),
        extraBold24: Font = Font.custom("Figtree-Bold", size: 24),
        extraBold22: Font = Font.custom("Figtree-Bold", size: 22),
        extraBold20: Font = Font.custom("Figtree-Bold", size: 20),
        extraBold18: Font = Font.custom("Figtree-Bold", size: 18),
        extraBold16: Font = Font.custom("Figtree-Bold", size: 16),
        extraBold14: Font = Font.custom("Figtree-Bold", size: 14),
        extraBold12: Font = Font.custom("Figtree-Bold", size: 12),
        
        regular32: Font = Font.custom("Figtree-Regular", size: 32),
        regular30: Font = Font.custom("Figtree-Regular", size: 30),
        regular28: Font = Font.custom("Figtree-Regular", size: 28),
        regular26: Font = Font.custom("Figtree-Regular", size: 26),
        regular24: Font = Font.custom("Figtree-Regular", size: 24),
        regular22: Font = Font.custom("Figtree-Regular", size: 22),
        regular20: Font = Font.custom("Figtree-Regular", size: 20),
        regular18: Font = Font.custom("Figtree-Regular", size: 18),
        regular16: Font = Font.custom("Figtree-Regular", size: 16),
        regular14: Font = Font.custom("Figtree-Regular", size: 14),
        regular12: Font = Font.custom("Figtree-Regular", size: 12),
        
        
        medium32: Font = Font.custom("Figtree-Medium", size: 32),
        medium30: Font = Font.custom("Figtree-Medium", size: 30),
        medium28: Font = Font.custom("Figtree-Medium", size: 28),
        medium26: Font = Font.custom("Figtree-Medium", size: 26),
        medium24: Font = Font.custom("Figtree-Medium", size: 24),
        medium22: Font = Font.custom("Figtree-Medium", size: 22),
        medium20: Font = Font.custom("Figtree-Medium", size: 20),
        medium18: Font = Font.custom("Figtree-Medium", size: 18),
        medium16: Font = Font.custom("Figtree-Medium", size: 16),
        medium14: Font = Font.custom("Figtree-Medium", size: 14),
        medium12: Font = Font.custom("Figtree-Medium", size: 12),
        
        semiBold32: Font = Font.custom("Figtree-SemiBold", size: 32),
        semiBold30: Font = Font.custom("Figtree-SemiBold", size: 30),
        semiBold28: Font = Font.custom("Figtree-SemiBold", size: 28),
        semiBold26: Font = Font.custom("Figtree-SemiBold", size: 26),
        semiBold24: Font = Font.custom("Figtree-SemiBold", size: 24),
        semiBold22: Font = Font.custom("Figtree-SemiBold", size: 22),
        semiBold20: Font = Font.custom("Figtree-SemiBold", size: 20),
        semiBold18: Font = Font.custom("Figtree-SemiBold", size: 18),
        semiBold16: Font = Font.custom("Figtree-SemiBold", size: 16),
        semiBold14: Font = Font.custom("Figtree-SemiBold", size: 14),
        semiBold12: Font = Font.custom("Figtree-SemiBold", size: 12)
        
        
    ) {
        self.titleXL = titleXL
        self.title = title
        self.subtitle = subtitle
        self.body = body
        self.callout = callout
        self.caption = caption
        self.button = button
        
        self.medium32 = medium32
        self.medium30 = medium30
        self.medium28 = medium28
        self.medium26 = medium26
        self.medium24 = medium24
        self.medium22 = medium22
        self.medium20 = medium20
        self.medium18 = medium18
        self.medium16 = medium16
        self.medium14 = medium14
        self.medium12 = medium12
        
        self.regular32 = regular32
        self.regular30 = regular30
        self.regular28 = regular28
        self.regular26 = regular26
        self.regular24 = regular24
        self.regular22 = regular22
        self.regular20 = regular20
        self.regular18 = regular18
        self.regular16 = regular16
        self.regular14 = regular14
        self.regular12 = regular12
        
        self.semiBold32 = semiBold32
        self.semiBold30 = semiBold30
        self.semiBold28 = semiBold28
        self.semiBold26 = semiBold26
        self.semiBold24 = semiBold24
        self.semiBold22 = semiBold22
        self.semiBold20 = semiBold20
        self.semiBold18 = semiBold18
        self.semiBold16 = semiBold16
        self.semiBold14 = semiBold14
        self.semiBold12 = semiBold12
        
        self.bold34 = bold34
        self.bold32 = bold32
        self.bold30 = bold30
        self.bold28 = bold28
        self.bold26 = bold26
        self.bold24 = bold24
        self.bold22 = bold22
        self.bold20 = bold20
        self.bold18 = bold18
        self.bold16 = bold16
        self.bold14 = bold14
        self.bold12 = bold12
        
        self.extraBold30 = extraBold30
        self.extraBold28 = extraBold28
        self.extraBold24 = extraBold24
        self.extraBold22 = extraBold22
        self.extraBold20 = extraBold20
        self.extraBold18 = extraBold18
        self.extraBold16 = extraBold16
        self.extraBold14 = extraBold14
        self.extraBold12 = extraBold12
    }
}

public struct AppTheme: AppThemeProtocol {
    public let colors: ThemeColors
    public let typography: ThemeTypography
    public let spacing: ThemeSpacing
    public let cornerRadius: CGFloat
    public let shadowRadius: CGFloat

    public init(
        colors: ThemeColors = AppColors(),
        typography: ThemeTypography = AppTypography(),
        spacing: ThemeSpacing = ThemeSpacing(),
        cornerRadius: CGFloat = 12,
        shadowRadius: CGFloat = 6
    ) {
        self.colors = colors
        self.typography = typography
        self.spacing = spacing
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
    }

    public static let `default` = AppTheme()
}
