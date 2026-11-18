# The sweep

The reveal is one diagonal line crossing both panes, not a per-row animation.
Everything here is in `SkulletXCore/SweepGeometry.swift` and
`SkulletXCore/SweepTiming.swift`, and is covered by `swift test`.

## The front

```
        skeleton          content
        ┌───────┐        ┌───────┐
        │░░░░░░ │        │       │
        │░░░░░░ │  ⟋     │       │      ⟋ = the front, 20° from vertical
        │░░░░░░ │        │       │
        └───────┘        └───────┘
```

A point belongs to the front by one coordinate:

```
u = x + y · tan(20°)
```

The front is the line of constant `u`. It travels from a feather before the
reveal to a feather past it:

```
pad    = 40 / cos(20°) ≈ 42.6
span   = width + height · tan(20°)
front  = u(reveal.origin) − pad + (span + 2·pad) · progress
```

## The mask

Each pane gets a gradient mask: 13 stops over the 80 pt either side of the front,
with `ease(t) = (1 − cos(πt)) / 2`.

- **Incoming** content: opaque behind the front, transparent ahead of it. It fills
  in as the front passes.
- **Outgoing** skeleton: the exact inverse — its own mask, not a composited one.
  `alpha_in + alpha_out = 1` at every stop, which `swift test` checks.

Stops are clamped into 0…1 and always non-decreasing, because `CAGradientLayer`
requires it. The gradient axis is the pane's own diagonal: from `(0, 0)` to
`(axis·sin/w, axis·cos/h)` in unit space, where `axis = w·sin + h·cos`, so
`locations` are exactly the fraction along the slant.

## The gloss

A 320 pt band of white trails the front by 120 pt, peaking at 0.45 alpha:

```
centre = front − 120 / cos(20°)
half   = 160 / cos(20°)
alpha  = ease(1 − |2t − 1|) · 0.45
```

It is drawn as a normal-blend white gradient over the incoming pane. That is
mathematically the same as Skullet's `feComponentTransfer` (`slope 1 − 0.45`,
`intercept 0.45`): `c·(1−a) + 255·a`, which is exactly source-over white. No
filter, no shader, no Metal.

## Pace

A shimmer's loop is measured across 1280 + 320 pt, so a wide screen does not make
it race:

```
pace = shimmerDuration · 0.7 / 1600        // seconds per point
```

The sweep runs at twice the shimmer's pace, but never so fast that a reveal takes
more than 360 pt of travel:

```
speed = max(2 / pace, span / 360)          // points per second
delay = (from − pad − origin) / speed
duration = (span + 2·pad) / speed
```

On a 390 × 844 screen with the 4 s shimmer: `speed ≈ 1142 pt/s`,
`duration ≈ 0.68 s`, `delay ≈ −0.04 s` (the front starts a feather before the
reveal, so the reveal begins already slightly into the sweep).

## One front per batch

Reveals landing within 150 ms share a front, so a list arriving at once reads as
one gesture instead of a dozen:

```
joined = now − wave.start ≤ 150 ms
      && the front has not passed this reveal yet
      && waiting for it costs at most 600 pt of travel
```

Otherwise a new front starts at this reveal's `u`. `SweepClock` is a value type;
hold one per screen (or per reveal) and pass the same `now`.

## Falling back

| Situation | What happens |
|---|---|
| More than 100 ms between frames | masks drop, the rest is a crossfade from where the front got |
| Pane bigger than 1.5 screens | crossfade instead of a sweep |
| `style.shimmer == .none` | crossfade — there is no pace to match |
| Reduce Motion | instant |
| Skeleton up under 150 ms | instant, the skeleton is never shown |

## Tuning

| Change | Effect |
|---|---|
| `slantDegrees` | the angle. Bigger is more theatrical, and makes short rows read as a wipe |
| `feather` | softness of the edge. Smaller is a harder, more graphic wipe |
| `glossWidth`, `glossLag` | the band's size and how far behind the front it sits |
| `glossLift` | how bright it is; 0 removes it |
| `SweepClock.sweepShare` | how much of the shimmer's loop the sweep takes |
| `SweepClock.wavePace` | front speed against the shimmer |
| `RevealPolicy.hold` | how long a fast load is hidden from the user |
| `style.shimmerDuration` | the loop; the sweep's pace follows it |

After changing any of them, run `swift test`: the geometry tests pin the front's
endpoints, mask monotonicity, the incoming/outgoing inverse, and the gloss peak.
