# Usage

The package gives you primitives and a reveal. Every skeleton is yours to build
from bars — the library never guesses your layout.

## The reveal (UIKit)

`SkulletRevealView` holds one view at a time and animates the swap.

```swift
let reveal = SkulletRevealView()

reveal.setSkeleton(skeleton)   // any view; usually a stack of SkeletonBarView
reveal.show(content)           // the real thing: sweeps, crossfades, or cuts
```

- `setSkeleton(_:)` — the skeleton. Calling it again with the same view does nothing.
- `show(_:animated:)` — the content. The old view leaves, the new one arrives. Pass
  `animated: false` for a reload that must not animate.
- Both views are pinned to the reveal's bounds with a flexible autoresizing mask,
  so the reveal takes whatever frame your layout gives it.

`reveal.reveal` picks the behaviour:

| Value | What happens |
|---|---|
| `.smart` (default) | decided per reveal: instant, quick crossfade, or sweep |
| `.sweep` | always a sweep (still crossfades if the pane is over 1.5 screens) |
| `.crossfade` | 200 ms crossfade |
| `.instant` | swap with no animation |

The decision in `.smart`, in order:

1. The skeleton was up for under 150 ms → **instant**. A fast load never flashes.
2. No shimmer (`style.shimmer == .none`) → **crossfade**.
3. The reveal is bigger than 1.5 screens → **crossfade**.
4. Otherwise → **sweep**.

A sweep that sees more than 100 ms between frames gives way to a crossfade from
wherever the front got, so a hitch never leaves a half-masked screen.

## Styling

`SkeletonStyle` carries only what a skeleton cannot decide for itself: colours and
motion. Sizes, spacing and layout belong to your views.

```swift
var style = SkeletonStyle()
style.base = .label.withAlphaComponent(0.07)   // any UIColor; dynamic colours work
style.highlight = .white.withAlphaComponent(0.5)
style.radius = 6
style.shimmer = .shimmer                       // .shimmer, .pulse or .none
style.shimmerDuration = SweepClock.shimmerSlow // 4 s; .shimmerFast is 2 s
```

`shimmer`:

- `.shimmer` — a diagonal band crossing every bar, in one stream across the page.
- `.pulse` — the whole bar fades between 1 and 0.45 opacity.
- `.none` — flat bars; the reveal crossfades instead of sweeping.

Everything holds still under **Reduce Motion**; the gloss is dropped under
**Reduce Transparency**.

## The primitive (UIKit)

`SkeletonBarView` is one bar: a rounded base with the page's shimmer crossing it.

```swift
let bar = SkeletonBarView()
bar.style = style
bar.isCircular = true                 // an avatar rather than a line
bar.frame = CGRect(x: 16, y: 16, width: 48, height: 48)
```

It is a plain `UIView`: give it a frame, or let Auto Layout do it. Corner radius
comes from `style.radius`, capped at half the height; `isCircular` forces a
circle. Set `style` again at any time — the shimmer restarts in phase.

## Building a skeleton

A row is a few bars in a stack — the same paddings and sizes as your real row, so
nothing moves when the content lands.

```swift
func makeSkeleton(style: SkeletonStyle, rows: Int = 8) -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 0

    for _ in 0..<rows {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)

        let avatar = SkeletonBarView()
        avatar.style = style
        avatar.isCircular = true
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.widthAnchor.constraint(equalToConstant: 48).isActive = true
        avatar.heightAnchor.constraint(equalToConstant: 48).isActive = true

        let lines = UIStackView()
        lines.axis = .vertical
        lines.spacing = 8
        for height in [14, 12] {
            let bar = SkeletonBarView()
            bar.style = style
            bar.translatesAutoresizingMaskIntoConstraints = false
            bar.heightAnchor.constraint(equalToConstant: CGFloat(height)).isActive = true
            lines.addArrangedSubview(bar)
        }

        row.addArrangedSubview(avatar)
        row.addArrangedSubview(lines)
        stack.addArrangedSubview(row)
    }
    return stack
}
```

## SwiftUI

Native views: no `UIViewRepresentable`, no hosting controllers, no sizing
surprises in a `List`.

```swift
List(store.chats) { chat in
    ChatRow(chat: chat)
}
.skulletReveal(isLoading: store.isLoading) {
    VStack(spacing: 12) {
        ForEach(0..<8, id: \.self) { index in
            HStack(spacing: 12) {
                SkeletonBar(width: 48, height: 48, isCircular: true)
                    .phase(Double(index) * 0.06)
                VStack(alignment: .leading, spacing: 8) {
                    SkeletonBar(height: 14).phase(Double(index) * 0.06 + 0.02)
                    SkeletonBar(height: 12).phase(Double(index) * 0.06 + 0.04)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}
```

`.skulletReveal(isLoading:style:skeleton:)`:

- keeps the skeleton up for at least 150 ms, so a fast load never flashes;
- masks the content in and the skeleton out with the same front, gloss included;
- falls back to a plain swap when the shimmer is `.none` or Reduce Motion is on;
- drops its masks when the reveal is over, so nothing stays layered on the content.

### `SkeletonBar`

```swift
SkeletonBar(width: 120, height: 14)              // fixed width
SkeletonBar(height: 14)                          // nil width: fills the space
SkeletonBar(width: 48, height: 48, isCircular: true)
    .phase(0.3)                                  // shift its shimmer along the stream
```

`phase(_:)` takes 0…1. Offsetting each row by `Double(index) * 0.06` keeps a list
in one stream instead of a dozen bars pulsing in sync.

Colours come from the same `SkeletonStyle` (`baseColor`, `highlightColor`), so a
UIKit screen and a SwiftUI screen look identical.

## Tuning

All the numbers live in one place each and are public:

```swift
SweepGeometry.slantDegrees   // 20
SweepGeometry.feather        // 40 pt
SweepGeometry.glossWidth     // 320 pt
SweepGeometry.glossLag       // 120 pt
SweepGeometry.glossLift      // 0.45
SweepClock.sweepShare        // 0.7 of the shimmer loop
SweepClock.wavePace          // 2× the shimmer's pace
SweepClock.batchWindow       // 150 ms
RevealPolicy.hold            // 150 ms
RevealPolicy.fade            // 200 ms
```

See [the sweep](sweep.md) for what each one does to the picture.

## Troubleshooting

**Nothing animates, the content just appears.** The skeleton was up for less than
150 ms (that is by design), the style's `shimmer` is `.none`, or Reduce Motion is
on.

**A sweep looks like a crossfade.** The reveal is bigger than 1.5 screens, or
frames dropped during it.

**The skeleton has no shimmer.** `style.shimmerDuration` is 0, or the bars are
off screen: the phase comes from the bar's position in the window.

**The reveal is blank for a moment.** `show(_:)` was called before the incoming
view had a frame; give it a size (or call it after `layoutIfNeeded()`).

## Tests

```sh
swift test                                                              # core, macOS
xcodebuild -scheme SkulletX -destination 'generic/platform=iOS' build   # UIKit
```
