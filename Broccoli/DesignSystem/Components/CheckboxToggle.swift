//
//  CheckboxToggle.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 09/10/25.
//
import SwiftUI

struct CheckboxToggle: View {
    @Environment(\.appTheme) private var theme
    @Binding var isOn: Bool
    let label: String

    var body: some View {
        Button(action: { isOn.toggle() }) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(theme.colors.border, lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                        .background(isOn ? theme.colors.textPrimary : Color.clear)
                        .cornerRadius(6)
                    if isOn {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                Text(label)
                    .font(theme.typography.callout)
                    .foregroundStyle(theme.colors.textPrimary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
