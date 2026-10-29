// The laaabs. palette, moved here from the apps' own Theme/ (baaar, taaab and caaapture carried the
// same copy) with the same names, so an app moves onto the kit by deleting its copy. As terminaaal defines it: Two colors do the work: cyan accent and
// absolute black. Everything else is a white-opacity ladder. Never invent shades.
// The solid values come from brand (tokens/tokens.json, generated as `BrandTokens`), the one source
// for every kit; a hex is never typed here, only tints and the ladder are derived.

#if os(macOS)
import AppKit
#else
import UIKit
#endif
import SwiftUI

public enum BrandColors {
    // MARK: Anchors

    /// Brand cyan, the single accent.
    public static let accent = Color(hex: BrandTokens.Colors.accent)
    /// Hover and pressed cyan.
    public static let accentDeep = Color(hex: BrandTokens.Colors.accentDeep)
    /// Destructive actions.
    public static let danger = Color(hex: BrandTokens.Colors.danger)
    /// Something that worked: a granted permission. paaager's good level.
    public static let success = Color(hex: BrandTokens.Colors.success)
    /// Something that needs a look soon: paaager's attention level. A signal, never a surface.
    public static let attention = Color(hex: BrandTokens.Colors.attention)
    /// Something that needs a look now, before it is urgent: paaager's important level. A signal,
    /// never a surface.
    public static let important = Color(hex: BrandTokens.Colors.important)
    /// Chrome black.
    public static let surface = Color(hex: BrandTokens.Colors.surface)
    /// Primary text and icons.
    public static let on = Color(hex: BrandTokens.Colors.on)

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

    public static let successWash = success.opacity(0.06)
    public static let successSoft = success.opacity(0.12)
    public static let successTint = success.opacity(0.20)
    public static let successStrong = success.opacity(0.30)
    public static let successOutline = success.opacity(0.55)

    public static let attentionWash = attention.opacity(0.06)
    public static let attentionSoft = attention.opacity(0.12)
    public static let attentionTint = attention.opacity(0.20)
    public static let attentionStrong = attention.opacity(0.30)
    public static let attentionOutline = attention.opacity(0.55)
    /// Text on an attention tint, as `accentText` is on a cyan one: the colour 56 % of the way to white.
    public static let attentionText = Color(hex: BrandTokens.Colors.attentionText)

    public static let importantWash = important.opacity(0.06)
    public static let importantSoft = important.opacity(0.12)
    public static let importantTint = important.opacity(0.20)
    public static let importantStrong = important.opacity(0.30)
    public static let importantOutline = important.opacity(0.55)
    /// Text on an important tint: the colour 56 % of the way to white.
    public static let importantText = Color(hex: BrandTokens.Colors.importantText)

    // MARK: Glyphs on a solid signal

    /// A symbol drawn on solid cyan (a level circle, the central tab action).
    public static let accentGlyph = Color.white
    /// A symbol drawn on solid red.
    public static let dangerGlyph = Color.white
    /// A symbol drawn on solid green: the yellow-greens need black to be read.
    public static let successGlyph = Color.black
    /// A symbol drawn on solid attention yellow.
    public static let attentionGlyph = Color.black
    /// A symbol drawn on solid important orange.
    public static let importantGlyph = Color.black
    /// A symbol drawn on solid white (paaager's info level).
    public static let onGlyph = Color.black

    // MARK: Shadow

    /// Something floating over the content: the bar, a menu.
    public static let shadowOverlay = Color.black.opacity(0.35)
    /// Something lifted off its own surface by a hair: a dragged chip.
    public static let shadowRaised = Color.black.opacity(0.35)

    // MARK: Solid lines and lifts

    /// `separator` flattened over `surface`, so crossing lines never stack their alpha.
    public static let separatorSolid = Color(hex: BrandTokens.Colors.separatorSolid)
    /// `border` flattened over `surface`.
    public static let borderSolid = Color(hex: BrandTokens.Colors.borderSolid)
    /// Cards, the bar.
    public static let surfaceElevated = Color(hex: BrandTokens.Colors.surfaceElevated)
    /// Hover and pressed on top of a card.
    public static let surfaceHigh = Color(hex: BrandTokens.Colors.surfaceHigh)

    #if os(macOS)
    // MARK: AppKit twins

    public static let nsAccent = NSColor(displayP3Hex: BrandTokens.Colors.accent)
    public static let nsSurface = NSColor(srgbHex: BrandTokens.Colors.surface)
    public static let nsSurfaceElevated = NSColor(srgbHex: BrandTokens.Colors.surfaceElevated)
    public static let nsSeparatorSolid = NSColor(srgbHex: BrandTokens.Colors.separatorSolid)
    public static let nsOn = NSColor.white
    public static let nsOnSecondary = NSColor.white.withAlphaComponent(0.55)
    public static let nsSurfaceSelected = NSColor.white.withAlphaComponent(0.08)
    public static let nsSeparator = NSColor.white.withAlphaComponent(0.12)
    public static let nsShadowOverlay = NSColor.black.withAlphaComponent(0.35)
    public static let nsSurfaceHigh = NSColor(srgbHex: BrandTokens.Colors.surfaceHigh)
    public static let nsBorderSolid = NSColor(srgbHex: BrandTokens.Colors.borderSolid)
    public static let nsAccentDeep = NSColor(displayP3Hex: BrandTokens.Colors.accentDeep)
    public static let nsDanger = NSColor(displayP3Hex: BrandTokens.Colors.danger)
    public static let nsSuccess = NSColor(displayP3Hex: BrandTokens.Colors.success)
    public static let nsAttention = NSColor(displayP3Hex: BrandTokens.Colors.attention)
    public static let nsImportant = NSColor(displayP3Hex: BrandTokens.Colors.important)
    #endif
}

#if os(macOS)
extension NSColor {
    /// A brand token in Display P3: the cyan and the signals.
    fileprivate convenience init(displayP3Hex hex: UInt32) {
        self.init(
            displayP3Red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }

    /// A brand token in sRGB: the greys, identical in either space.
    fileprivate convenience init(srgbHex hex: UInt32) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}
#endif

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
