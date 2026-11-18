#if canImport(UIKit)
    import SkulletXCore
    import UIKit

    /// Swaps a skeleton for its content, sweeping one diagonal front across both.
    ///
    /// ```swift
    /// reveal.setSkeleton(SkeletonChatRowView())
    /// reveal.show(contentView) // content arrives
    /// ```
    public final class SkulletRevealView: UIView {
        /// How content replaces its skeleton.
        public enum Reveal: Equatable, Sendable {
            case smart
            case sweep
            case crossfade
            case instant
        }

        public var style = SkeletonStyle()
        public var reveal: Reveal = .smart

        private var current: UIView?
        private var skeletonSince: CFTimeInterval?
        private var clock = SweepClock()
        private var link: CADisplayLink?
        private var lastTick: CFTimeInterval = 0

        private var incoming: SweepPaneLayer?
        private var outgoing: SweepPaneLayer?
        private var panes: (incoming: SweepPane, outgoing: SweepPane)?
        private var start: CFTimeInterval = 0
        private var duration: CFTimeInterval = 0
        private var leaving: UIView?

        public func setSkeleton(_ view: UIView) {
            guard current !== view else { return }
            install(view)
            skeletonSince = CACurrentMediaTime()
        }

        public func show(_ view: UIView, animated: Bool = true) {
            guard current !== view else { return }
            let old = current
            layoutIfNeeded()
            install(view)
            view.layoutIfNeeded()

            guard animated, !UIAccessibility.isReduceMotionEnabled, let old else {
                old?.removeFromSuperview()
                skeletonSince = nil
                return
            }
            transition(from: old, to: view)
        }

        override public func willMove(toWindow newWindow: UIWindow?) {
            super.willMove(toWindow: newWindow)
            if newWindow == nil {
                stop()
            }
        }

        private func install(_ view: UIView) {
            view.frame = bounds
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(view)
            current = view
        }

        private func transition(from old: UIView, to new: UIView) {
            let now = CACurrentMediaTime()
            let waited = now - (skeletonSince ?? now)
            skeletonSince = nil

            guard let boxes = boxes(from: old, to: new) else {
                old.removeFromSuperview()
                return
            }
            panes = boxes

            switch kind(waited: waited, pane: boxes.incoming) {
            case .instant:
                old.removeFromSuperview()
            case .crossfade:
                crossfade(from: old, to: new)
            case .sweep:
                sweep(from: old, to: new, now: now, pane: boxes.incoming)
            }
        }

        /// Both panes' boxes, and the box the front crosses.
        private func boxes(from old: UIView, to new: UIView) -> (incoming: SweepPane, outgoing: SweepPane)? {
            let box = old.frame.union(new.frame).intersection(bounds)
            guard box.width > 0, box.height > 0 else { return nil }
            return (
                SweepPane(rect: new.frame, reveal: box),
                SweepPane(rect: old.frame, reveal: box)
            )
        }

        private func kind(waited: CFTimeInterval, pane: SweepPane) -> RevealKind {
            if reveal == .instant {
                return .instant
            }
            if reveal == .crossfade {
                return .crossfade
            }
            guard style.shimmer != .none else { return .crossfade }
            var context = RevealContext(pane: pane, screen: window?.bounds ?? UIScreen.main.bounds)
            // `.sweep` was asked for, so a fast load doesn't turn it into a cut.
            context.waited = reveal == .sweep ? .infinity : waited
            context.shimmerDuration = style.shimmerDuration
            return RevealPolicy.choose(context)
        }

        private func crossfade(from old: UIView, to new: UIView) {
            new.alpha = 0
            UIView.animate(withDuration: RevealPolicy.fade, delay: 0, options: [.curveEaseInOut]) {
                new.alpha = 1
                old.alpha = 0
            } completion: { _ in
                old.removeFromSuperview()
            }
        }

        private func sweep(from old: UIView, to new: UIView, now: CFTimeInterval, pane: SweepPane) {
            guard let timing = clock.timing(
                for: pane,
                now: now,
                shimmerDuration: style.shimmerDuration,
                screen: window?.bounds ?? UIScreen.main.bounds
            ) else {
                crossfade(from: old, to: new)
                return
            }

            incoming = SweepPaneLayer(host: new.layer)
            outgoing = SweepPaneLayer(host: old.layer)
            leaving = old
            start = CACurrentMediaTime() + timing.delay
            duration = timing.duration
            lastTick = 0
            old.isUserInteractionEnabled = false
            new.alpha = 1
            old.alpha = 1
            apply(progress: 0)

            let link = CADisplayLink(target: self, selector: #selector(tick))
            link.add(to: .main, forMode: .common)
            self.link = link
        }

        @objc private func tick() {
            guard panes != nil else { stop(); return }
            let now = CACurrentMediaTime()
            let stalled = lastTick > 0 && now - lastTick > SweepClock.stall
            lastTick = now
            let progress = SweepClock.progress(now: now, start: start, duration: duration)
            apply(progress: progress)
            if progress >= 1 || stalled {
                finish(at: progress, stalled: stalled)
            }
        }

        private func apply(progress: CGFloat) {
            guard let panes else { return }
            let glossing = !UIAccessibility.isReduceTransparencyEnabled
            incoming?.apply(progress: progress, pane: panes.incoming, incoming: true, glossing: glossing)
            outgoing?.apply(progress: progress, pane: panes.outgoing, incoming: false, glossing: false)
        }

        private func finish(at progress: CGFloat, stalled: Bool) {
            stop()
            let old = leaving
            leaving = nil
            guard let old else { return }

            guard stalled else {
                old.removeFromSuperview()
                return
            }
            // Frames dropped: the rest as a crossfade, from as far as the front got.
            let rest = RevealPolicy.fade * CFTimeInterval(1 - progress)
            UIView.animate(withDuration: rest, delay: 0, options: [.curveEaseInOut]) {
                old.alpha = 0
            } completion: { _ in
                old.removeFromSuperview()
            }
        }

        private func stop() {
            link?.invalidate()
            link = nil
            incoming?.clear()
            outgoing?.clear()
            incoming = nil
            outgoing = nil
            panes = nil
        }
    }

#endif
