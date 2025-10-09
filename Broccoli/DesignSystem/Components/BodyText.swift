//
//  BodyText.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 08/10/25.
//
import SwiftUI

struct BodyText: View {
    @Environment(\.appTheme) private var theme
    let text: String
    var body: some View {
        Text(text)
            .font(theme.typography.body)
            .foregroundStyle(theme.colors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
