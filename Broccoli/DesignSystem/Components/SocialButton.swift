//
//  SocialButton.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 09/10/25.
//
import SwiftUI

struct SocialButton: View {
    @Environment(\.appTheme) private var theme
    let title: String
    let systemImageName: String? // replace with brand images where available
    let background: Color
    let foreground: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if let name = systemImageName {
                    Image(name)
                        .imageScale(.large)
                }
                Text(title)
                    .font(theme.typography.callout)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .foregroundColor(foreground)
        }
        .background(background)
        .cornerRadius(theme.cornerRadius)
        .overlay(
            title == "Google" ? RoundedRectangle(cornerRadius: theme.cornerRadius)
                .stroke(theme.colors.border, lineWidth: 1) : RoundedRectangle(cornerRadius: theme.cornerRadius)
                .stroke(Color.clear, lineWidth: 0)
        )
        .buttonStyle(PlainButtonStyle())
    }
}
