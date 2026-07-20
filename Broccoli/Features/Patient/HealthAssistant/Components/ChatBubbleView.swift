//
//  ChatBubbleView.swift
//  Broccoli
//
//  P2-06 — assistant and user message bubbles.
//

import SwiftUI

struct ChatBubbleView: View {
    @Environment(\.appTheme) private var theme

    enum Role {
        case assistant
        case user
    }

    let role: Role
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: theme.spacing.sm) {
            switch role {
            case .assistant:
                avatar
                bubble
                // Leave room on the right so a long assistant reply doesn't run
                // edge-to-edge and lose its left/right distinction.
                Color.clear.frame(width: 32)

            case .user:
                Color.clear.frame(width: 32)
                bubble
            }
        }
        .frame(maxWidth: .infinity, alignment: role == .assistant ? .leading : .trailing)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(role == .assistant ? "Assistant said: \(text)" : "You said: \(text)")
    }

    // MARK: - Pieces

    private var avatar: some View {
        Circle()
            .fill(theme.colors.primary)
            .frame(width: 32, height: 32)
            .overlay(
                Image(systemName: "leaf.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            )
            .accessibilityHidden(true)
    }

    private var bubble: some View {
        Text(text)
            .font(theme.typography.regular16)
            .foregroundStyle(textColour)
            // .fixedSize lets the bubble grow vertically for multi-line text
            // instead of truncating, and keeps Dynamic Type working.
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, theme.spacing.lg)
            .padding(.vertical, theme.spacing.md)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(borderColour, lineWidth: role == .user ? 1 : 0)
            )
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(role == .assistant ? assistantFill : Color.white)
    }

    /// Slate — deliberately not a theme colour: the assistant bubble is specific to
    /// this screen and shouldn't drift if a shared surface token is retuned.
    private var assistantFill: Color {
        Color(red: 0.94, green: 0.95, blue: 0.96)
    }

    private var textColour: Color {
        theme.colors.textPrimary
    }

    private var borderColour: Color {
        role == .user ? theme.colors.border : .clear
    }
}

#Preview("Bubbles") {
    ScrollView {
        VStack(spacing: 12) {
            ChatBubbleView(role: .assistant, text: "Hi! How can I help today?")
            ChatBubbleView(role: .user, text: "Short one")
            ChatBubbleView(
                role: .assistant,
                text: "You should rest and hydrate. If the sore throat lasts more than a week, or you develop a high temperature, it's worth booking a consultation so a GP can take a proper look."
            )
            ChatBubbleView(
                role: .user,
                text: "I've had a sore throat for three days now and it doesn't seem to be getting any better."
            )
        }
        .padding()
    }
    .environment(\.appTheme, AppTheme.default)
}

#Preview("Large text") {
    ScrollView {
        VStack(spacing: 12) {
            ChatBubbleView(role: .assistant, text: "Hi! How can I help today?")
            ChatBubbleView(role: .user, text: "I need to book a blood test")
        }
        .padding()
    }
    .environment(\.appTheme, AppTheme.default)
    .environment(\.dynamicTypeSize, .accessibility3)
}
