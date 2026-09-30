# ui-swift

the design kit for macOS and iOS: the marks, the tokens and the components every laaabs. app shares. by laaabs.

```swift
.package(url: "https://github.com/bylaaabs/ui-swift.git", exact: "0.1.0")

import LaaabsKit
Wordmark(.baaar, height: 22)
```

- **marks**: `Wordmark(_:height:ink:dot:)` draws any mark from brand's vectors (`brand/generated/swift`), with the cyan dot, the dot in the ink colour, or any colour. `height` is the height of the letters, as on the web.
- **gallery**: `swift run Gallery`, or `swift run Gallery --png out.png`.
- macOS 26 and iOS 18.

the plan: #1 (this start), #3 (the marks), #2 (tokens and components from baaar, taaab and caaapture), #4 (what the apps need: iOS, the subscription, the paywall).
