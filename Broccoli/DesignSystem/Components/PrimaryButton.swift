//
//  PrimaryButton.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 10/10/25.
//
import SwiftUI

struct PrimaryButton<Content: View>: View {
    @Environment(\.appTheme) private var theme
    let action: () -> Void
    let label: () -> Content

    init(action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Content) {
        self.action = action
        self.label = label
    }

    var body: some View {
        Button(action: action) {
            label()
                .font(theme.typography.button)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
        }
        .background(theme.colors.primary)
        .cornerRadius(theme.cornerRadius)
        .buttonStyle(PlainButtonStyle())
    }
}
