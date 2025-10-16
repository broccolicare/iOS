//
//  StaticPageView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 13/10/25.
//


import SwiftUI
import WebKit
import AlertToast

struct StaticPageView: View {
    @Environment(\.appTheme) private var theme
    
    let pageType: StaticPageType
    @EnvironmentObject private var appVM: AppGlobalViewModel
    
    @State private var htmlContent: String? = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(pageType: StaticPageType) {
        self.pageType = pageType
    }
    
    var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Text(pageType.title)
                        .font(theme.typography.title)
                        .foregroundStyle(theme.colors.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.top, safeTop() + theme.spacing.md)
                .padding(.bottom, theme.spacing.sm)
                
                Divider()
                
                Text("Loading Content for Page \(pageType.rawValue)") // For accessibility
                
            }
        }
        .toast(isPresenting: $showError, duration: 4.0, tapToDismiss: true) {
            AlertToast(displayMode: .hud, type: .error(theme.colors.error), title: "", subTitle: errorMessage)
        }
        .task(id: pageType) {
            await loadContent()
        }
    }
    
    @MainActor
    private func loadContent() async {
        await appVM.load(page:pageType)
    }
    
    private func safeTop() -> CGFloat {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        return window?.safeAreaInsets.top ?? 20
    }
}
