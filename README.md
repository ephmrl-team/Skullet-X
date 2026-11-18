# Skullet-X

Smart skeleton states for iOS, with the diagonal **sweep** reveal from
[Skullet](https://github.com/lochie/skullet) ported one to one.

UIKit and SwiftUI. No Metal, no Objective-C, no measurement magic, and no
dependency on any app: the package is two libraries and its own tests.

```swift
// SwiftUI
chatList.skulletReveal(isLoading: store.isLoading) {
    VStack(spacing: 12) {
        ForEach(0..<8, id: \.self) { _ in SkeletonBar(height: 14) }
    }
}

// UIKit
reveal.setSkeleton(makeSkeleton())   // stacked SkeletonBarView
reveal.show(contentView)
```

While the skeleton is up, one shimmer crosses every bar as a single stream.
When the content lands, a feathered front at 20° sweeps across both, with a
light band trailing it — the skeleton leaves and the content arrives in the same
gesture.

## Install

```swift
.package(url: "https://github.com/ephmrl-team/Skullet-X", from: "0.3.0")
```

iOS 17+, Swift 6 toolchain (Swift 5 language mode). Products: `SkulletX` (views,
both UI frameworks) and `SkulletXCore` (pure `CoreGraphics`/`Foundation` — the
geometry and timing, testable without a simulator).

## Quick start

### SwiftUI

```swift
import SkulletX
import SwiftUI

struct ChatListScreen: View {
    @Environment(Store.self) private var store

    var body: some View {
        List(store.chats) { chat in
            ChatRow(chat: chat)
        }
        .skulletReveal(isLoading: store.isLoading) {
            VStack(spacing: 12) {
                ForEach(0..<8, id: \.self) { index in
                    HStack(spacing: 12) {
                        SkeletonBar(width: 48, height: 48, isCircular: true)
                            .phase(Double(index) * 0.06)
                        SkeletonBar(height: 14)
                            .phase(Double(index) * 0.06 + 0.02)
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}
```

### UIKit

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

That is the whole integration: one view, two calls (or one modifier).

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
| Same look both ways | one `SkeletonStyle` for UIKit and SwiftUI views |

## Not in 0.3

Measuring sample content, remembered shapes, ordering reveals by row, SSR.
Those are most of Skullet's code and none of what a list of rows needs.

## Credits

Geometry and pacing from [Skullet](https://github.com/lochie/skullet) by Lochie
Axon, MIT. See [LICENSE](LICENSE).
