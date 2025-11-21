//
//  DoctorInfoRow.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 20/11/25.
//
import SwiftUI

struct DoctorInfoRow: View {
    @Environment(\.appTheme) private var theme
    let label: String
    let value: String
    let showDivider: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                Text(label)
                    .font(theme.typography.medium16)
                    .foregroundStyle(theme.colors.textPrimary)
                    .frame(width: 140, alignment: .leading)
                
                Spacer()
                
                Text(value)
                    .font(theme.typography.medium16)
                    .foregroundStyle(theme.colors.profileDetailTextColor)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.vertical, 12)
            
            if showDivider {
                Divider()
                    .padding(.horizontal, 16)
            }
        }
    }
}
