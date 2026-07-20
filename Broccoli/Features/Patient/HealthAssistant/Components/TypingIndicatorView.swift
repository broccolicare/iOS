//
//  TypingIndicatorView.swift
//  Broccoli
//
//  P3-05 — shown from send until the first event arrives.
//
//  ⚠️ This is NOT a typewriter effect, and must never become one. The server runs
//  the whole turn — AI call, tool loop, guardrails, persistence — before it emits a
//  single byte, and sends no keepalive. The socket is silent for up to ~120s and
//  then delivers everything at once. There is nothing to type out progressively;
//  this indicator's entire job is to hold the user's attention across that silence.
//

import SwiftUI

struct TypingIndicatorView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Set after ~15s of silence, so a slow-but-healthy turn doesn't read as a hang.
    var isTakingLonger: Bool = false

    @State private var animating = false

    var body: some View {
        HStack(alignment: .center, spacing: theme.spacing.sm) {
            avatar

            HStack(spacing: theme.spacing.sm) {
                dots

                if isTakingLonger {
                    Text("Still working…")
                        .font(theme.typography.regular12)
                        .foregroundStyle(theme.colors.textSecondary)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, theme.spacing.lg)
            .padding(.vertical, theme.spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(red: 0.94, green: 0.95, blue: 0.96))
            )

            Spacer(minLength: 0)
        }
        .animation(.easeInOut(duration: 0.2), value: isTakingLonger)
        .onAppear { animating = true }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isTakingLonger ? "Assistant is still working" : "Assistant is thinking")
    }

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

    private var dots: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(theme.colors.textSecondary.opacity(0.55))
                    .frame(width: 7, height: 7)
                    .scaleEffect(scale(for: index))
                    .animation(
                        reduceMotion
                            ? nil
                            : .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.18),
                        value: animating
                    )
            }
        }
    }

    private func scale(for index: Int) -> CGFloat {
        // Reduce Motion: hold the dots static rather than pulsing them. The label
        // above still conveys the state to VoiceOver.
        guard !reduceMotion else { return 1 }
        return animating ? 1.25 : 0.75
    }
}

#Preview("Thinking") {
    VStack(alignment: .leading, spacing: 16) {
        TypingIndicatorView()
        TypingIndicatorView(isTakingLonger: true)
    }
    .padding()
    .environment(\.appTheme, AppTheme.default)
}
