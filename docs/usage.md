# Usage

## The reveal

`SkulletRevealView` holds one view at a time and animates the swap.

```swift
let reveal = SkulletRevealView()

reveal.setSkeleton(skeletonView)   // the loading state; records when it appeared
reveal.show(contentView)           // the real thing; sweeps, crossfades, or cuts
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
3. The reveal is bigger than 1.5 screens → **crossfade**. A front across it would
   be mostly off screen and costly.
4. Otherwise → **sweep**.

A sweep that sees more than 100 ms between frames gives way to a crossfade from
wherever the front got, so a hitch never leaves a half-masked screen.

## Styling

`SkeletonStyle` is a value type: set what your theme says, leave the rest.

```swift
var style = SkeletonStyle()
style.base = .label.withAlphaComponent(0.07)   // any UIColor; dynamic colours work
style.highlight = .white.withAlphaComponent(0.5)
style.radius = 8
style.avatarSize = 48
style.spacing = 12
style.insets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
style.titleHeight = 14
style.subtitleHeight = 12
style.shimmer = .shimmer                       // .shimmer, .pulse or .none
style.shimmerDuration = SweepClock.shimmerSlow // 4 s; .shimmerFast is 2 s

let reveal = SkulletRevealView()
reveal.style = style
```

Defaults match the web: a translucent grey that reads on light and dark alike, a
white highlight, 6 pt radius, 48 pt avatar.

`shimmer`:

- `.shimmer` — a diagonal band crossing every bar, in one stream across the page.
- `.pulse` — the whole bar fades between 1 and 0.45 opacity.
- `.none` — flat bars; the reveal crossfades instead of sweeping.

Everything holds still under **Reduce Motion**; the gloss is dropped under
**Reduce Transparency**.

## Rows

`SkeletonChatRowView` is a chat row: avatar, title, subtitle, time.

```swift
let row = SkeletonChatRowView()
row.style = style
```

Sizes come from the style (`avatarSize`, `insets`, `spacing`, `titleHeight`,
`subtitleHeight`), laid out in `layoutSubviews` — no Auto Layout, so a hundred
rows cost nothing.

Build a whole list by stacking them:

```swift
func makeSkeleton(rows: Int = 8) -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    for _ in 0..<rows {
        let row = SkeletonChatRowView()
        row.style = style
        stack.addArrangedSubview(row)
        row.heightAnchor.constraint(equalToConstant: 72).isActive = true
    }
    return stack
}
```

For anything else, `SkeletonBarView` is one bar:

```swift
let bar = SkeletonBarView()
bar.style = style
bar.isCircular = true      // an avatar rather than a line
bar.frame = CGRect(x: 16, y: 16, width: 120, height: 14)
```

## SwiftUI

The package ships native SwiftUI views, so nothing is bridged: no
`UIViewRepresentable`, no hosting controllers, no sizing surprises in a `List`.

```swift
import SwiftUI
import SkulletX

struct ChatListScreen: View {
    @Environment(Store.self) private var store

    var body: some View {
        List(store.chats) { chat in
            ChatRow(chat: chat)
        }
        .skulletReveal(isLoading: store.isLoading) {
            VStack(spacing: 0) {
                ForEach(0..<8, id: \.self) { index in
                    SkeletonChatRow()
                        .phase(Double(index) * 0.06)   // one stream down the list
                        .frame(height: 72)
                }
            }
        }
    }
}
```

`.skulletReveal(isLoading:style:skeleton:)`:

- keeps the skeleton up for at least 150 ms, so a fast load never flashes;
- masks the content in and the skeleton out with the same front, gloss included;
- falls back to a plain swap when the shimmer is `.none` or Reduce Motion is on;
- drops its masks when the reveal is over, so nothing stays layered on the content.

Any view can be the skeleton; the two below are the ones that ship.

### `SkeletonChatRow` and `SkeletonBar`

```swift
SkeletonChatRow()                       // avatar, title, subtitle, time
    .phase(0.12)                        // shift its shimmer along the stream

SkeletonBar(width: 120, height: 14)     // one bar; nil width fills
    .phase(0.3)
```

`SkeletonBar(width:height:style:isCircular:)` takes `width: nil` to fill the space
it is given, and `isCircular: true` for avatars.

The SwiftUI views read the same `SkeletonStyle`: colours are exposed as
`baseColor` / `highlightColor`, insets as `edgeInsets`, and everything else is
shared with the UIKit views.

### Mixing

Both halves use one `SkeletonStyle` and one set of numbers, so a screen can be
UIKit and another SwiftUI without the two looking different.

## Tuning

All the numbers live in one place each and are public, so you can read them
without forking:

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
