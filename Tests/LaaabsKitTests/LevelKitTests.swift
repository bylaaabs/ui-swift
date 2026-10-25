import Foundation
import SwiftUI
import Testing
@testable import LaaabsKit
#if os(macOS)
import AppKit

/// a colour's hex in display p3, the space the kit writes them in
private func hex(_ color: Color) -> UInt32? {
    guard let p3 = NSColor(color).usingColorSpace(.displayP3) else { return nil }
    let byte = { (v: CGFloat) in UInt32((v * 255).rounded()) }
    return byte(p3.redComponent) << 16 | byte(p3.greenComponent) << 8 | byte(p3.blueComponent)
}

private func alpha(_ color: Color) -> CGFloat? {
    NSColor(color).usingColorSpace(.displayP3)?.alphaComponent
}

/// the six levels of paaager draw from the kit: good is success, and attention and important are new
@Test func theLevelColoursAreTheDesigns() {
    #expect(hex(BrandColors.success) == 0x30D158)
    #expect(hex(BrandColors.attention) == 0xFFC300)
    #expect(hex(BrandColors.important) == 0xFF7F00)
    #expect(hex(BrandColors.accent) == 0x00B5E2)
    #expect(hex(BrandColors.danger) == 0xFF453A)
    #expect(hex(BrandColors.attentionText) == 0xFFE58F)
    #expect(hex(BrandColors.importantText) == 0xFFC78F)
}

/// every signal has the same ladder of washes as cyan and red
@Test func theWashesAreTheSameLadder() throws {
    let ladders: [[Color]] = [
        [BrandColors.accentWash, BrandColors.accentSoft, BrandColors.accentTint, BrandColors.accentStrong, BrandColors.accentOutline],
        [BrandColors.successWash, BrandColors.successSoft, BrandColors.successTint, BrandColors.successStrong, BrandColors.successOutline],
        [BrandColors.attentionWash, BrandColors.attentionSoft, BrandColors.attentionTint, BrandColors.attentionStrong, BrandColors.attentionOutline],
        [BrandColors.importantWash, BrandColors.importantSoft, BrandColors.importantTint, BrandColors.importantStrong, BrandColors.importantOutline],
    ]
    for ladder in ladders {
        let alphas = try ladder.map { try #require(alpha($0)) }
        for (got, want) in zip(alphas, [0.06, 0.12, 0.20, 0.30, 0.55]) {
            #expect(abs(got - want) < 0.001)
        }
    }
    #expect(hex(BrandColors.attentionTint) == 0xFFC300)
    #expect(hex(BrandColors.importantSoft) == 0xFF7F00)
}

/// a symbol on the yellow, orange, green and white is black; on cyan and red, white
@Test func theGlyphsAreReadableOnTheirSignal() {
    #expect(hex(BrandColors.attentionGlyph) == 0x000000)
    #expect(hex(BrandColors.importantGlyph) == 0x000000)
    #expect(hex(BrandColors.successGlyph) == 0x000000)
    #expect(hex(BrandColors.onGlyph) == 0x000000)
    #expect(hex(BrandColors.accentGlyph) == 0xFFFFFF)
    #expect(hex(BrandColors.dangerGlyph) == 0xFFFFFF)
    #expect(BrandColors.nsAttention.redComponent == 1)
}
#endif

/// a badge shows nothing for no count, the count, and 99+ past 99
@Test func theTabBadgeSaysTheCount() {
    #expect(BrandTabBadge.text(nil) == nil)
    #expect(BrandTabBadge.text(0) == nil)
    #expect(BrandTabBadge.text(-3) == nil)
    #expect(BrandTabBadge.text(7) == "7")
    #expect(BrandTabBadge.text(99) == "99")
    #expect(BrandTabBadge.text(100) == "99+")
}

/// the central action sits in the middle of the tabs, or where it is put, and never past the ends
@Test func theActionSitsInTheMiddle() {
    let tabs = ["pages", "agents", "team", "settings"]
    #expect(BrandTabSlot.layout(tabs, hasAction: true, at: nil) == [.tab("pages"), .tab("agents"), .action, .tab("team"), .tab("settings")])
    #expect(BrandTabSlot.layout(tabs, hasAction: false, at: nil) == tabs.map { .tab($0) })
    #expect(BrandTabSlot.layout(tabs, hasAction: true, at: 0).first == .action)
    #expect(BrandTabSlot.layout(tabs, hasAction: true, at: 99).last == .action)
    #expect(BrandTabSlot.layout(["one", "two", "three"], hasAction: true, at: nil)[1] == .action)
    #expect(BrandTabSlot.layout([String](), hasAction: true, at: nil) == [.action])
}

/// a tab bar can be built for a selection and says what is where
@MainActor @Test func theBarHoldsItsTabs() {
    let bar = BrandTabBar(selection: .constant("pages"), tabs: [
        BrandTab("pages", symbol: "tray", value: "pages", selectedSymbol: "tray.fill", badge: 7),
        BrandTab("settings", symbol: "gearshape", value: "settings"),
    ], action: BrandTabAction("new page", symbol: "square.and.pencil") {})
    #expect(bar.slots == [.tab("pages"), .action, .tab("settings")])
}

/// one of them: a tap picks it; any of them: a tap brings it in or takes it out, up to the limit
@Test func aTapPicksOrToggles() {
    #expect(BrandChoicePick.single("eu-west-3") == "eu-west-3")
    #expect(BrandChoicePick.multi(Set<Int>(), toggling: 1) == [1])
    #expect(BrandChoicePick.multi([1, 2], toggling: 2) == [1])
    #expect(BrandChoicePick.multi([1, 2], toggling: 3, limit: 2) == [1, 2])
    #expect(BrandChoicePick.multi([1, 2], toggling: 2, limit: 2) == [1])
    #expect(BrandChoicePick.multi([1], toggling: 3, limit: 2) == [1, 3])
}

/// a choice is at least a finger's height on iOS
@Test func aChoiceIsAFingersHeight() {
    #if os(iOS)
    #expect(BrandChoiceMetrics.target >= 44)
    #expect(BrandMenuListMetrics.target >= 44)
    #expect(BrandSheetMetrics.target >= 44)
    #expect(BrandTabMetrics.target >= 44)
    #else
    #expect(BrandChoiceMetrics.target >= 28)
    #endif
}

#if os(iOS)
/// a fitted sheet is its own height while short, half and full when long
@Test func aSheetFitsWhatItHolds() {
    #expect(BrandSheetDetents.detents(.fit, measured: 320) == [.height(320)])
    #expect(BrandSheetDetents.detents(.fit, measured: 900) == [.medium, .large])
    #expect(BrandSheetDetents.detents(.fit, measured: 0) == [.medium])
    #expect(BrandSheetDetents.detents(.half, measured: 100) == [.medium, .large])
    #expect(BrandSheetDetents.detents(.full, measured: 100) == [.large])
}
#endif

/// "done" is said in both languages
@Test(arguments: ["en", "es"]) func theSheetSpeaksBothLanguages(language: String) throws {
    let path = try #require(KitBundle.bundle.path(forResource: language, ofType: "lproj"))
    let bundle = try #require(Bundle(path: path))
    let said = bundle.localizedString(forKey: "done", value: "missing", table: nil)
    #expect(said != "missing")
    if language == "es" { #expect(said == "listo") }
}
