// the scales an app lays out with, beside the colours and the fonts (#11): spacing, corner radii,
// the sizes behind the brand fonts and the floating shadow. values only: the kit's components read
// the sizes and the shadow from here and draw exactly what they drew before, so no app changes.
// ui-web keeps its radii in src/tokens.css (`--radius-6` to `--radius-24`); `BrandRadius` is their
// swift twin. radii and spacing are each kit's, not brand's, as ui-web says of its own.

import CoreGraphics

/// spacing on a base of 4, the steps haaarness lays out with: 2 for a hairline, then 4 to 32.
public enum BrandSpacing {
    public static let s2: CGFloat = 2
    public static let s4: CGFloat = 4
    public static let s8: CGFloat = 8
    public static let s12: CGFloat = 12
    public static let s16: CGFloat = 16
    public static let s24: CGFloat = 24
    public static let s32: CGFloat = 32
}

/// corner radii, the twin of ui-web's `--radius-*`. zero, the default, is no rounding at all.
public enum BrandRadius {
    public static let r6: CGFloat = 6
    public static let r8: CGFloat = 8
    public static let r10: CGFloat = 10
    public static let r12: CGFloat = 12
    public static let r14: CGFloat = 14
    public static let r16: CGFloat = 16
    public static let r20: CGFloat = 20
    public static let r24: CGFloat = 24
}

/// the point sizes of the brand fonts (`Font.brandTitle` and the rest), for an app that sets
/// outfit at a role itself. macOS reads smaller than a phone, as apple's own styles do.
public enum BrandTypeSize {
    #if os(macOS)
    public static let display: CGFloat = 30
    public static let title: CGFloat = 24
    public static let headline: CGFloat = 15
    public static let body: CGFloat = 13
    public static let callout: CGFloat = 12
    public static let caption: CGFloat = 11
    public static let badge: CGFloat = 10
    #else
    public static let display: CGFloat = 34
    public static let title: CGFloat = 28
    public static let headline: CGFloat = 17
    public static let body: CGFloat = 17
    public static let callout: CGFloat = 16
    public static let caption: CGFloat = 13
    public static let badge: CGFloat = 12
    #endif
}

/// the shadow of what floats (the tab bar's pill, a menu, a popover): brand black at `opacity`,
/// `y` below, blurred to `radius` as swiftui's `.shadow(radius:)` takes it.
public enum BrandShadow {
    public static let opacity: Double = 0.35
    public static let radius: CGFloat = 18
    public static let y: CGFloat = 6
}
