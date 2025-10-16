//
//  CountryPhoneField.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 14/10/25.
//


import SwiftUI

struct CountryPhoneField: View {
    @Environment(\.appTheme) private var theme

    @Binding var countryCode: String
    @Binding var phone: String

    // list of codes to show in selection sheet
    var countryCodes: [String] = ["+1", "+44", "+91", "+353", "+61", "+971", "+86"]

    // optional error text (e.g. from authVM.fieldErrors[.phone])
    var errorText: String?

    // internal temporary selection used by GenericSelectionListView (expects Binding<T?>)
    @State private var tempSelectedCode: String? = nil
    @State private var showCountryPicker: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            // single bordered container around both controls
            HStack(spacing: 12) {
                Button(action: {
                    // set temp selection so the picker opens with current code selected
                    tempSelectedCode = countryCode
                    showCountryPicker.toggle()
                }) {
                    HStack(spacing: 8) {
                        Text(countryCode)
                            .font(theme.typography.callout)
                            .foregroundStyle(theme.colors.textPrimary)
                        Image(systemName: "chevron.down")
                            .imageScale(.small)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 10)
                }
                .buttonStyle(PlainButtonStyle())
                .frame(minWidth: 80, alignment: .leading)

                // vertical divider between code and phone (subtle)
                Rectangle()
                    .frame(width: 1)
                    .foregroundStyle(theme.colors.border)
                    .padding(.vertical, 8)

                // Phone input consumes rest of space
                TextInputField(
                    placeholder: "Enter mobile no.",
                    text: $phone,
                    keyboardType: .phonePad,
                    isSecure: false,
                    leadingSystemImage: nil,
                    trailingSystemImage: nil,
                    errorText: nil,
                    showBorder: false
                )
                .padding(.trailing, 4)
            }
            .padding(.horizontal, 8)
            .background(theme.colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(errorText != nil ? Color.red : theme.colors.border, lineWidth: 1)
            )
            .cornerRadius(theme.cornerRadius)

            // inline error text (multiline)
            if let err = errorText {
                Text(err)
                    .font(theme.typography.caption)
                    .foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
        .sheet(isPresented: $showCountryPicker) {
            GenericSelectionListView<String>(
                selectedValue: $tempSelectedCode,
                title: "Select Country Code",
                items: countryCodes,
                allowsSearch: false
            )
            .onDisappear {
                if let selected = tempSelectedCode {
                    countryCode = selected
                }
            }
        }
    }
}
