//
//  Font+App.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 07/10/25.
//

import SwiftUI

public extension Font {
    
    // MARK: - Figtree Font Family
    
    /// Figtree Regular
    static func figtree(size: CGFloat) -> Font {
        return Font.custom("Figtree-Regular", size: size)
    }
    
    /// Figtree Medium
    static func figtreeMedium(size: CGFloat) -> Font {
        return Font.custom("Figtree-Medium", size: size)
    }
    
    /// Figtree SemiBold
    static func figtreeSemiBold(size: CGFloat) -> Font {
        return Font.custom("Figtree-SemiBold", size: size)
    }
    
    /// Figtree Bold
    static func figtreeBold(size: CGFloat) -> Font {
        return Font.custom("Figtree-Bold", size: size)
    }
    
    /// Figtree ExtraBold
    static func figtreeExtraBold(size: CGFloat) -> Font {
        return Font.custom("Figtree-ExtraBold", size: size)
    }
    
    // MARK: - App Specific Typography Scale
    
    static var appTitleXL: Font {
        return .figtreeBold(size: 34)
    }
    
    static var appTitle: Font {
        return .figtreeSemiBold(size: 28)
    }
    
    static var appSubtitle: Font {
        return .figtreeMedium(size: 20)
    }
    
    static var appBody: Font {
        return .figtree(size: 16)
    }
    
    static var appCallout: Font {
        return .figtree(size: 15)
    }
    
    static var appCaption: Font {
        return .figtree(size: 13)
    }
    
    static var appButton: Font {
        return .figtreeSemiBold(size: 16)
    }
}