//
//  IntakeProgressBarView.swift
//  Broccoli
//
//  "Question N of M" — driven by the server's `advance_intake` cards.
//

import SwiftUI

/// A thin progress bar under the intake header.
///
/// The chat has no equivalent because it has no end; the intake asks a fixed set
/// of questions, and telling the patient how much is left is what keeps them from
/// abandoning it half way — an abandoned intake yields the clinician nothing.
///
/// ⚠️ The bar can jump several questions at once: the pain follow-ups are skipped
/// wholesale when the patient reports no pain. The denominator deliberately stays
/// put rather than shrinking under them.
struct IntakeProgressBarView: View {
    @Environment(\.appTheme) private var theme

    let progress: IntakeProgressPayload

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text("Question \(progress.position) of \(progress.total)")
                .font(theme.typography.regular12)
                .foregroundStyle(theme.colors.textSecondary)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(theme.colors.primary.opacity(0.12))

                    Capsule()
                        .fill(theme.colors.primary)
                        .frame(width: geometry.size.width * progress.fraction)
                }
            }
            .frame(height: 4)
        }
        .animation(.easeOut(duration: 0.3), value: progress.position)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Question \(progress.position) of \(progress.total)")
    }
}

#Preview {
    VStack(spacing: 24) {
        IntakeProgressBarView(
            progress: IntakeProgressPayload(
                questionId: "onset", outcome: .answered, position: 2, total: 16
            )
        )
        IntakeProgressBarView(
            progress: IntakeProgressPayload(
                questionId: "allergies", outcome: .answered, position: 10, total: 16
            )
        )
    }
    .padding()
    .environment(\.appTheme, AppTheme.default)
}
