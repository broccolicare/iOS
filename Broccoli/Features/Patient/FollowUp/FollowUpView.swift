//
//  FollowUpView.swift
//  Broccoli
//
//  The post-appointment follow-up check-in screen, opened from the
//  `ai_followup_checkin` notification (push tap or in-app notifications list).
//

import SwiftUI

struct FollowUpView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var router: Router

    @StateObject private var viewModel: FollowUpViewModel

    @State private var composerText: String = ""
    @State private var isPinnedToBottom = true

    private static let bottomAnchor = "followup-bottom"

    init(
        appointmentId: Int,
        followUpService: FollowUpServiceProtocol = FollowUpService()
    ) {
        _viewModel = StateObject(
            wrappedValue: FollowUpViewModel(appointmentId: appointmentId, followUpService: followUpService)
        )
    }

    var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                transcript
                footer
            }
        }
        .navigationBarHidden(true)
        .onDisappear { viewModel.endSession() }
    }

    // MARK: - Header

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

            Text("Follow-up check-in")
                .font(theme.typography.medium20)
                .foregroundStyle(theme.colors.textPrimary)

            Spacer()

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
                    if !viewModel.hasStarted && viewModel.startupError == nil {
                        introCard
                    }

                    ForEach(viewModel.messages) { message in
                        row(for: message)
                    }

                    if viewModel.isAwaitingFirstEvent {
                        TypingIndicatorView(isTakingLonger: viewModel.isTakingLonger)
                    }

                    if viewModel.isComplete {
                        completionCard
                    }

                    Color.clear
                        .frame(height: 1)
                        .id(Self.bottomAnchor)
                        .onAppear { isPinnedToBottom = true }
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.vertical, theme.spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .simultaneousGesture(
                DragGesture().onChanged { _ in isPinnedToBottom = false }
            )
            .onChange(of: viewModel.messages) { _, _ in scrollToBottom(proxy) }
            .onChange(of: viewModel.isAwaitingFirstEvent) { _, _ in scrollToBottom(proxy) }
            .onChange(of: viewModel.isComplete) { _, _ in scrollToBottom(proxy) }
        }
    }

    @ViewBuilder
    private func row(for message: ChatMessage) -> some View {
        switch message.kind {
        case .user(let text):
            ChatBubbleView(role: .user, text: text)

        case .assistant(let text):
            if !text.isEmpty {
                ChatBubbleView(role: .assistant, text: text)
            }

        case .toolCard(let card):
            ChatToolCardView(
                card: card,
                onOpenBooking: { _, _ in },
                onOpenAppointment: { _ in },
                onOpenPrescription: { _ in },
                onSendMessage: { text in send(text) }
            )
            .padding(.leading, 40)

        case .systemNotice(let text):
            notice(text, centred: true)

        case .disclaimer(let text):
            notice(text, centred: false)
                .padding(.leading, 40)
        }
    }

    // MARK: - Intro / completion / error states

    private var introCard: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text("How has it been since your appointment?")
                .font(theme.typography.semiBold16)
                .foregroundStyle(theme.colors.textPrimary)

            Text(
                "A few quick questions so your clinician knows how you're doing. "
                + "It takes a minute, and you can stop and come back — your answers "
                + "are saved as you go."
            )
            .font(theme.typography.regular14)
            .foregroundStyle(theme.colors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)

            Text("This isn't medical advice, and it can't tell you how urgent something is.")
                .font(theme.typography.regular12)
                .foregroundStyle(theme.colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(theme.spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16).fill(theme.colors.surface)
        )
    }

    private var completionCard: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            HStack(spacing: theme.spacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(theme.colors.primary)
                Text("All done")
                    .font(theme.typography.semiBold16)
                    .foregroundStyle(theme.colors.textPrimary)
            }

            Text("Thanks for checking in — your clinician will see your answers.")
                .font(theme.typography.regular14)
                .foregroundStyle(theme.colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(theme.spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16).fill(theme.colors.primary.opacity(0.08))
        )
    }

    private func notice(_ text: String, centred: Bool) -> some View {
        Text(text)
            .font(theme.typography.regular12)
            .foregroundStyle(theme.colors.textSecondary)
            .multilineTextAlignment(centred ? .center : .leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: centred ? .center : .leading)
            .accessibilityLabel(text)
    }

    // MARK: - Footer

    @ViewBuilder
    private var footer: some View {
        VStack(spacing: theme.spacing.sm) {
            if let startupError = viewModel.startupError {
                Text(startupError)
                    .font(theme.typography.regular14)
                    .foregroundStyle(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

            } else if viewModel.isComplete {
                Button {
                    router.pop()
                } label: {
                    Text("Done")
                        .font(theme.typography.medium16)
                        .foregroundStyle(theme.colors.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, theme.spacing.md)
                        .background(Capsule().fill(theme.colors.primary))
                }
                .buttonStyle(.plain)

            } else if !viewModel.hasStarted {
                Button {
                    viewModel.begin()
                } label: {
                    Text("Start")
                        .font(theme.typography.medium16)
                        .foregroundStyle(theme.colors.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, theme.spacing.md)
                        .background(
                            Capsule().fill(
                                viewModel.canSend
                                    ? theme.colors.primary
                                    : theme.colors.primary.opacity(0.35)
                            )
                        )
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canSend)

            } else {
                if viewModel.retryableMessage != nil {
                    retryButton
                }

                ChatComposerView(text: $composerText, isEnabled: viewModel.canSend) {
                    send(composerText)
                }
            }
        }
        .padding(.horizontal, theme.spacing.lg)
        .padding(.top, theme.spacing.md)
        .padding(.bottom, theme.spacing.sm)
        .background(theme.colors.background)
    }

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

#Preview("Not started") {
    NavigationStack {
        FollowUpView(
            appointmentId: 501,
            followUpService: PreviewFollowUpService(script: [])
        )
    }
    .environment(\.appTheme, AppTheme.default)
    .environmentObject(Router.shared)
}

#Preview("Mid check-in") {
    NavigationStack {
        FollowUpView(
            appointmentId: 501,
            followUpService: PreviewFollowUpService(script: [
                .token("Thanks. How would you rate your recovery so far, "),
                .token("on a scale from 1 to 5?"),
                .done(TurnDone(status: .ok, conversationId: 34))
            ])
        )
    }
    .environment(\.appTheme, AppTheme.default)
    .environmentObject(Router.shared)
}

private struct PreviewFollowUpService: FollowUpServiceProtocol {
    let script: [TurnEvent]

    func streamTurn(
        message: String,
        conversationId: Int?,
        appointmentId: Int?
    ) -> AsyncThrowingStream<TurnEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                try? await Task.sleep(for: .seconds(1))
                for event in script {
                    continuation.yield(event)
                    try? await Task.sleep(for: .milliseconds(200))
                }
                continuation.finish()
            }
        }
    }
}
