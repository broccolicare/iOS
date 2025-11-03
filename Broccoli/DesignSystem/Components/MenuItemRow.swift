//
//  MenuItemRow.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 02/11/25.
//
import SwiftUI

struct MenuItemRow: View {
    @Environment(\.appTheme) private var theme
    let icon: String
    let title: String
    let action: () -> Void
    var isLast: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: action) {
                HStack(spacing: 16) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(icon).frame(width: 20, height: 20)
                        )
                    Text(title)
                        .font(theme.typography.regular16)
                        .foregroundStyle(theme.colors.textPrimary)
                    
                    Spacer()
                    
                    Image("right-arrow-icon")
                        
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            
            if !isLast {
                Divider()
                    .padding(.leading, 56)
            }
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        MenuItemRow(
            icon: "my-reviews-icon",
            title: "My Reviews",
            action: { print("My Reviews tapped") }
        )
        
        MenuItemRow(
            icon: "calendar",
            title: "Appointment History",
            action: { print("Appointment History tapped") }
        )
        
        MenuItemRow(
            icon: "info.circle",
            title: "About Broccoli",
            action: { print("About Broccoli tapped") },
            isLast: true
        )
    }
    .background(Color.white)
    .cornerRadius(12)
    .padding()
    .background(Color(red: 0.96, green: 0.97, blue: 0.98))
    .environment(\.appTheme, AppTheme.default)
}
