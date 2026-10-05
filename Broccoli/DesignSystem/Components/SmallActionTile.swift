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
    /// Optional remote image URL. When present, this is loaded instead of `backgroundImage`
    /// (which is otherwise treated as a local asset catalog name).
    var backgroundImageUrl: String? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            if let backgroundImageUrl, let url = URL(string: backgroundImageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        ZStack(alignment: .bottom) {
                            GeometryReader { proxy in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .leading)
                                    .clipped()
                            }
                            captionStrip
                        }
                    default:
                        ZStack(alignment: .bottom) {
                            Rectangle().fill(theme.colors.surface)
                            captionStrip
                        }
                    }
                }
            } else {
                Image(backgroundImage)
                    .resizable()
                    .scaledToFill()
                    .clipped()
                captionStrip
            }
        }
        .cornerRadius(20)
        .clipped()
    }

    // Frosted title strip at bottom, used for local placeholder images and as a
    // fallback when a remote image fails to load.
    private var captionStrip: some View {
        Text(title.uppercased())
            .font(theme.typography.semiBold14)
            .fontWeight(.bold)
            .foregroundStyle(.black)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(.white.opacity(0.82))
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
