//
//  SmallActionTile.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 02/11/25.
//
import SwiftUI

struct SmallActionTile: View {
    @Environment(\.appTheme) private var theme
    let title: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack{
                Image(icon)
                    .resizable()
                    .scaledToFill()
                    .foregroundStyle(theme.colors.primary)
                    .frame(width: 28, height: 28)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(theme.colors.primary.opacity(0.1))
                    )
                Spacer()
            }
            Text(title)
                .font(theme.typography.medium18)
        }
        .padding()
        .background(theme.colors.surface)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(theme.colors.border))
    }
}

#Preview {
    HStack(spacing: 12) {
        SmallActionTile(
            title: "Medical Tourism",
            icon: "medical-tourism-icon"
        )
        .frame(height: 100)
        
        SmallActionTile(
            title: "Cure From Drug",
            icon: "cure-from-drug-icon"
        )
        .frame(height: 100)
    }
    .padding()
    .environment(\.appTheme, AppTheme.default)
}
