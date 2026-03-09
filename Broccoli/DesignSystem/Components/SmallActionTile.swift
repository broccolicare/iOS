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
    let backgroundImage: String

    var body: some View {
        ZStack(alignment: .bottom) {
            // Full-bleed background photo
            Image(backgroundImage)
                .resizable()
                .scaledToFill()
                .clipped()

            // Frosted title strip at bottom
            Text(title.uppercased())
                .font(theme.typography.semiBold14)
                .fontWeight(.bold)
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(.white.opacity(0.82))
        }
        .cornerRadius(20)
        .clipped()
    }
}

#Preview {
    HStack(spacing: 12) {
        SmallActionTile(
            title: "Medical Tourism",
            backgroundImage: "medical-tourism"
        )
        .frame(height: 130)

        SmallActionTile(
            title: "Cure From Drug",
            backgroundImage: "cure-from-drug"
        )
        .frame(height: 130)
    }
    .padding()
    .environment(\.appTheme, AppTheme.default)
}
