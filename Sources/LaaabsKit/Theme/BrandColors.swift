#if os(macOS)
// The laaabs. palette, moved here from the apps' own Theme/ (baaar, taaab and caaapture carried the
// same copy) with the same names, so an app moves onto the kit by deleting its copy. As terminaaal defines it: Two colors do the work: cyan accent and
// absolute black. Everything else is a white-opacity ladder. Never invent shades.

import AppKit
import SwiftUI

public enum BrandColors {
    // MARK: Anchors

    /// Brand cyan, the single accent.
    public static let accent = Color(hex: 0x00B5E2)
    /// Hover and pressed cyan.
    public static let accentDeep = Color(hex: 0x009EC5)
    /// Destructive actions.
    public static let danger = Color(hex: 0xFF453A)
    /// Something that worked: a granted permission.
    public static let success = Color(hex: 0x30D158)
    /// Chrome black.
    public static let surface = Color(hex: 0x0A0A0A)
    /// Primary text and icons.
    public static let on = Color(hex: 0xFFFFFF)

    // MARK: White-opacity ladder

    public static let onSecondary = on.opacity(0.55)
    public static let onTertiary = on.opacity(0.30)
    public static let onDisabled = on.opacity(0.20)
    public static let border = on.opacity(0.20)
    public static let separator = on.opacity(0.12)
    public static let surfaceHover = on.opacity(0.06)
    /// A control on an unknown background: a field, a segmented track.
    public static let surfaceField = on.opacity(0.06)
    /// The recessed groove a control sits in.
    public static let surfaceTrack = on.opacity(0.04)
    /// A selected row or segment. One rung above hover.
    public static let surfaceSelected = on.opacity(0.08)

    // MARK: Tints

    public static let accentWash = accent.opacity(0.06)
    public static let accentSoft = accent.opacity(0.12)
    public static let accentTint = accent.opacity(0.20)
    public static let accentStrong = accent.opacity(0.30)
    public static let accentOutline = accent.opacity(0.55)

    public static let dangerWash = danger.opacity(0.06)
    public static let dangerSoft = danger.opacity(0.12)
    public static let dangerTint = danger.opacity(0.20)
    public static let dangerStrong = danger.opacity(0.30)
    public static let dangerOutline = danger.opacity(0.55)

    // MARK: Shadow

    /// Something floating over the content: the bar, a menu.
    public static let shadowOverlay = Color.black.opacity(0.35)
    /// Something lifted off its own surface by a hair: a dragged chip.
    public static let shadowRaised = Color.black.opacity(0.35)

    // MARK: Solid lines and lifts

    /// `separator` flattened over `surface`, so crossing lines never stack their alpha.
    public static let separatorSolid = Color(hex: 0x272727)
    /// `border` flattened over `surface`.
    public static let borderSolid = Color(hex: 0x3B3B3B)
    /// Cards, the bar.
    public static let surfaceElevated = Color(hex: 0x141414)
    /// Hover and pressed on top of a card.
    public static let surfaceHigh = Color(hex: 0x1A1A1A)

    // MARK: AppKit twins

    public static let nsAccent = NSColor(displayP3Red: 0x00 / 255, green: 0xB5 / 255, blue: 0xE2 / 255, alpha: 1)
    public static let nsSurface = NSColor(srgbRed: 0x0A / 255, green: 0x0A / 255, blue: 0x0A / 255, alpha: 1)
    public static let nsSurfaceElevated = NSColor(srgbRed: 0x14 / 255, green: 0x14 / 255, blue: 0x14 / 255, alpha: 1)
    public static let nsSeparatorSolid = NSColor(srgbRed: 0x27 / 255, green: 0x27 / 255, blue: 0x27 / 255, alpha: 1)
    public static let nsOn = NSColor.white
    public static let nsOnSecondary = NSColor.white.withAlphaComponent(0.55)
    public static let nsSurfaceSelected = NSColor.white.withAlphaComponent(0.08)
    public static let nsSeparator = NSColor.white.withAlphaComponent(0.12)
    public static let nsShadowOverlay = NSColor.black.withAlphaComponent(0.35)
    public static let nsSurfaceHigh = NSColor(srgbRed: 0x1A / 255, green: 0x1A / 255, blue: 0x1A / 255, alpha: 1)
    public static let nsBorderSolid = NSColor(srgbRed: 0x3B / 255, green: 0x3B / 255, blue: 0x3B / 255, alpha: 1)
    public static let nsAccentDeep = NSColor(displayP3Red: 0x00 / 255, green: 0x9E / 255, blue: 0xC5 / 255, alpha: 1)
}

extension Color {
    /// Hex literal (RGB) in Display P3, so the cyan and red render as vividly as the brand
    /// intends. Greys, black and white are identical in P3 and sRGB.
    public init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.displayP3, red: r, green: g, blue: b, opacity: alpha)
    }
}

// MARK: - Hairlines
//
// Every line is one physical pixel: `1 / displayScale`. Borders are drawn as a fill ring, not a
// stroke, which renders heavier.

/// A one-pixel horizontal line.
public struct BrandHLine: View {
    public init(color: Color = BrandColors.separatorSolid) { self.color = color }

    @Environment(\.displayScale) private var scale
    public var color: Color = BrandColors.separatorSolid
    public var body: some View { Rectangle().fill(color).frame(height: 1 / scale) }
}

/// A one-pixel vertical line. `height` nil fills the available height.
public struct BrandVLine: View {
    public init(color: Color = BrandColors.separatorSolid, height: CGFloat? = nil) {
        self.color = color
        self.height = height
    }

    @Environment(\.displayScale) private var scale
    public var color: Color = BrandColors.separatorSolid
    public var height: CGFloat?
    public var body: some View { Rectangle().fill(color).frame(width: 1 / scale, height: height) }
}

extension View {
    /// Fills `fill` and draws a one-pixel ring of `ring` around it, for a self-contained surface.
    public func brandHairlineBorder(
        cornerRadius radius: CGFloat,
        fill: Color = BrandColors.surface,
        ring: Color = BrandColors.separatorSolid
    ) -> some View {
        modifier(BrandHairlineBorder(radius: radius, fill: fill, ring: ring))
    }
}

private struct BrandHairlineBorder: ViewModifier {
    @Environment(\.displayScale) private var scale
    let radius: CGFloat
    let fill: Color
    let ring: Color

    func body(content: Content) -> some View {
        let width = 1 / scale
        return content
            .background(fill, in: RoundedRectangle(cornerRadius: max(radius - width, 0)))
            .padding(width)
            .background(ring, in: RoundedRectangle(cornerRadius: radius))
    }
}
#endif
