#if os(macOS)
import AppKit
import SwiftUI

// what an app's own Theme/ gave it that is about the app, not the look: its own mark, and whether its
// floating panels show up in screen captures. the app says both once at launch; every call site it
// already has keeps compiling as it is.

public extension Wordmark {
    /// the mark of the app the kit runs in. set it once at launch: `Wordmark.appMark = .caaapture`
    @MainActor static var appMark: WordmarkName = .laaabs

    /// the app's own mark, as every app wrote it before the kit: `Wordmark(height: 22)`. `tint` colours
    /// the letters; the dot stays cyan. the mark is now drawn from brand's vector, not a bundled image.
    @MainActor init(height: CGFloat = 28, tint: Color = BrandColors.on) {
        self.init(Wordmark.appMark, height: height, ink: tint)
    }
}

/// how the kit's floating panels (the context menu, the shortcut menu) take part in screen captures.
/// `.none` keeps them out of any capture, which is what caaapture needs and costs the others nothing.
public enum BrandPanels {
    @MainActor public static var sharingType: NSWindow.SharingType = .none
}
#endif
