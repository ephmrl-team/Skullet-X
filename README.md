# Skullet-X

Smart skeleton states for iOS, with the diagonal **sweep** reveal from
[Skullet](https://github.com/lochie/skullet) ported one to one.

UIKit. No Metal, no Objective-C, no measurement magic.

```swift
let reveal = SkulletRevealView()
reveal.setSkeleton(SkeletonChatRowView())   // while loading
reveal.show(contentView)                    // when it arrives
```

The skeleton is replaced by its content behind one diagonal front: a feathered
edge crossing the reveal, with a light band trailing it.

## What it does

- **Sweep reveal** — a front at 20° from vertical, 40 pt of feather, a 320 pt
  gloss band lagging it by 120 pt. Its pace comes from the shimmer, so both read
  as one gesture. Reveals landing within 150 ms share one front.
- **Shimmer** — one stream across the page: every bar's phase comes from its
  position, so the highlight is continuous rather than per-bar.
- **Holds a fast load back** — a skeleton up for under 150 ms is never shown.
- **Falls back on its own** — frames dropping (> 100 ms) mid-sweep finish as a
  crossfade from where the front got; a pane bigger than 1.5 screens crossfades
  instead of sweeping; reduce motion is instant; reduce transparency drops the
  gloss.

## Install

```swift
.package(url: "https://github.com/ephmrl-team/Skullet-X", from: "0.1.0")
```

`SkulletX` (UIKit) depends on `SkulletXCore` (pure numbers, no UIKit) and
re-exports nothing: import both if you want the geometry.

iOS 15+, Swift 6 toolchain, Swift 5 language mode.

## API

### `SkeletonStyle`

Colours and metrics. Defaults are the web ones: translucent base, white
highlight, 6 pt radius, 48 pt avatar, 12 pt spacing.

```swift
var style = SkeletonStyle()
style.base = Theme.colors.skeleton            // any UIColor, dynamic is fine
style.highlight = .white.withAlphaComponent(0.5)
style.radius = Theme.corner.md
style.shimmer = .shimmer                      // or .pulse, .none
style.shimmerDuration = SweepClock.shimmerSlow
```

### Views

| Type | What |
|---|---|
| `SkeletonBarView` | One rounded bar with the page's shimmer. `isCircular` for avatars. |
| `SkeletonChatRowView` | Avatar, title, subtitle, time — sized from `SkeletonStyle`. |
| `SkulletRevealView` | Holds one view at a time; `setSkeleton` then `show` sweeps between them. |

`SkulletRevealView.reveal` picks the behaviour: `.smart` (default), `.sweep`,
`.crossfade`, `.instant`.

### Core

`SweepGeometry` and `SweepClock` are pure `CoreGraphics` + `Foundation`: the
front position, mask stops, gloss stops, pace, and when a reveal joins the
front under way. They are tested on macOS, without a simulator.

## Using it from SwiftUI

The reveal animates UIKit layers, so it wants a UIView to mask. Until the
SwiftUI modifier lands, wrap the skeleton:

```swift
struct SkeletonRow: UIViewRepresentable {
    func makeUIView(context: Context) -> SkeletonChatRowView { SkeletonChatRowView() }
    func updateUIView(_ view: SkeletonChatRowView, context: Context) {}
}
```

and crossfade to the real content with `.transition(.opacity)`. A native
`.skulletReveal(isLoading:)` modifier is the next thing on the list.

## Tests

```sh
swift test                                   # core geometry and timing, macOS
xcodebuild -scheme SkulletX -destination 'generic/platform=iOS' build
```

## Not in 0.1

Measurement of sample content, remembered shapes, `smart` ordering by row,
SSR, the web component. Those are most of Skullet's code and none of what a
list of chats needs.

## Credits

Geometry and pacing from [Skullet](https://github.com/lochie/skullet) by Lochie
Axon, MIT. See `LICENSE`.
