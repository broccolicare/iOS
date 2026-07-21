//
//  ChatQuickRepliesView.swift
//  Broccoli
//
//  BIC-1.5 — renders an `offer_quick_replies` tool_result as tappable chips.
//
//  Server-driven counterpart to `StarterChipsView`: the assistant streams a set of
//  short answer labels (e.g. the booking flow's care type / time of day), the user
//  taps one, and that label is sent verbatim as the next `message`. Reuses the
//  shared `ChipFlowLayout` so wrapping/Dynamic-Type behaviour matches the rest of
//  the chat.
//
//  One-shot by design: once a chip is tapped it locks (dims the rest, keeps the
//  choice highlighted). The card persists in the transcript, so without this a user
//  could tap the same question twice — or a stale earlier question — and double-post.
//

import SwiftUI

struct ChatQuickRepliesView: View {
    @Environment(\.appTheme) private var theme

    let options: [String]
    /// Invoked with the tapped label, which is then sent as a normal message.
    let onSelect: (String) -> Void

    /// The chosen label, or nil until the user taps. Locks the group once set.
    @State private var selected: String?

    var body: some View {
        ChipFlowLayout(spacing: theme.spacing.sm) {
            ForEach(options, id: \.self) { option in
                Button {
                    guard selected == nil else { return }
                    selected = option
                    onSelect(option)
                } label: {
                    chip(option)
                }
                .buttonStyle(.plain)
                .disabled(selected != nil)
                .accessibilityHint("Sends this as a message")
            }
        }
    }

    @ViewBuilder
    private func chip(_ option: String) -> some View {
        // The tapped chip stays filled; the others fade once a choice is locked in.
        let isChosen = selected == option
        let isDimmed = selected != nil && !isChosen

        Text(option)
            .font(theme.typography.medium14)
            .foregroundStyle(isChosen ? theme.colors.background : theme.colors.primary)
            .padding(.horizontal, theme.spacing.lg)
            .padding(.vertical, theme.spacing.sm + 2)
            .background(
                Capsule().fill(
                    isChosen
                        ? theme.colors.primary
                        : theme.colors.primary.opacity(0.08)
                )
            )
            .overlay(
                Capsule().stroke(theme.colors.primary.opacity(0.25), lineWidth: 1)
            )
            .opacity(isDimmed ? 0.4 : 1)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 24) {
        ChatQuickRepliesView(
            options: ["GP", "Specialist", "Nutritionist", "Blood test"]
        ) { print("tapped \($0)") }

        ChatQuickRepliesView(
            options: ["Morning", "Afternoon", "Evening", "Any time"]
        ) { _ in }
        .environment(\.dynamicTypeSize, .accessibility2)
    }
    .padding()
    .environment(\.appTheme, AppTheme.default)
}
