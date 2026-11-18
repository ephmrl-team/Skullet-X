#if canImport(SwiftUI) && canImport(UIKit)
    import SkulletXCore
    import SwiftUI

    public extension View {
        /// Sweeps the skeleton away when `isLoading` turns false.
        ///
        /// ```swift
        /// chatList.skulletReveal(isLoading: store.isLoading) {
        ///     VStack(spacing: 12) {
        ///         ForEach(0..<8, id: \.self) { _ in
        ///             SkeletonBar(height: 14).phase(0.06)
        ///         }
        ///     }
        /// }
        /// ```
        func skulletReveal<Skeleton: View>(
            isLoading: Bool,
            style: SkeletonStyle = SkeletonStyle(),
            @ViewBuilder skeleton: @escaping () -> Skeleton
        ) -> some View {
            modifier(
                SkulletRevealModifier(isLoading: isLoading, style: style, skeleton: skeleton)
            )
        }
    }

    private struct SkulletRevealModifier<Skeleton: View>: ViewModifier {
        let isLoading: Bool
        let style: SkeletonStyle
        let skeleton: () -> Skeleton

        @State private var size: CGSize = .zero
        @State private var clock = SweepClock()
        @State private var shownAt = Date()
        @State private var run: Run?
        @State private var done = false

        private struct Run {
            let start: Date
            let duration: TimeInterval
        }

        func body(content: Content) -> some View {
            TimelineView(.animation(minimumInterval: 1 / 60, paused: run == nil)) { context in
                panes(content: content, at: context.date)
            }
            .background {
                GeometryReader { proxy in
                    Color.clear.preference(key: SkulletSizeKey.self, value: proxy.size)
                }
            }
            .onPreferenceChange(SkulletSizeKey.self) { size = $0 }
            .onAppear {
                shownAt = Date()
                if !isLoading {
                    done = true
                }
            }
            .onChange(of: isLoading) { _, loading in
                if loading {
                    done = false
                    run = nil
                    shownAt = Date()
                } else {
                    reveal()
                }
            }
        }

        @ViewBuilder
        private func panes(content: Content, at date: Date) -> some View {
            let pane = pane
            let progress = progress(at: date)
            ZStack {
                // No size yet: the skeleton is what gives this stack a size, so it goes in unmasked.
                if !done {
                    masked(skeleton(), progress: progress, pane: pane, incoming: false)
                        .accessibilityHidden(true)
                }
                if done {
                    content
                } else {
                    masked(content, progress: progress, pane: pane, incoming: true)
                        .overlay {
                            gloss(progress: progress, pane: pane)
                                .allowsHitTesting(false)
                        }
                        .accessibilityHidden(isLoading)
                }
            }
        }

        @ViewBuilder
        private func masked<V: View>(_ view: V, progress: CGFloat, pane: SweepPane, incoming: Bool) -> some View {
            if size == .zero {
                view
            } else {
                view.mask(mask(progress: progress, pane: pane, incoming: incoming))
            }
        }

        private var pane: SweepPane {
            let box = CGRect(origin: .zero, size: size)
            return SweepPane(rect: box, reveal: box)
        }

        private func progress(at date: Date) -> CGFloat {
            guard let run else { return done ? 1 : 0 }
            return SweepClock.progress(
                now: date.timeIntervalSinceReferenceDate,
                start: run.start.timeIntervalSinceReferenceDate,
                duration: run.duration
            )
        }

        private func reveal() {
            let now = Date()
            let waited = now.timeIntervalSince(shownAt)
            guard size != .zero, waited >= RevealPolicy.hold, style.shimmer != .none,
                  let timing = clock.timing(
                      for: pane,
                      now: now.timeIntervalSinceReferenceDate,
                      shimmerDuration: style.shimmerDuration,
                      screen: UIScreen.main.bounds
                  )
            else {
                done = true
                return
            }

            run = Run(start: now.addingTimeInterval(timing.delay), duration: timing.duration)
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(max(timing.delay, 0) + timing.duration))
                run = nil
                done = true
            }
        }

        private func mask(progress: CGFloat, pane: SweepPane, incoming: Bool) -> some View {
            SweepMaskView(
                stops: SweepGeometry.mask(progress: progress, pane: pane, incoming: incoming),
                size: size,
                white: false
            )
        }

        private func gloss(progress: CGFloat, pane: SweepPane) -> some View {
            SweepMaskView(
                stops: SweepGeometry.gloss(progress: progress, pane: pane),
                size: size,
                white: true
            )
            .opacity(UIAccessibility.isReduceTransparencyEnabled ? 0 : 1)
        }
    }

    private struct SkulletSizeKey: PreferenceKey {
        static var defaultValue: CGSize = .zero
        static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
            value = nextValue()
        }
    }
#endif
