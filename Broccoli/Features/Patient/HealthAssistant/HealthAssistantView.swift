//
//  HealthAssistantView.swift
//  Broccoli
//
//  P2-05 / P2-09 / P2-10 — screen shell.
//  P3-09 / P3-10 — scroll behaviour and session teardown.
//

import SwiftUI

struct HealthAssistantView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var router: Router

    /// Feature-scoped and owned here, so the conversation dies with the screen.
    /// See the note on `ChatViewModel` — this is deliberately not a GlobalViewModel.
    @StateObject private var viewModel: ChatViewModel

    @State private var composerText: String = ""

    /// P3-09 — auto-scroll only while the user is at the bottom. Set false the
    /// moment they drag, restored when the bottom sentinel comes back into view.
    @State private var isPinnedToBottom = true

    private static let bottomAnchor = "chat-bottom"

    init(chatService: ChatServiceProtocol = ChatService(sseClient: SSEClient())) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(chatService: chatService))
    }

    var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                transcript

                VStack(spacing: theme.spacing.sm) {
                    if viewModel.retryableMessage != nil {
                        retryButton
                    }

                    ChatComposerView(
                        text: $composerText,
                        isEnabled: viewModel.canSend
                    ) {
                        send(composerText)
                    }

                    disclaimer
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.top, theme.spacing.md)
                .padding(.bottom, theme.spacing.sm)
                .background(theme.colors.background)
            }
        }
        .navigationBarHidden(true)
        // P3-10 — cancel any in-flight stream and drop the conversation id.
        .onDisappear { viewModel.endSession() }
    }

    // MARK: - Header (P2-05)

    private var header: some View {
        HStack {
            Button {
                router.pop()
            } label: {
                Image("BackButton")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.colors.primary)
            }
            .accessibilityLabel("Back")

            Spacer()

            VStack(spacing: 2) {
                Text("Health Assistant")
                    .font(theme.typography.medium20)
                    .foregroundStyle(theme.colors.textPrimary)

                Text("Always available")
                    .font(theme.typography.regular12)
                    .foregroundStyle(theme.colors.primary)
            }

            Spacer()

            // Balances the back button so the title stays optically centred.
            Circle()
                .fill(.clear)
                .frame(width: 40, height: 40)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, theme.spacing.md)
        .background(theme.colors.background)
    }

    // MARK: - Transcript

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    ChatBubbleView(
                        role: .assistant,
                        text: "Hi! I'm your health assistant. I can help you book appointments, set medication reminders, and answer general health questions."
                    )

                    ForEach(viewModel.messages) { message in
                        row(for: message)
                    }

                    if viewModel.isAwaitingFirstEvent {
                        TypingIndicatorView(isTakingLonger: viewModel.isTakingLonger)
                    }

                    if viewModel.showsStarterChips {
                        StarterChipsView { chip in
                            send(chip)
                        }
                        .padding(.top, theme.spacing.xs)
                        // Chips align under the assistant bubble, not the avatar.
                        .padding(.leading, 40)
                    }

                    // Scroll target, and the "is the user at the bottom?" sentinel.
                    // Only `onAppear` flips the flag back on: a programmatic scroll
                    // during a token burst must not be mistaken for the user
                    // scrolling away, so nothing here ever unpins.
                    Color.clear
                        .frame(height: 1)
                        .id(Self.bottomAnchor)
                        .onAppear { isPinnedToBottom = true }
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.vertical, theme.spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            // Any drag is the user taking control — stop yanking the view from
            // under them until they come back to the bottom themselves.
            .simultaneousGesture(
                DragGesture().onChanged { _ in isPinnedToBottom = false }
            )
            .onChange(of: viewModel.messages) { _, _ in
                scrollToBottom(proxy)
            }
            .onChange(of: viewModel.isAwaitingFirstEvent) { _, _ in
                scrollToBottom(proxy)
            }
        }
    }

    @ViewBuilder
    private func row(for message: ChatMessage) -> some View {
        switch message.kind {
        case .user(let text):
            ChatBubbleView(role: .user, text: text)

        case .assistant(let text):
            // A bubble is created on the first token, so it is never empty in
            // practice — but guard anyway rather than render a bare rounded rect.
            if !text.isEmpty {
                ChatBubbleView(role: .assistant, text: text)
            }

        case .toolCard(let card):
            // Phase 4 (P4-01) replaces this with the real card router. Rendering a
            // visible placeholder now keeps P3-08 — cards disappearing when a turn
            // ends guardrail-blocked — observable rather than invisible.
            toolCardPlaceholder(card)

        case .systemNotice(let text):
            systemNotice(text)
        }
    }

    private func toolCardPlaceholder(_ card: ChatToolCard) -> some View {
        Text(card.tool)
            .font(theme.typography.regular12)
            .foregroundStyle(theme.colors.textSecondary)
            .padding(theme.spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.colors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(theme.colors.border, style: StrokeStyle(lineWidth: 1, dash: [4]))
            )
            .padding(.leading, 40)
    }

    private func systemNotice(_ text: String) -> some View {
        Text(text)
            .font(theme.typography.regular12)
            .foregroundStyle(theme.colors.textSecondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacing.xs)
            .accessibilityLabel(text)
    }

    // MARK: - Retry (P3-07)

    /// Only shown for retryable failures, and only ever user-initiated — there is
    /// no idempotency key, so an automatic retry can double-post a turn.
    private var retryButton: some View {
        Button {
            viewModel.retry()
        } label: {
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .semibold))
                Text(
                    viewModel.retryCooldownRemaining > 0
                        ? "Try again in \(viewModel.retryCooldownRemaining)s"
                        : "Try again"
                )
                .font(theme.typography.medium14)
            }
            .foregroundStyle(
                viewModel.retryCooldownRemaining > 0
                    ? theme.colors.textSecondary
                    : theme.colors.primary
            )
            .padding(.horizontal, theme.spacing.lg)
            .padding(.vertical, theme.spacing.sm)
            .background(Capsule().fill(theme.colors.primary.opacity(0.08)))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.retryCooldownRemaining > 0 || !viewModel.canSend)
    }

    // MARK: - Disclaimer (P2-09)

    /// Persistent and outside the ScrollView — it must stay visible at all times,
    /// not scroll away with the transcript.
    private var disclaimer: some View {
        Text("I can't diagnose or prescribe - for medical concerns, book a consultation")
            .font(theme.typography.regular12)
            .foregroundStyle(theme.colors.textSecondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, theme.spacing.sm)
    }

    // MARK: - Actions

    private func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, viewModel.canSend else { return }
        viewModel.send(trimmed)
        composerText = ""
        isPinnedToBottom = true
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        guard isPinnedToBottom else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(Self.bottomAnchor, anchor: .bottom)
        }
    }
}

#Preview("Empty — chips visible") {
    NavigationStack {
        HealthAssistantView(chatService: PreviewChatService(script: []))
    }
    .environment(\.appTheme, AppTheme.default)
    .environmentObject(Router.shared)
}

#Preview("Streaming reply") {
    NavigationStack {
        HealthAssistantView(
            chatService: PreviewChatService(script: [
                .token("You should rest and hydrate. "),
                .token("If it lasts more than a week, it's worth booking a consultation."),
                .done(TurnDone(status: .ok, conversationId: 1))
            ])
        )
    }
    .environment(\.appTheme, AppTheme.default)
    .environmentObject(Router.shared)
}

#Preview("Retryable failure") {
    NavigationStack {
        HealthAssistantView(
            chatService: PreviewChatService(script: [
                .token("Sorry — I couldn't reach that just now."),
                .done(TurnDone(
                    status: .error,
                    conversationId: 1,
                    errorCode: .providerError
                ))
            ])
        )
    }
    .environment(\.appTheme, AppTheme.default)
    .environmentObject(Router.shared)
}

/// Preview-only stand-in for `ChatService`. Replays a fixed script with a short
/// delay so the typing indicator and token accumulation are both visible.
private struct PreviewChatService: ChatServiceProtocol {
    let script: [TurnEvent]

    func streamTurn(message: String, conversationId: Int?) -> AsyncThrowingStream<TurnEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                for event in script {
                    continuation.yield(event)
                    try? await Task.sleep(for: .milliseconds(250))
                }
                continuation.finish()
            }
        }
    }
}
