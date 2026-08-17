//
//  FloatingChatButton.swift
//  Broccoli
//

import SwiftUI

/// Floating action button that opens the Health Assistant chat from any tab.
struct FloatingChatButton: View {
    @Environment(\.appTheme) private var theme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "message.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(theme.colors.primary)
                .clipShape(Circle())
                .overlay(Circle().stroke(theme.colors.border))
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Health Assistant")
    }
}
