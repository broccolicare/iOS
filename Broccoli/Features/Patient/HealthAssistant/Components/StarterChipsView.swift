//
//  StarterChipsView.swift
//  Broccoli
//
//  P2-07 — the three starter chips shown before the first user message.
//
//  These chips are now served by the AI backend (`GET /chatbot/starters`) so copy
//  changes ship without an App Store release. This view is purely presentational:
//  the caller passes the chips, `ChatViewModel` fetches them, and
//  `ChatStarters.bundledFallback` covers the pre-fetch paint and any failure — the
//  empty state must never render without chips.
//
//  Still distinct from *server-driven* quick replies (BIC-1.5): those are streamed
//  mid-conversation by the booking flow's `offer_quick_replies` and rendered by
//  `ChatQuickRepliesView` (which reuses `ChipFlowLayout` below). Starters are a
//  static config read fetched once on appear; quick replies come off the
//  `tool_result` stream. Keep the two paths separate.
//

import SwiftUI

struct StarterChipsView: View {
    @Environment(\.appTheme) private var theme

    let chips: [StarterChip]

    /// Invoked with the chip's `message` (not its label), which is then sent as a
    /// normal message.
    let onSelect: (String) -> Void

    var body: some View {
        ChipFlowLayout(spacing: theme.spacing.sm) {
            ForEach(chips) { chip in
                Button {
                    onSelect(chip.message)
                } label: {
                    Text(chip.label)
                        .font(theme.typography.medium14)
                        .foregroundStyle(theme.colors.primary)
                        .padding(.horizontal, theme.spacing.lg)
                        .padding(.vertical, theme.spacing.sm + 2)
                        .background(
                            Capsule().fill(theme.colors.primary.opacity(0.08))
                        )
                        .overlay(
                            Capsule().stroke(theme.colors.primary.opacity(0.25), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityHint("Sends this as a message")
            }
        }
    }
}

/// Minimal flow layout — wraps chips onto a second row when they don't fit.
/// A plain `HStack` would squash or clip them at large Dynamic Type sizes.
/// Shared by `StarterChipsView` and `ChatQuickRepliesView`.
struct ChipFlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var maxRowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth > 0, rowWidth + spacing + size.width > maxWidth {
                maxRowWidth = max(maxRowWidth, rowWidth)
                totalHeight += rowHeight + spacing
                rowWidth = size.width
                rowHeight = size.height
            } else {
                rowWidth += (rowWidth > 0 ? spacing : 0) + size.width
                rowHeight = max(rowHeight, size.height)
            }
        }

        maxRowWidth = max(maxRowWidth, rowWidth)
        totalHeight += rowHeight
        return CGSize(width: min(maxRowWidth, maxWidth), height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 24) {
        StarterChipsView(chips: ChatStarters.bundledFallback.chips) { print("tapped \($0)") }
        StarterChipsView(chips: ChatStarters.bundledFallback.chips) { _ in }
            .environment(\.dynamicTypeSize, .accessibility2)
    }
    .padding()
    .environment(\.appTheme, AppTheme.default)
}
