//
//  HeadlineText.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 08/10/25.
//
import SwiftUI

struct HeadlineText: View {
    @Environment(\.appTheme) private var theme
    let text: String
    var body: some View {
        Text(text)
            .font(theme.typography.titleXL)
            .foregroundStyle(theme.colors.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
