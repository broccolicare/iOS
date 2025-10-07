//
//  Color+App.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 07/10/25.
//

import SwiftUI

public extension Color {
    
    // MARK: - App Color Palette
    
    /// Primary brand color
    static var appPrimary: Color {
        return Color("Primary")
    }
    
    /// Secondary brand color
    static var appSecondary: Color {
        return Color("Secondary")
    }
    
    /// App background color
    static var appBackground: Color {
        return Color("Background")
    }
    
    /// Surface color for cards, modals, etc.
    static var appSurface: Color {
        return Color("Surface")
    }
    
    /// Primary text color
    static var appTextPrimary: Color {
        return Color("TextPrimary")
    }
    
    /// Secondary text color
    static var appTextSecondary: Color {
        return Color("TextSecondary")
    }
    
    /// Success color for positive actions
    static var appSuccess: Color {
        return Color("Success")
    }
    
    /// Warning color for caution states
    static var appWarning: Color {
        return Color("Warning")
    }
    
    /// Error color for negative states
    static var appError: Color {
        return Color("Error")
    }
    
    /// Border color for inputs and dividers
    static var appBorder: Color {
        return Color("Border")
    }
    
    // MARK: - Fallback Colors (in case assets are missing)
    
    /// Fallback colors when asset colors are not available
    static var fallbackPrimary: Color {
        return Color(red: 0.0, green: 0.48, blue: 1.0) // Blue
    }
    
    static var fallbackSecondary: Color {
        return Color(red: 0.35, green: 0.34, blue: 0.84) // Purple
    }
    
    static var fallbackSuccess: Color {
        return Color(red: 0.2, green: 0.78, blue: 0.35) // Green
    }
    
    static var fallbackWarning: Color {
        return Color(red: 1.0, green: 0.58, blue: 0.0) // Orange
    }
    
    static var fallbackError: Color {
        return Color(red: 1.0, green: 0.23, blue: 0.19) // Red
    }
}