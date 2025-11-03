//
//  CustomPillTabBar.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 22/10/25.
//
import SwiftUI

struct CustomPillTabBar: View {
    @Environment(\.appTheme) private var theme
    @Binding var selected: AppTab

    var body: some View {
        HStack(spacing: 2) {
            tabButton(tab: .home, icon: "house.fill", title: "Home")
            tabButton(tab: .prescription, icon: "pills.fill", title: "Prescription")
            tabButton(tab: .packages, icon: "doc.plaintext", title: "Packages")
            tabButton(tab: .profile, icon: "person.crop.circle", title: "Profile")
        }
        .padding(5)
        .frame(height: 60)
        .background(theme.colors.surface)           // pill background
        .cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(theme.colors.border))
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }

    @ViewBuilder
    private func tabButton(tab: AppTab, icon: String, title: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selected = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(theme.typography.regular12)
                    .foregroundStyle(selected == tab ? .white : theme.colors.textSecondary)
                Text(title)
                    .font(theme.typography.caption)
                    .foregroundStyle(selected == tab ? .white : theme.colors.textSecondary)
            }
            .frame(minWidth: 80)
            .frame(height: 38)
            .padding(.vertical, 6)
            .padding(.horizontal, 6)
            .background(selected == tab ? theme.colors.primary : Color.clear)
            .cornerRadius(26)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
