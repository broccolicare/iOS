//
//  GrayOutlineButton.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 09/10/25.
//
import SwiftUI

struct GrayOutlineButton: View {
    @Environment(\.appTheme) private var theme
    let title: String
    
    
    var body: some View {
        
        Text(title)
            .font(theme.typography.button)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .foregroundColor(theme.colors.secondary)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(theme.colors.secondary, lineWidth: 1)
            )
            .cornerRadius(theme.cornerRadius)
    }
}

