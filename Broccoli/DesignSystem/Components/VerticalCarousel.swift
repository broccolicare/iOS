//
//  VerticalCarousel.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 02/11/25.
//


import SwiftUI

public struct VerticalCarousel<Item: Identifiable, CardView: View>: View {
    private let items: [Item]
    private let visibleCount: Int
    private let spacing: CGFloat
    private let scaleGap: CGFloat
    private let swipeThreshold: CGFloat
    private let maxRotationX: Double
    private let perspective: CGFloat
    private let height: CGFloat
    private let cardBuilder: (Item) -> CardView

    @State private var currentIndex: Int = 0
    @State private var dragTranslation: CGSize = .zero         // used for top card during drag
    @State private var dragRotationX: Double = 0
    @State private var isAnimating: Bool = false
    @State private var topOpacity: Double = 1.0

    // new state for swipe-down incoming overlay
    @State private var overlayPrevItem: Item? = nil
    @State private var overlayPrevOffsetY: CGFloat = 0
    @State private var pushBackOffset: CGFloat = 0            // used to push current card down a bit while prev slides in

    public init(
        items: [Item],
        visibleCount: Int = 4,
        spacing: CGFloat = 14,
        scaleGap: CGFloat = 0.04,
        swipeThreshold: CGFloat = 110,
        maxRotationX: Double = 18,
        perspective: CGFloat = 0.9,
        height: CGFloat = 400,
        @ViewBuilder cardBuilder: @escaping (Item) -> CardView
    ) {
        self.items = items
        self.visibleCount = max(1, visibleCount)
        self.spacing = spacing
        self.scaleGap = scaleGap
        self.swipeThreshold = swipeThreshold
        self.maxRotationX = maxRotationX
        self.perspective = perspective
        self.height = height
        self.cardBuilder = cardBuilder
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                // 1) Main stack: underlying cards including the top card (position 0)
                ForEach(0..<min(visibleCount, items.count), id: \.self) { pos in
                    let idx = index(forPosition: pos)
                    wheelCard(for: items[idx], position: pos, container: geo.size)
                        .zIndex(Double(visibleCount - pos))
                }

                // 2) Overlay for previous item (used only during swipe-down)
                if let prev = overlayPrevItem {
                    cardBuilder(prev)
                        .scaleEffect(1.0) // same scale as top; underlying stacking already handled by main stack
                        .frame(height: cardHeight(for: geo.size))
                        .offset(y: overlayPrevOffsetY)
                        .shadow(color: Color.black.opacity(0.14), radius: 6, x: 0, y: 4)
                        .zIndex(Double(visibleCount + 10))
                        .transition(.identity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .frame(height: height)
    }

    // compute wrapped index for position (0 = top)
    private func index(forPosition pos: Int) -> Int {
        guard items.count > 0 else { return 0 }
        return (currentIndex + pos) % items.count
    }

    // build each card in the stack
    @ViewBuilder
    private func wheelCard(for item: Item, position: Int, container: CGSize) -> some View {
        let posF = CGFloat(position)
        let baseRotation = Double(posF) * (maxRotationX / Double(max(1, visibleCount - 1)))
        let scale = 1.0 - (posF * scaleGap)
        let yOffset = position == 0 ? (dragTranslation.height + pushBackOffset) : (posF * spacing)
        let baseOpacity = 1.0 - Double(min(posF * 0.12, 0.7))
        let finalOpacity = position == 0 ? topOpacity : baseOpacity
        
        cardBuilder(item)
            .scaleEffect(scale)
            .frame(height: cardHeight(for: container))
            .rotation3DEffect(
                .degrees(position == 0 ? dragRotationX : -baseRotation),
                axis: (x: 1, y: 0, z: 0),
                perspective: perspective
            )
            .offset(y: yOffset)
            .rotationEffect(.degrees(Double(dragTranslation.width / 30)))
            .opacity(finalOpacity)
            .shadow(color: Color.black.opacity(0.12 + Double(max(0, (0.05 - Double(posF) * 0.01)))), radius: 6, x: 0, y: 4 - Double(posF))
            .gesture(position == 0 ? topDragGesture(containerHeight: container.height) : nil)
            .transition(.opacity)
    }

    private func cardHeight(for container: CGSize) -> CGFloat {
        return min(300, container.height * 0.36)
    }

    private func topDragGesture(containerHeight: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .local)
            .onChanged { value in
                guard !isAnimating else { return }
                dragTranslation = value.translation
                let normalized = Double(-value.translation.height / max(120, containerHeight / 2))
                dragRotationX = normalized * maxRotationX
                topOpacity = 1.0
            }
            .onEnded { value in
                guard !isAnimating else { return }
                let v = value.translation.height
                if v <= -swipeThreshold {
                    // swipe up -> next card (existing behavior)
                    performTransitionUp(containerHeight: containerHeight)
                } else if v >= swipeThreshold {
                    // swipe down -> show previous by sliding it down from top
                    performTransitionDown(containerHeight: containerHeight)
                } else {
                    // snap back
                    withAnimation(.easeOut(duration: 0.16)) {
                        dragTranslation = .zero
                        dragRotationX = 0
                        topOpacity = 1.0
                    }
                }
            }
    }

    // swipe up: outgoing top card moves up + fade; next card is already below -> becomes top instantly
    private func performTransitionUp(containerHeight: CGFloat) {
        guard items.count > 1 else {
            withAnimation(.easeOut(duration: 0.12)) {
                dragTranslation = .zero
                dragRotationX = 0
                topOpacity = 1.0
            }
            return
        }

        isAnimating = true

        // animate outgoing top card off-screen and fade out
        let offscreenY = -containerHeight * 0.9
        withAnimation(.easeOut(duration: 0.18)) {
            dragTranslation = CGSize(width: 0, height: offscreenY)
            dragRotationX = -maxRotationX * 1.0
            topOpacity = 0.0
        }

        // after outgoing finishes, advance index and reset instantly so the next card (already below) is the top
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            currentIndex = (currentIndex + 1) % items.count
            withAnimation(.none) {
                dragTranslation = .zero
                dragRotationX = 0
                topOpacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                isAnimating = false
            }
        }
    }

    // swipe down: we create an overlay for previous item starting above the view and slide it down into top position.
    // the current (top) card is pushed back to stacked offset during animation; no incoming animation for other cards.
    private func performTransitionDown(containerHeight: CGFloat) {
        guard items.count > 1 else {
            withAnimation(.easeOut(duration: 0.12)) {
                dragTranslation = .zero
                dragRotationX = 0
                topOpacity = 1.0
            }
            return
        }

        isAnimating = true

        // determine previous index
        let prevIndex = (currentIndex - 1 + items.count) % items.count
        let prevItem = items[prevIndex]

        // set up overlay item above the view and invisible (we keep it visible)
        overlayPrevItem = prevItem
        overlayPrevOffsetY = -containerHeight * 0.95
        // push current card down a bit (visual push back)
        pushBackOffset = spacing

        // animate incoming overlay downward to the top position (0)
        withAnimation(.easeOut(duration: 0.20)) {
            overlayPrevOffsetY = 0
            // pushBackOffset is already set — keep as is during animation
        }

        // after overlay finishes sliding down, update currentIndex to prevIndex and remove overlay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            // switch index: previous becomes current
            currentIndex = prevIndex

            // reset states instantly so the overlay is no longer needed; the card that was below is now at position 0
            withAnimation(.none) {
                overlayPrevItem = nil
                overlayPrevOffsetY = 0
                pushBackOffset = 0
                dragTranslation = .zero
                dragRotationX = 0
                topOpacity = 1.0
            }

            // small delay to allow next interactions
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                isAnimating = false
            }
        }
    }
}
