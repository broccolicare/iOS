//
//  GenderSegment.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 10/10/25.
//
import SwiftUI

struct GenderSegment: View {
    @Environment(\.appTheme) private var theme
    @Binding var selected: String
    let left: String
    let right: String

    var body: some View {
        HStack(spacing: 0) {
            Button(action: { selected = left }) {
                Text(left)
                    .font(theme.typography.callout)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundStyle(selected == left ? .white : theme.colors.textSecondary)
                    .background(selected == left ? theme.colors.textPrimary : theme.colors.surface)
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: { selected = right }) {
                Text(right)
                    .font(theme.typography.callout)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundStyle(selected == right ? .white : theme.colors.textSecondary)
                    .background(selected == right ? theme.colors.textPrimary : theme.colors.surface)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .stroke(theme.colors.border, lineWidth: 1)
        )
        .cornerRadius(theme.cornerRadius)
    }
}
