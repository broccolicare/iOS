//
//  PrimaryButtonView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 08/10/25.
//
import SwiftUI

struct PrimaryButtonView: View {
    @Environment(\.appTheme) private var theme
    let title: String
    
    var body: some View {
        
        Text(title)
            .font(theme.typography.button)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(theme.colors.primary)
            .cornerRadius(theme.cornerRadius)
            .buttonStyle(PlainButtonStyle())
    }
}
