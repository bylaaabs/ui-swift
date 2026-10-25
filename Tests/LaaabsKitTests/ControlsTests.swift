import Foundation
import SwiftUI
import Testing
@testable import LaaabsKit

private let times = (0 ..< 48).map { BrandSelectOption(String(format: "%02d:%02d", $0 / 2, $0 % 2 * 30), value: $0 * 30) }
private let sounds = [
    BrandSelectSection("laaabs.", options: [BrandSelectOption("chime", value: "chime"), BrandSelectOption("knock", value: "knock")]),
    BrandSelectSection("the system", options: [BrandSelectOption("glass", value: "glass"), BrandSelectOption("Ñu", value: "nu")]),
]

/// the arrows walk every row across sections and stop at the ends
@Test func theArrowsWalkTheRowsAndStopAtTheEnds() {
    let rows = BrandSelectRows(sounds)
    #expect(rows.options.map(\.value) == ["chime", "knock", "glass", "nu"])
    #expect(rows.sectionStarts == [0, 2])
    #expect(rows.move(from: 1, by: 1) == 2)
    #expect(rows.move(from: 3, by: 1) == 3)
    #expect(rows.move(from: 0, by: -1) == 0)
    #expect(rows.move(from: nil, by: 1) == 0)
    #expect(rows.move(from: nil, by: -1) == 3)
    #expect(BrandSelectRows<String>([]).move(from: nil, by: 1) == nil)
}

/// typing finds the row that starts with it, ignoring case and accents, then one that has it
@Test func typingJumpsToTheRow() {
    let rows = BrandSelectRows(sounds)
    #expect(rows.match("GL") == 2)
    #expect(rows.match("nu") == 3)
    #expect(rows.match("ock") == 1)
    #expect(rows.match("zz") == nil)
    #expect(rows.match(" ") == nil)
    #expect(BrandSelectRows([BrandSelectSection(options: times)]).match("07:3") == 15)
}

/// the letters add up while typed quickly and start again after a pause
@Test func theTypedLettersStartAgainAfterAPause() {
    var ahead = BrandTypeAhead()
    let now = Date()
    #expect(ahead.add("0", at: now) == "0")
    #expect(ahead.add("7", at: now.addingTimeInterval(0.4)) == "07")
    #expect(ahead.add("2", at: now.addingTimeInterval(2)) == "2")
}

/// "every x" is the first option, means nil, and a filter lights only when it narrows
@MainActor @Test func everyIsTheFirstOptionAndLeavesTheFilterUnlit() {
    let levels = ["info", "urgent"].map { BrandSelectOption($0, value: $0) }
    let all = BrandSelect(selection: .constant(String?.none), every: "every level", options: levels)
    #expect(all.rows.options.map(\.label) == ["every level", "info", "urgent"])
    #expect(all.rows.options.first?.value == nil)
    #expect(all.current?.label == "every level")
    #expect(!all.isLit)
    let urgent = BrandSelect(selection: .constant(Optional("urgent")), every: "every level", options: levels)
    #expect(urgent.isLit)
    #expect(urgent.current?.label == "urgent")
    // a field never lights, whatever is chosen
    #expect(!BrandSelect(selection: .constant(90), options: times).isLit)
}

/// the panel is as tall as its rows, titles and separators
@Test func thePanelIsAsTallAsItsRows() {
    let one = BrandSelectMetrics.height([BrandSelectSection(options: Array(times.prefix(3)))])
    #expect(one == BrandSelectMetrics.padding * 2 + 3 * BrandSelectMetrics.rowHeight + 2 * BrandSelectMetrics.rowSpacing)
    #expect(BrandSelectMetrics.height(sounds) > one)
    #if os(macOS)
    // 48 half hours scroll inside a panel that stays a panel
    #expect(BrandSelectMetrics.height([BrandSelectSection(options: times)]) > BrandSelectMetrics.maxHeight)
    #endif
}

/// a multi line field grows to its limit, and never below one line
@Test func aMultiLineFieldGrowsToItsLimit() {
    #expect(BrandTextFieldKind.single.lines == 1 ... 1)
    #expect(BrandTextFieldKind.secure.lines == 1 ... 1)
    #expect(BrandTextFieldKind.multiline(maxLines: 4).lines == 1 ... 4)
    #expect(BrandTextFieldKind.multiline(maxLines: 0).lines == 1 ... 1)
}

/// the clear button shows only when asked for and there is text
@MainActor @Test func theClearButtonShowsOnlyWithText() {
    #expect(BrandTextField("search", text: .constant("x"), clearable: true).showsClear)
    #expect(!BrandTextField("search", text: .constant(""), clearable: true).showsClear)
    #expect(!BrandTextField("search", text: .constant("x")).showsClear)
}

/// the arrows in a list stop at the ends, and start at the top
@Test func theArrowsInAListStopAtTheEnds() {
    let ids = [10, 20, 30]
    #expect(BrandListRows.step(ids, from: 20, by: 1) == 30)
    #expect(BrandListRows.step(ids, from: 30, by: 1) == 30)
    #expect(BrandListRows.step(ids, from: 10, by: -1) == 10)
    #expect(BrandListRows.step(ids, from: nil, by: 1) == 10)
    #expect(BrandListRows.step(ids, from: 99, by: 1) == 10)
    #expect(BrandListRows.step([Int](), from: nil, by: 1) == nil)
}

/// the bar is clamped from empty to full, whatever it is given
@Test func theBarIsClamped() {
    #expect(BrandProgress.fraction(0.5, of: 1) == 0.5)
    #expect(BrandProgress.fraction(30, of: 60) == 0.5)
    #expect(BrandProgress.fraction(2, of: 1) == 1)
    #expect(BrandProgress.fraction(-1, of: 1) == 0)
    #expect(BrandProgress.fraction(1, of: 0) == 0)
    #expect(BrandProgress.fraction(.nan, of: 1) == 0)
    #expect(BrandProgress.percent(0.424) == "42 %")
}

/// the words the new controls say themselves are written in both languages
@Test(arguments: ["en", "es"]) func theControlsSpeakBothLanguages(language: String) throws {
    let path = try #require(KitBundle.bundle.path(forResource: language, ofType: "lproj"))
    let bundle = try #require(Bundle(path: path))
    for key in ["shows the options", "clear", "loading", "progress"] {
        let said = bundle.localizedString(forKey: key, value: "missing", table: nil)
        #expect(said != "missing")
        if language == "es" { #expect(said != key) }
    }
}
