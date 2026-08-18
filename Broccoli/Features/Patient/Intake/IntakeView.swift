//
//  IntakeView.swift
//  Broccoli
//
//  The pre-appointment questionnaire screen.
//  Contract: docs/ios-integration-guide.md §5.
//

import SwiftUI

/// One appointment's intake questionnaire.
///
/// Reuses the Health Assistant's transcript components wholesale — same bubbles,
/// same typing indicator, same quick-reply chips — because it is the same stream
/// protocol. What differs is the frame around them: a progress bar, an intro that
/// explains why the patient is being asked anything, and an ending. The chat has
/// none of those because it never finishes.
struct IntakeView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var router: Router

    @StateObject private var viewModel: IntakeViewModel

    @State private var composerText: String = ""
    @State private var isPinnedToBottom = true

    private static let bottomAnchor = "intake-bottom"

    /// `doctorName` is display-only — the appointment the intake attaches to is
    /// identified by `appointmentId` alone, and the server re-checks that it
    /// belongs to the caller.
    private let doctorName: String?

    init(
        appointmentId: Int,
        doctorName: String? = nil,
        intakeService: IntakeServiceProtocol = IntakeService()
    ) {
        self.doctorName = doctorName
        _viewModel = StateObject(
            wrappedValue: IntakeViewModel(appointmentId: appointmentId, intakeService: intakeService)
        )
    }

    var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if let progress = viewModel.progress, !viewModel.isComplete {
                    IntakeProgressBarView(progress: progress)
                        .padding(.horizontal, theme.spacing.lg)
                        .padding(.bottom, theme.spacing.sm)
                }

                transcript

                footer
            }
        }
        .navigationBarHidden(true)
        // Cancels the in-flight stream but deliberately keeps the conversation id,
        // so re-entering resumes rather than starting a second intake.
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

            VStack(spacing: 2) {
                Text("Before your appointment")
                    .font(theme.typography.medium20)
                    .foregroundStyle(theme.colors.textPrimary)

                if let doctorName {
                    Text(doctorName)
                        .font(theme.typography.regular12)
                        .foregroundStyle(theme.colors.primary)
                }
            }

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
            // Quick replies are the only card the intake actually emits; the
            // booking/appointment closures are unreachable here and route nowhere
            // rather than pretending to.
            ChatToolCardView(
                card: card,
                onOpenBooking: { _, _ in },
                onOpenAppointment: { _ in },
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
            Text("A few questions before you're seen")
                .font(theme.typography.semiBold16)
                .foregroundStyle(theme.colors.textPrimary)

            Text(
                "Your clinician will read your answers before the appointment, so "
                + "there's less to cover on the call. It takes a few minutes, and "
                + "you can stop and come back — your answers are saved as you go."
            )
            .font(theme.typography.regular14)
            .foregroundStyle(theme.colors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)

            // Set against the module's hard rule: intake gathers, it never assesses.
            // Saying so up front is what stops a patient treating it as triage.
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

            Text("Your answers have been shared with your clinician, who'll read them before your appointment.")
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
                // Not a conversational failure — the questionnaire never opened, so
                // there is nothing to type into and no retry that would help.
                Text(startupError)
                    .font(theme.typography.regular14)
                    .foregroundStyle(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

            } else if viewModel.isComplete {
                // The composer is gone for good. Sending another message would
                // start a *second* intake on this appointment, and its summary
                // would silently supersede the one the clinician already has.
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

    /// Only ever user-initiated — there is no idempotency key, so an automatic
    /// retry can double-post a turn the server actually completed.
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
        IntakeView(
            appointmentId: 501,
            doctorName: "Dr Amelia Hart",
            intakeService: PreviewIntakeService(script: [])
        )
    }
    .environment(\.appTheme, AppTheme.default)
    .environmentObject(Router.shared)
}

#Preview("Mid-questionnaire") {
    NavigationStack {
        IntakeView(
            appointmentId: 501,
            doctorName: "Dr Amelia Hart",
            intakeService: PreviewIntakeService(script: [
                .toolResult(
                    tool: intakeProgressToolName,
                    data: Data(
                        #"{"question_id":"onset","outcome":"answered","position":2,"total":16}"#.utf8
                    )
                ),
                .token("Thanks. Has it got better, worse, "),
                .token("or stayed the same since then?"),
                .done(TurnDone(status: .ok, conversationId: 34))
            ])
        )
    }
    .environment(\.appTheme, AppTheme.default)
    .environmentObject(Router.shared)
}

/// Preview-only stand-in. Replays a fixed script with a short delay so the typing
/// indicator and token accumulation are both visible.
private struct PreviewIntakeService: IntakeServiceProtocol {
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
