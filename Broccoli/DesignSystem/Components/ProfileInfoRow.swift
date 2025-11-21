//
//  ProfileInfoRow.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 06/11/25.
//
import SwiftUI

struct ProfileInfoRow: View {
    let label: String
    let value: String
    var valueColor: Color?
    
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                Text(label)
                    .font(theme.typography.regular14)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(value)
                    .font(theme.typography.medium14)
                    .foregroundStyle(valueColor ?? theme.colors.textPrimary)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}
