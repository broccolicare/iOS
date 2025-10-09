//
//  SecondaryButton.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 08/10/25.
//
import SwiftUI

enum SecondaryButtonStyle {
    case outline
    case ghost
}

struct SecondaryButton: View {
    @Environment(\.appTheme) private var theme
    let title: String
    let style: SecondaryButtonStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(theme.typography.button)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .foregroundColor(style == .outline ? theme.colors.secondary : theme.colors.textPrimary)
                .background(style == .ghost ? theme.colors.surface : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadius)
                        .stroke(style == .outline ? theme.colors.primary : Color.clear, lineWidth: style == .outline ? 1.5 : 0)
                )
        }
        .cornerRadius(theme.cornerRadius)
        .buttonStyle(PlainButtonStyle())
    }
}
