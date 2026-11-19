// Typography: Outfit (variable) for all UI, the system monospaced font where a mono role is
// needed. Only three weights are used: 700 headings, 600 buttons and badges, 500 everything else.

#if os(macOS)
import AppKit
#else
import UIKit
#endif
import CoreText
import SwiftUI
import os

/// the kit's own log lines, in the app's process under their own subsystem
let kitLog = Logger(subsystem: "com.laaabs.kit", category: "fonts")

@MainActor
public enum BrandFonts {
    public nonisolated static let family = BrandTokens.Fonts.sans

    private static var isRegistered = false

    /// Registers the bundled Outfit variable font for this process. Call once before the UI is
    /// built; later calls do nothing. No Info.plist key is needed.
    public static func register() {
        guard !isRegistered else { return }
        let name = "Outfit-Variable"
        let candidates = [
            Bundle.module.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts"),
            Bundle.main.url(forResource: name, withExtension: "ttf"),
            Bundle.main.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts"),
            Bundle.main.url(forResource: name, withExtension: "ttf", subdirectory: "Resources/Fonts"),
        ]
        guard let url = candidates.compactMap(\.self).first else {
            kitLog.error("Outfit-Variable.ttf not found in the bundle, falling back to the system font")
            return
        }
        var error: Unmanaged<CFError>?
        if CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
            isRegistered = true
        } else if let error = error?.takeRetainedValue() {
            // Already registered is fine; anything else is worth seeing.
            let code = CFErrorGetCode(error)
            if code == CTFontManagerError.alreadyRegistered.rawValue {
                isRegistered = true
            } else {
                kitLog.error("registering Outfit failed: \(error)")
            }
        }
    }
}

#if os(macOS)
extension NSFont {
    /// Outfit at an explicit size and weight, for views built in AppKit.
    public static func brandOutfit(_ size: CGFloat, weight: NSFont.Weight = .medium) -> NSFont {
        let descriptor = NSFontDescriptor(fontAttributes: [
            .family: BrandFonts.family,
            .traits: [NSFontDescriptor.TraitKey.weight: weight],
        ])
        return NSFont(descriptor: descriptor, size: size) ?? .systemFont(ofSize: size, weight: weight)
    }

    public static var brandBody: NSFont { brandOutfit(BrandTypeSize.body, weight: .medium) }
    public static var brandCallout: NSFont { brandOutfit(BrandTypeSize.callout, weight: .medium) }
    public static var brandCaption: NSFont { brandOutfit(BrandTypeSize.caption, weight: .medium) }
    public static var brandMono: NSFont { .monospacedSystemFont(ofSize: 12, weight: .regular) }
}
#endif

extension Font {
    /// Outfit at an explicit size and weight, anchored to a text style.
    public static func outfit(_ size: CGFloat, weight: Font.Weight = .medium, relativeTo style: Font.TextStyle = .body) -> Font {
        Font.custom(BrandFonts.family, size: size, relativeTo: style).weight(weight)
    }

    #if os(macOS)
    public static var brandDisplay: Font { outfit(BrandTypeSize.display, weight: .bold, relativeTo: .largeTitle) }
    public static var brandTitle: Font { outfit(BrandTypeSize.title, weight: .bold, relativeTo: .title) }
    public static var brandHeadline: Font { outfit(BrandTypeSize.headline, weight: .bold, relativeTo: .headline) }
    public static var brandBody: Font { outfit(BrandTypeSize.body, weight: .medium, relativeTo: .body) }
    public static var brandNav: Font { outfit(BrandTypeSize.body, weight: .medium, relativeTo: .body) }
    public static var brandNavSelected: Font { outfit(BrandTypeSize.body, weight: .semibold, relativeTo: .body) }
    public static var brandCallout: Font { outfit(BrandTypeSize.callout, weight: .medium, relativeTo: .callout) }
    public static var brandButton: Font { outfit(BrandTypeSize.callout, weight: .semibold, relativeTo: .body) }
    public static var brandCaption: Font { outfit(BrandTypeSize.caption, weight: .medium, relativeTo: .caption) }
    public static var brandBadge: Font { outfit(BrandTypeSize.badge, weight: .semibold, relativeTo: .caption) }
    #else
    // the same roles at the sizes a phone reads, apple's text styles set in outfit
    public static var brandDisplay: Font { outfit(BrandTypeSize.display, weight: .bold, relativeTo: .largeTitle) }
    public static var brandTitle: Font { outfit(BrandTypeSize.title, weight: .bold, relativeTo: .title) }
    public static var brandHeadline: Font { outfit(BrandTypeSize.headline, weight: .bold, relativeTo: .headline) }
    public static var brandBody: Font { outfit(BrandTypeSize.body, weight: .medium, relativeTo: .body) }
    public static var brandNav: Font { outfit(BrandTypeSize.body, weight: .medium, relativeTo: .body) }
    public static var brandNavSelected: Font { outfit(BrandTypeSize.body, weight: .semibold, relativeTo: .body) }
    public static var brandCallout: Font { outfit(BrandTypeSize.callout, weight: .medium, relativeTo: .callout) }
    public static var brandButton: Font { outfit(BrandTypeSize.body, weight: .semibold, relativeTo: .body) }
    public static var brandCaption: Font { outfit(BrandTypeSize.caption, weight: .medium, relativeTo: .caption) }
    public static var brandBadge: Font { outfit(BrandTypeSize.badge, weight: .semibold, relativeTo: .caption) }
    #endif
    public static var brandMono: Font { .system(.callout, design: .monospaced) }
}
