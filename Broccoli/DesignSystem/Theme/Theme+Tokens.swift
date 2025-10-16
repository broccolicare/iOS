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
        lightGreen: Color = Color("LightGreen")
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
    }
}

public struct AppTypography: ThemeTypography {
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
        button: Font = Font.custom("Figtree-Bold", size: 16)
    ) {
        self.titleXL = titleXL
        self.title = title
        self.subtitle = subtitle
        self.body = body
        self.callout = callout
        self.caption = caption
        self.button = button
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
