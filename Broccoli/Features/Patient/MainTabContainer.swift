//
//  MainTabContainer.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 22/10/25.
//

import SwiftUI

/// App tabs
enum AppTab: Hashable {
    case home, prescription, packages, profile
}

/// A container that shows a content view for each tab and renders a custom tab bar.
struct MainTabContainer<Content: View>: View {
    @Environment(\.appTheme) private var theme

    /// current selected tab
    @Binding var selected: AppTab

    /// Provide the content for each tab via a builder closure
    private let content: (AppTab) -> Content

    init(selected: Binding<AppTab>, @ViewBuilder content: @escaping (AppTab) -> Content) {
        self._selected = selected
        self.content = content
    }

    var body: some View {
        ZStack {
            // Content - Only show the selected tab to avoid initializing all views at once
            Group {
                switch selected {
                case .home:
                    content(.home)
                        .transition(.opacity)
                case .prescription:
                    content(.prescription)
                        .transition(.opacity)
                case .packages:
                    content(.packages)
                        .transition(.opacity)
                case .profile:
                    content(.profile)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: selected)

            // Custom Tab Bar overlay
            VStack {
                Spacer()
                CustomPillTabBar(selected: $selected)
                    .padding(.bottom, safeBottomPadding() > 0 ? safeBottomPadding() - 4 : 10)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .background(theme.colors.background.ignoresSafeArea())
    }

    private func safeBottomPadding() -> CGFloat {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }.flatMap { $0.windows }.first { $0.isKeyWindow }
        return window?.safeAreaInsets.bottom ?? 0
    }
}
