import CoreGraphics
import Foundation
@testable import SkulletXCore
import Testing

private let screen = CGRect(x: 0, y: 0, width: 390, height: 844)

@Test func frontRunsFromAFeatherBeforeToAFeatherPast() {
    let pane = SweepPane(rect: CGRect(x: 0, y: 100, width: 390, height: 200), reveal: screen)
    let from = SweepGeometry.u(pane.reveal.origin)
    let across = SweepGeometry.span(width: pane.reveal.width, height: pane.reveal.height)

    #expect(abs(SweepGeometry.front(progress: 0, pane: pane) - (from - SweepGeometry.pad)) < 0.001)
    #expect(abs(SweepGeometry.front(progress: 1, pane: pane) - (from + across + SweepGeometry.pad)) < 0.001)
}

@Test func maskIsMonotonicAndFadesInFromBehindTheFront() {
    let pane = SweepPane(rect: CGRect(x: 0, y: 100, width: 390, height: 200), reveal: screen)
    let incoming = SweepGeometry.mask(progress: 0.5, pane: pane, incoming: true)

    #expect(incoming.locations.count == SweepGeometry.steps + 3)
    #expect(incoming.locations == incoming.locations.sorted())
    #expect(incoming.locations.first == 0)
    #expect(incoming.locations.last == 1)
    #expect(incoming.alphas.first == 1)
    #expect(incoming.alphas.last == 0)

    let outgoing = SweepGeometry.mask(progress: 0.5, pane: pane, incoming: false)
    #expect(outgoing.alphas.first == 0)
    #expect(outgoing.alphas.last == 1)
    for (index, alpha) in incoming.alphas.enumerated() {
        #expect(abs(alpha + outgoing.alphas[index] - 1) < 0.0001)
    }
}

@Test func maskIsFullyHiddenBeforeAndFullyShownAfter() {
    let pane = SweepPane(rect: CGRect(x: 0, y: 0, width: 390, height: 200), reveal: screen)
    let before = SweepGeometry.mask(progress: 0, pane: pane, incoming: true)
    // The front starts a feather before the reveal, so its first feather already crosses the pane.
    #expect(before.alphas[1] > 0.999)

    let after = SweepGeometry.mask(progress: 1, pane: pane, incoming: true)
    #expect(after.alphas[SweepGeometry.steps + 1] < 0.001)
}

@Test func glossPeaksAtItsLift() {
    let pane = SweepPane(rect: CGRect(x: 0, y: 0, width: 390, height: 200), reveal: screen)
    let gloss = SweepGeometry.gloss(progress: 0.5, pane: pane)
    let peak = gloss.alphas.max() ?? 0

    #expect(abs(peak - SweepGeometry.glossLift) < 0.001)
    #expect(gloss.alphas.first == 0)
    #expect(gloss.alphas.last == 0)
}

@Test func gradientPointsSpanTheSlantAxis() {
    let size = CGSize(width: 390, height: 200)
    let points = SweepGeometry.gradientPoints(for: size)
    let axis = SweepGeometry.axis(width: size.width, height: size.height)

    #expect(points.start == .zero)
    #expect(abs(points.end.x * size.width - axis * SweepGeometry.cosSlant) < 0.001)
    #expect(abs(points.end.y * size.height - axis * SweepGeometry.sinSlant) < 0.001)
}

@Test func paceFollowsTheShimmerLoop() {
    #expect(abs(SweepClock.pace(shimmerDuration: 4) - 4 * 0.7 / 1600) < 0.000001)
    #expect(SweepClock.pace(shimmerDuration: 2) < SweepClock.pace(shimmerDuration: 4))
}

@Test func firstRevealStartsAFrontAtOnce() {
    var clock = SweepClock()
    let pane = SweepPane(rect: CGRect(x: 0, y: 100, width: 390, height: 200), reveal: screen)
    let timing = clock.timing(for: pane, now: 100, shimmerDuration: 4, screen: screen)

    #expect(timing != nil)
    // The front starts a feather before the reveal, so the delay is a little negative.
    #expect((timing?.delay ?? -1) > -0.1)
    #expect((timing?.duration ?? 0) > 0)
    #expect(clock.wave != nil)
}

@Test func aRevealLandingTogetherJoinsTheFrontUnderWay() {
    var clock = SweepClock()
    let first = SweepPane(rect: CGRect(x: 0, y: 0, width: 390, height: 120), reveal: screen)
    let second = SweepPane(rect: CGRect(x: 0, y: 300, width: 390, height: 120), reveal: screen)
    _ = clock.timing(for: first, now: 100, shimmerDuration: 4, screen: screen)
    let origin = clock.wave?.origin
    _ = clock.timing(for: second, now: 100.05, shimmerDuration: 4, screen: screen)

    #expect(clock.wave?.origin == origin)
}

@Test func aLaterRevealStartsItsOwnFront() {
    var clock = SweepClock()
    let first = SweepPane(rect: CGRect(x: 0, y: 0, width: 390, height: 120), reveal: screen)
    let second = SweepPane(rect: CGRect(x: 0, y: 300, width: 390, height: 120), reveal: screen)
    _ = clock.timing(for: first, now: 100, shimmerDuration: 4, screen: screen)
    _ = clock.timing(for: second, now: 101, shimmerDuration: 4, screen: screen)

    #expect(clock.wave?.start == 101)
}

@Test func aRevealBiggerThanAScreenAndAHalfIsNotSwept() {
    var clock = SweepClock()
    let tall = SweepPane(
        rect: CGRect(x: 0, y: 0, width: 390, height: 2000),
        reveal: CGRect(x: 0, y: 0, width: 390, height: 2000)
    )
    #expect(clock.timing(for: tall, now: 0, shimmerDuration: 4, screen: screen) == nil)
}

@Test func policyHoldsBackAFlashAndSweepsTheRest() {
    let pane = SweepPane(rect: CGRect(x: 0, y: 0, width: 390, height: 200), reveal: screen)
    let choose: (CFTimeInterval, Bool, Bool, CFTimeInterval?) -> RevealKind = { waited, input, refetch, shimmer in
        var context = RevealContext(pane: pane, screen: screen)
        context.waited = waited
        context.input = input
        context.refetch = refetch
        context.shimmerDuration = shimmer
        return RevealPolicy.choose(context)
    }

    #expect(choose(0.05, false, false, 4) == .instant)
    #expect(choose(2, true, false, 4) == .instant)
    #expect(choose(2, false, true, 4) == .crossfade)
    #expect(choose(2, false, false, nil) == .crossfade)
    #expect(choose(2, false, false, 4) == .sweep)
}
