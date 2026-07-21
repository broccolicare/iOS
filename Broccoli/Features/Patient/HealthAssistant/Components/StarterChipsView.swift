//
//  StarterChipsView.swift
//  Broccoli
//
//  P2-07 — the three starter chips shown before the first user message.
//
//  ⚠️ These are LOCAL STATIC UI and stay that way — this is a decision, not a
//  deferral (plan §2.2). Two contract facts make it the only option:
//
//   1. There is no "create conversation" call, so nothing can stream before the
//      user's first message — there is no moment at which the server could supply
//      chips for this screen.
//   2. `offer_quick_replies` is intake-exclusive; the chatbot tool set has no
//      quick-reply tool at all (guide §4.1).
//
//  Do not build a server-driven chip renderer here. That belongs to intake.
//

import SwiftUI

struct StarterChipsView: View {
    @Environment(\.appTheme) private var theme

    static let chips = ["Book appointment", "My appointments", "Set reminder", "Health tips"]

    /// Invoked with the chip's label, which is then sent as a normal message.
    let onSelect: (String) -> Void

    var body: some View {
        ChipFlowLayout(spacing: theme.spacing.sm) {
            ForEach(Self.chips, id: \.self) { chip in
                Button {
                    onSelect(chip)
                } label: {
                    Text(chip)
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
private struct ChipFlowLayout: Layout {
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
        StarterChipsView { print("tapped \($0)") }
        StarterChipsView { _ in }
            .environment(\.dynamicTypeSize, .accessibility2)
    }
    .padding()
    .environment(\.appTheme, AppTheme.default)
}
