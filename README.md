# ui-swift

the design kit for macOS and iOS: the marks, the tokens and the components every laaabs. app shares. by laaabs.

```swift
.package(url: "https://github.com/bylaaabs/ui-swift.git", exact: "0.1.0")

import LaaabsKit
Wordmark(.baaar, height: 22)
```

- **marks**: `Wordmark(_:height:ink:dot:)` draws any mark from brand's vectors (`brand/generated/swift`), with the cyan dot, the dot in the ink colour, or any colour. `height` is the height of the letters, as on the web.
- **the theme** (macOS): `BrandColors`, `BrandFonts` (outfit and geist mono ship in the kit), the controls (`BrandBlock`, `BrandRow`, `BrandToggle`, `BrandSegmented`, `BrandStepper`, `PillButton`, `BrandBadge`, `BrandStatusPill`, `BrandDot`, `ActionChip`, `BrandLink`, `BrandCallout`, `BrandTitleRow`), `BrandMenu` and `BrandShortcutMenu`, `NSWindow.applyBrandChrome`. the same names the apps' own `Theme/` used.
- **shortcuts**: `ShortcutField`, in `LaaabsShortcuts`, apart, because it pulls KeyboardShortcuts 2.4.0.
- **an app's own mark**: set `Wordmark.appMark = .caaapture` at launch, and `Wordmark(height:tint:)` draws it, as the app's `Theme/` did.
- **gallery**: `swift run Gallery`, or `swift run Gallery --png out.png`.

## moving an app onto the kit

1. add the package at an exact tag; `LaaabsShortcuts` too if the app records shortcuts.
2. at launch: `Wordmark.appMark = .<app>`, `BrandFonts.register()`, `BrandMonoFont.register()`.
3. delete the app's `Theme/` (baaar keeps `BarPalette`, which is about its bar, not the look) and its bundled fonts.
4. `import LaaabsKit` where the theme was used. nothing else changes: same names, same parameters, same defaults.
5. screenshots of the app before and after; the only difference allowed is the mark, now drawn from brand's current vector.
- macOS 26 and iOS 18.

the plan: #1 (this start), #3 (the marks), #2 (tokens and components from baaar, taaab and caaapture), #4 (what the apps need: iOS, the subscription, the paywall).
