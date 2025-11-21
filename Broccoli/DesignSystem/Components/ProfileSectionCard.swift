//
//  ProfileSectionCard.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 06/11/25.
//
import SwiftUI

struct ProfileSectionCard<Content: View>: View {
    let icon: String
    let title: String
    let content: Content
    
    @Environment(\.appTheme) private var theme
    
    init(
        icon: String,
        title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.icon = icon
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack(spacing: 12) {
                Image(icon)
                
                Text(title)
                    .font(theme.typography.bold16)
                    .foregroundStyle(theme.colors.textPrimary)
            }
            
            // Section Content
            content
        }
        .padding(20)
        .background(theme.colors.profileDetailSectionBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}
