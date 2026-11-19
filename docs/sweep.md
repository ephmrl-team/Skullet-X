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
pad    = 68 / cos(20°) ≈ 72.4
span   = width + height · tan(20°)
front  = u(reveal.origin) − pad + (span + 2·pad) · progress
```

## The mask

Each pane gets a gradient mask: 17 stops over the 136 pt around the front,
with `ease(t) = (1 − cos(πt)) / 2`.

- **Incoming** content: opaque behind the front, transparent ahead of it. It fills
  in as the front passes.
- **Outgoing** skeleton: the exact inverse — its own mask, not a composited one.
  `alpha_in + alpha_out = 1` at every stop, which `swift test` checks.

Stops are clamped into 0…1 and always non-decreasing, because `CAGradientLayer`
requires it. The gradient axis is the pane's own diagonal: from `(0, 0)` to
`(axis·cos/w, axis·sin/h)` in unit space, where `axis = w·cos + h·sin`, so
`locations` are exactly the fraction along the slant.

The gradient controls opacity only; no white gloss is drawn over the content.

## Pace

A shimmer's loop is measured across 1280 + 320 pt, so a wide screen does not make
it race:

```
pace = shimmerDuration · 0.7 / 1600        // seconds per point
```

Every screen takes about half a second, so panes never sweep at different speeds:

```
speed = (span + 2·pad) / 0.55              // points per second
delay = (from − pad − origin) / speed
duration = (span + 2·pad) / speed
```

Every screen takes 0.55 s: `duration = 0.55 s`, `speed ≈ 1270 pt/s` on 390 × 844,
`delay ≈ −0.02 s` (the front starts a feather before the
reveal, so the reveal begins already slightly into the sweep). Spring progress is
normalized to finish at the end of that duration.

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
| `SweepClock.sweepShare` | how much of the shimmer's loop the sweep takes |
| `SweepClock.wavePace` | kept for API compatibility; the sweep is timed per screen |
| `RevealPolicy.hold` | how long a fast load is hidden from the user |
| `style.shimmerDuration` | the loop; the sweep's pace follows it |

After changing any of them, run `swift test`: the geometry tests pin the front's
endpoints, mask monotonicity, the incoming/outgoing inverse, and the gloss peak.
