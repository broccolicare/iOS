//
//  SignUpSuccessView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 16/10/25.
//


import SwiftUI

struct SignUpSuccessView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var router: Router

    var body: some View {
        VStack {
            Spacer()

            // ✅ Success Icon
            Image(systemName: "checkmark.seal.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(theme.colors.lightGreen)
                .padding(.bottom, theme.spacing.lg)

            // ✅ Title
            Text("Congratulations")
                .font(theme.typography.titleXL)
                .fontWeight(.semibold)
                .foregroundStyle(theme.colors.textPrimary)
                .padding(.bottom, theme.spacing.xs)

            // ✅ Subtitle
            Text("Your account has been created. Enjoy care services hassle-free.")
                .font(theme.typography.callout)
                .foregroundStyle(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, theme.spacing.xl)
                .padding(.bottom, theme.spacing.xl)

            Spacer().frame(height: 40)
            

            // ✅ Continue button
            Button(action: {
                // Navigate user to Login screen
                router.setStack([.login])
            }) {
                Text("Continue")
                    .font(theme.typography.button)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(theme.colors.primary)
                    .cornerRadius(theme.cornerRadius)
                    .padding(.horizontal, theme.spacing.lg)
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()
        }
        .background(
            LinearGradient(
                colors: [theme.colors.background, theme.colors.surface.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    SignUpSuccessView()
        .environment(\.appTheme, AppTheme.default)
        .environmentObject(Router.shared)
}
