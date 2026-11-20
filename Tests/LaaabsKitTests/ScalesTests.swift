import SwiftUI
import Testing
@testable import LaaabsKit
#if os(macOS)
import AppKit
#endif

/// spacing runs on a base of 4, from the hairline to 32
@Test func spacingIsOnABaseOfFour() {
    let steps = [BrandSpacing.s2, BrandSpacing.s4, BrandSpacing.s8, BrandSpacing.s12, BrandSpacing.s16, BrandSpacing.s24, BrandSpacing.s32]
    #expect(steps == [2, 4, 8, 12, 16, 24, 32])
    #expect(steps.dropFirst().allSatisfy { $0.truncatingRemainder(dividingBy: 4) == 0 })
}

/// the radii are ui-web's `--radius-6` to `--radius-24`, the same numbers
@Test func theRadiiAreUIWebs() {
    let radii = [BrandRadius.r6, BrandRadius.r8, BrandRadius.r10, BrandRadius.r12, BrandRadius.r14, BrandRadius.r16, BrandRadius.r20, BrandRadius.r24]
    #expect(radii == [6, 8, 10, 12, 14, 16, 20, 24])
}

// the sizes and the shadow below are the macOS ones, read through AppKit; iOS has its own sizes
#if os(macOS)
/// the brand fonts are set at the sizes the scale names, so an app that reads the scale gets the
/// kit's own sizes, and moving a size moves both
@Test @MainActor func theBrandFontsAreSetAtTheScalesSizes() {
    #expect(NSFont.brandBody.pointSize == BrandTypeSize.body)
    #expect(NSFont.brandCallout.pointSize == BrandTypeSize.callout)
    #expect(NSFont.brandCaption.pointSize == BrandTypeSize.caption)
    #expect([BrandTypeSize.display, BrandTypeSize.title, BrandTypeSize.headline, BrandTypeSize.body,
             BrandTypeSize.callout, BrandTypeSize.caption, BrandTypeSize.badge] == [30, 24, 15, 13, 12, 11, 10])
}

/// what floats casts the brand black at the scale's opacity, the value the kit always drew
@Test func theFloatingShadowIsTheOneTheKitDrew() {
    #expect(BrandShadow.opacity == 0.35)
    #expect(BrandShadow.radius == 18 && BrandShadow.y == 6)
    #expect(BrandColors.nsShadowOverlay.alphaComponent == CGFloat(BrandShadow.opacity))
}
#endif
