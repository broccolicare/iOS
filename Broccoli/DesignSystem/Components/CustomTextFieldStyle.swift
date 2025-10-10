//
//  CustomTextFieldStyle.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 09/10/25.
//
import SwiftUI

struct CustomTextFieldStyle: TextFieldStyle {
    let theme: AppThemeProtocol
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(theme.colors.surface)
            .cornerRadius(theme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(theme.colors.border, lineWidth: 1)
            )
    }
}
