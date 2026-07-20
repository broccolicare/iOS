//
//  ChatComposerView.swift
//  Broccoli
//
//  P2-08 — the message composer.
//

import SwiftUI

struct ChatComposerView: View {
    @Environment(\.appTheme) private var theme

    @Binding var text: String

    /// Set false while a turn is in flight (P3-04) or permanently after an
    /// emergency signpost (P5-02). Separate from the empty-text check so the
    /// caller can disable the composer without clearing what the user typed.
    var isEnabled: Bool = true

    let onSend: () -> Void

    private var canSend: Bool {
        isEnabled && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: theme.spacing.md) {
            // Grows to a few lines, then scrolls internally.
            TextField("Message the assistant", text: $text, axis: .vertical)
                .lineLimit(1...5)
                .font(theme.typography.regular16)
                .foregroundStyle(theme.colors.textPrimary)
                .disabled(!isEnabled)
                .padding(.horizontal, theme.spacing.lg)
                .padding(.vertical, theme.spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(theme.colors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(theme.colors.border, lineWidth: 1)
                )
                .accessibilityLabel("Message the assistant")

            Button(action: onSend) {
                Circle()
                    .fill(canSend ? theme.colors.primary : theme.colors.primary.opacity(0.35))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .accessibilityLabel("Send message")
        }
    }
}

#Preview("States") {
    struct Harness: View {
        @State private var empty = ""
        @State private var typed = "I need to book a blood test"
        @State private var disabled = "Sending…"
        @State private var long = "I've had a sore throat for three days now and I'm wondering whether it's worth booking a consultation or just waiting it out a bit longer."

        var body: some View {
            VStack(spacing: 20) {
                ChatComposerView(text: $empty) {}
                ChatComposerView(text: $typed) {}
                ChatComposerView(text: $disabled, isEnabled: false) {}
                ChatComposerView(text: $long) {}
            }
            .padding()
        }
    }
    return Harness().environment(\.appTheme, AppTheme.default)
}
