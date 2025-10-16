//
//  TextInputField.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 14/10/25.
//


import SwiftUI

/// Reusable text input used across the app.
///
/// Supports:
/// - optional title label
/// - placeholder
/// - secure / toggle-able password field
/// - leading SF Symbol icon
/// - trailing action button (e.g., clear / country picker / eye toggle)
/// - keyboardType
/// - inline error message
import SwiftUI

struct TextInputField: View {
    @Environment(\.appTheme) private var theme

    let title: String?
    let placeholder: String
    @Binding var text: String

    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var leadingSystemImage: String? = nil
    var trailingSystemImage: String? = nil
    var trailingAction: (() -> Void)? = nil

    var autocapitalization: TextInputAutocapitalization = .never
    var disableAutocorrection: Bool = true

    var errorText: String? = nil

    /// 👇 New parameter
    var showBorder: Bool = true

    // local state for secure toggle (if isSecure)
    @State private var isSecured: Bool = true

    init(
        title: String? = nil,
        placeholder: String = "",
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        isSecure: Bool = false,
        leadingSystemImage: String? = nil,
        trailingSystemImage: String? = nil,
        trailingAction: (() -> Void)? = nil,
        autocapitalization: TextInputAutocapitalization = .never,
        disableAutocorrection: Bool = true,
        errorText: String? = nil,
        showBorder: Bool = true // 👈 default value
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
        self.isSecure = isSecure
        self.leadingSystemImage = leadingSystemImage
        self.trailingSystemImage = trailingSystemImage
        self.trailingAction = trailingAction
        self.autocapitalization = autocapitalization
        self.disableAutocorrection = disableAutocorrection
        self.errorText = errorText
        self.showBorder = showBorder
        // default secured state true for password fields; will be ignored for non-secure
        self._isSecured = State(initialValue: isSecure)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            // Optional title above field (small label)
            if let title = title {
                Text(title)
                    .font(theme.typography.callout)
                    .foregroundStyle(theme.colors.textPrimary)
            }

            HStack(spacing: 12) {
                // Leading icon
                if let systemName = leadingSystemImage {
                    Image(systemName: systemName)
                        .font(.system(size: 18))
                        .foregroundStyle(theme.colors.textSecondary)
                }

                // Field (secure or plain)
                Group {
                    if isSecure {
                        if isSecured {
                            SecureField(placeholder, text: $text)
                                .textContentType(.password)
                                .autocorrectionDisabled(disableAutocorrection)
                                .textInputAutocapitalization(autocapitalization)
                                .keyboardType(keyboardType)
                                .accessibilityLabel(title ?? placeholder)
                        } else {
                            TextField(placeholder, text: $text)
                                .autocorrectionDisabled(disableAutocorrection)
                                .textInputAutocapitalization(autocapitalization)
                                .keyboardType(keyboardType)
                                .accessibilityLabel(title ?? placeholder)
                        }
                    } else {
                        TextField(placeholder, text: $text)
                            .autocorrectionDisabled(disableAutocorrection)
                            .textInputAutocapitalization(autocapitalization)
                            .keyboardType(keyboardType)
                            .accessibilityLabel(title ?? placeholder)
                    }
                }
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.textPrimary)

                // Trailing action (custom) OR eye toggle for secure fields
                if isSecure {
                    Button(action: { isSecured.toggle() }) {
                        Image(systemName: isSecured ? "eye.slash" : "eye")
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else if let trailing = trailingSystemImage {
                    Button(action: { trailingAction?() }) {
                        Image(systemName: trailing)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(theme.colors.surface)
            // 👇 Conditionally show border
            .overlay(
                Group {
                    if showBorder {
                        RoundedRectangle(cornerRadius: theme.cornerRadius)
                            .stroke(
                                errorText != nil ? Color.red : theme.colors.border,
                                lineWidth: errorText != nil ? 1.5 : 1
                            )
                    }
                }
            )
            .cornerRadius(theme.cornerRadius)

            // Inline error text
            if let err = errorText {
                Text(err)
                    .font(theme.typography.caption)
                    .foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true) // allow multi-line
            }
        }
    }
}
