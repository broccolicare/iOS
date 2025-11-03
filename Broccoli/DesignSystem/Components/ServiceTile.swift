//
//  ServiceTile.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 02/11/25.
//
import SwiftUI

struct ServiceTile: View {
    @Environment(\.appTheme) private var theme
    let item: ServiceItem
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomTrailing) {
                // Background color
                RoundedRectangle(cornerRadius: 16)
                    .fill(item.color)
                
                // Large semi-transparent icon in bottom right
                Image(item.icon)
                    .resizable()
                    .scaledToFit()
                    .opacity(0.10)
                    .frame(width: 86, height: 86)
                    .offset(x: 10, y: 0)
                
                // Content with small icon and title
                VStack(alignment: .leading, spacing: 0) {
                    // White circle with icon on top left
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 48, height: 48)
                        Image(item.icon)
                            .font(.system(size: 20))
                            .foregroundStyle(item.color)
                    }
                    
                    Spacer().frame(height: 22)
                    
                    // Title at bottom left
                    Text(item.title)
                        .font(theme.typography.subtitle)
                        .fontWeight(.medium)
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(20)
            }
            .frame(height: 140)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
