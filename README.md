# Skullet-X

Smart skeleton states for iOS, with the diagonal **sweep** reveal from
[Skullet](https://github.com/lochie/skullet) ported one to one.

UIKit. No Metal, no Objective-C, no measurement magic.

```swift
let reveal = SkulletRevealView()
reveal.setSkeleton(SkeletonChatRowView())   // while loading
reveal.show(contentView)                    // when it arrives
```

While the skeleton is up, one shimmer crosses every bar as a single stream.
When the content lands, a feathered front at 20° sweeps across both, with a
light band trailing it — the skeleton leaves and the content arrives in the same
gesture.

## Install

```swift
.package(url: "https://github.com/ephmrl-team/Skullet-X", from: "0.1.0")
```

iOS 15+, Swift 6 toolchain (Swift 5 language mode). One product, `SkulletX`;
`SkulletXCore` is its platform-free half (import it for the geometry).

## Quick start

```swift
import SkulletX

final class ChatListViewController: UIViewController {
    private let reveal = SkulletRevealView()
    private let list = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(reveal)
        reveal.frame = view.bounds
        reveal.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        reveal.setSkeleton(makeSkeleton())      // skeleton rows
        load()
    }

    private func load() {
        api.chats { [weak self] chats in
            guard let self else { return }
            list.reloadData()
            reveal.show(list)                   // sweeps from the skeleton
        }
    }
}
```

That is the whole integration: one view, two calls.

## Docs

- [Usage](docs/usage.md) — styling, rows, SwiftUI, behaviour, troubleshooting.
- [The sweep](docs/sweep.md) — the geometry and pacing, and what to change.

## What it does

| | |
|---|---|
| Sweep | 20° front, 40 pt feather, 320 pt gloss lagging 120 pt; pace taken from the shimmer |
| Shimmer | one stream across the page: each bar's phase comes from its position |
| Hold | a skeleton up for under 150 ms is never shown |
| Falls back | frames dropping mid-sweep finish as a crossfade; a pane over 1.5 screens crossfades; reduce motion is instant; reduce transparency drops the gloss |

## Not in 0.1

Measuring sample content, remembered shapes, ordering reveals by row, SSR.
Those are most of Skullet's code and none of what a list of chats needs.

## Credits

Geometry and pacing from [Skullet](https://github.com/lochie/skullet) by Lochie
Axon, MIT. See [LICENSE](LICENSE).
