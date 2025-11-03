//
//  StatItem.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 02/11/25.
//
import SwiftUI

struct StatItem: View {
    @Environment(\.appTheme) private var theme
    
    let number: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(number)
                .font(theme.typography.bold20)
                .foregroundStyle(theme.colors.primary)
            
            Text(label)
                .font(theme.typography.regular14)
                .foregroundStyle(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HStack(spacing: 0) {
        StatItem(number: "12 Years", label: "Experience")
        
        Divider()
            .frame(height: 40)
            .background(Color.gray.opacity(0.3))
        
        StatItem(number: "1.5K", label: "Patients")
        
        Divider()
            .frame(height: 40)
            .background(Color.gray.opacity(0.3))
        
        StatItem(number: "1.3K", label: "Reviews")
    }
    .padding(.vertical, 20)
    .background(Color.white)
    .cornerRadius(16)
    .padding(.horizontal, 20)
    .environment(\.appTheme, AppTheme.default)
}

