// a pick from a list, in the house's look instead of the system's `Menu`: a field that shows what is
// chosen (paaager's time of day in settings, its level and project filters in history) and opens the
// options in a brand panel. macOS: the floating panel of `BrandMenu`, with a check on the chosen row,
// up / down / return / escape and typing a name to jump to it. iOS: a sheet with the same rows.

#if os(macOS)
import AppKit
#else
import UIKit
#endif
import SwiftUI

// MARK: - options

/// one thing to pick: what it is, what it says, and an optional symbol.
public struct BrandSelectOption<Value: Hashable> {
    public let value: Value
    public var label: String
    public var symbol: String?

    public init(_ label: String, value: Value, symbol: String? = nil) {
        self.value = value
        self.label = label
        self.symbol = symbol
    }
}

/// options under an optional title. a select with more than one section draws a hairline between them.
public struct BrandSelectSection<Value: Hashable> {
    public var title: String?
    public var options: [BrandSelectOption<Value>]

    public init(_ title: String? = nil, options: [BrandSelectOption<Value>]) {
        self.title = title
        self.options = options
    }
}

extension BrandSelectOption: Sendable where Value: Sendable {}
extension BrandSelectSection: Sendable where Value: Sendable {}

/// the rows of a select, flattened: which one is chosen, where the arrows go, what typing finds.
/// no view in it, so it is what the tests look at.
struct BrandSelectRows<Value: Hashable> {
    let sections: [BrandSelectSection<Value>]
    let options: [BrandSelectOption<Value>]

    init(_ sections: [BrandSelectSection<Value>]) {
        self.sections = sections
        options = sections.flatMap(\.options)
    }

    func index(of value: Value) -> Int? {
        options.firstIndex { $0.value == value }
    }

    /// the row `step` rows away, stopping at the ends; from nothing, down starts at the top and up at
    /// the bottom.
    func move(from index: Int?, by step: Int) -> Int? {
        guard !options.isEmpty else { return nil }
        guard let index else { return step > 0 ? 0 : options.count - 1 }
        return min(max(index + step, 0), options.count - 1)
    }

    /// the first row whose label starts with what was typed, ignoring case and accents; then the first
    /// that has it anywhere.
    func match(_ typed: String) -> Int? {
        let typed = typed.trimmingCharacters(in: .whitespaces)
        guard !typed.isEmpty else { return nil }
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        if let index = self.options.firstIndex(where: { $0.label.range(of: typed, options: options.union(.anchored)) != nil }) {
            return index
        }
        return self.options.firstIndex { $0.label.range(of: typed, options: options) != nil }
    }

    /// the index of the first row of each section, to know where a section begins.
    var sectionStarts: [Int] {
        var starts: [Int] = []
        var count = 0
        for section in sections {
            starts.append(count)
            count += section.options.count
        }
        return starts
    }
}

/// the letters typed to jump to a row: they add up while typed quickly, and start again after a pause.
struct BrandTypeAhead {
    static let pause: TimeInterval = 1
    private(set) var typed = ""
    private(set) var last = Date.distantPast

    mutating func add(_ characters: String, at now: Date = Date()) -> String {
        if now.timeIntervalSince(last) > Self.pause { typed = "" }
        typed += characters
        last = now
        return typed
    }
}

// MARK: - the field

/// how a select's field looks.
public enum BrandSelectStyle: Sendable {
    /// a control in a settings row: the field fill, a hairline ring, radius 8, ⌃⌄ (paaager's time of day).
    case field
    /// a filter over a list: a small capsule, cyan when it narrows the list (paaager's history filters).
    case filter
}

/// a field that shows the chosen option and opens the rest in a brand panel.
///
///     BrandSelect("from", selection: $minutes, options: times)
///     BrandSelect(selection: $level, every: "every level", options: levels, style: .filter)
public struct BrandSelect<Value: Hashable>: View {
    let label: String?
    @Binding var selection: Value
    let sections: [BrandSelectSection<Value>]
    let style: BrandSelectStyle
    let font: Font?
    /// a filter is lit when it narrows: when the chosen option is not the first one ("every x")
    let litWhenNotFirst: Bool

    @State private var isOpen = false
    @State private var isHovered = false
    #if os(macOS)
    @State private var anchor = BrandSelectAnchor()
    #endif

    /// `label` is said before the value inside the field and read by voiceover; `font` is the value's
    /// (`.brandDigits` for times and numbers).
    public init(_ label: String? = nil, selection: Binding<Value>, sections: [BrandSelectSection<Value>], style: BrandSelectStyle = .field, font: Font? = nil) {
        self.label = label
        _selection = selection
        self.sections = sections
        self.style = style
        self.font = font
        litWhenNotFirst = style == .filter
    }

    public init(_ label: String? = nil, selection: Binding<Value>, options: [BrandSelectOption<Value>], style: BrandSelectStyle = .field, font: Font? = nil) {
        self.init(label, selection: selection, sections: [BrandSelectSection(options: options)], style: style, font: font)
    }

    /// the "every x" pattern: nil is the first option, `every`, and means no filter at all.
    public init<Wrapped: Hashable>(
        _ label: String? = nil, selection: Binding<Wrapped?>, every: String, options: [BrandSelectOption<Wrapped>],
        style: BrandSelectStyle = .filter, font: Font? = nil
    ) where Value == Wrapped? {
        let all = [BrandSelectOption<Wrapped?>(every, value: nil)] + options.map { BrandSelectOption($0.label, value: Optional($0.value), symbol: $0.symbol) }
        self.init(label, selection: selection, sections: [BrandSelectSection(options: all)], style: style, font: font)
    }

    var rows: BrandSelectRows<Value> { BrandSelectRows(sections) }

    var current: BrandSelectOption<Value>? {
        rows.index(of: selection).map { rows.options[$0] }
    }

    var isLit: Bool {
        litWhenNotFirst && rows.options.first.map { $0.value != selection } == true
    }

    public var body: some View {
        Button(action: open) { face }
            .buttonStyle(.plain)
            .fixedSize()
            #if os(macOS)
            .background(BrandSelectAnchorView(anchor: anchor))
            #else
            .sheet(isPresented: $isOpen) {
                BrandSelectSheet(title: label, sections: sections, selection: selection) { value in
                    selection = value
                    isOpen = false
                }
            }
            #endif
            .onHover { isHovered = $0 }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label ?? current?.label ?? "")
            .accessibilityValue(current?.label ?? "")
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(String(localized: "shows the options", bundle: .module))
    }

    @ViewBuilder private var face: some View {
        switch style {
        case .field:
            HStack(spacing: 6) {
                if let label {
                    Text(label).foregroundStyle(BrandColors.onSecondary)
                }
                Text(current?.label ?? "").foregroundStyle(BrandColors.on).font(font ?? .brandBody)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: Metrics.chevron, weight: .semibold))
                    .foregroundStyle(BrandColors.onSecondary)
            }
            .font(.brandBody)
            .lineLimit(1)
            .padding(.horizontal, Metrics.fieldH)
            .padding(.vertical, Metrics.fieldV)
            .background(isOpen || isHovered ? BrandColors.surfaceSelected : BrandColors.surfaceField, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(isOpen ? BrandColors.accentOutline : BrandColors.border, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 8))
        case .filter:
            HStack(spacing: 4) {
                if let label, !isLit {
                    Text(label)
                }
                Text(current?.label ?? "").font(font ?? .brandCaption)
                Image(systemName: "chevron.down").font(.system(size: Metrics.chevron - 1, weight: .semibold))
            }
            .font(.brandCaption)
            .lineLimit(1)
            .foregroundStyle(isLit ? BrandColors.accentText : (isHovered || isOpen ? BrandColors.on : BrandColors.onSecondary))
            .padding(.horizontal, Metrics.filterH)
            .padding(.vertical, Metrics.filterV)
            .background(isLit ? BrandColors.accentSoft : (isHovered || isOpen ? BrandColors.surfaceSelected : BrandColors.surfaceField), in: Capsule())
            .contentShape(Capsule())
        }
    }

    private func open() {
        #if os(macOS)
        guard let frame = anchor.screenFrame else { return }
        isOpen = true
        BrandMenu.select(below: frame, sections: sections, selection: selection, onClose: { isOpen = false }) { value in
            selection = value
        }
        #else
        isOpen = true
        #endif
    }
}

/// the field's sizes: a mac control, a finger's target on iOS.
private enum Metrics {
    #if os(macOS)
    static let chevron: CGFloat = 9
    static let fieldH: CGFloat = 10
    static let fieldV: CGFloat = 6
    static let filterH: CGFloat = 9
    static let filterV: CGFloat = 5
    #else
    static let chevron: CGFloat = 11
    static let fieldH: CGFloat = 14
    static let fieldV: CGFloat = 11
    static let filterH: CGFloat = 12
    static let filterV: CGFloat = 8
    #endif
}

// MARK: - the open list

/// the options as the open select shows them: titled sections, a check on the chosen row, the
/// highlighted row lit. the panel on macOS and the sheet on iOS draw this; a gallery or a preview can
/// draw it too.
public struct BrandSelectMenu<Value: Hashable>: View {
    let rows: BrandSelectRows<Value>
    let selection: Value
    @Bindable var state: BrandSelectState
    let onPick: @MainActor (Value) -> Void

    /// `highlighted` is the row lit by the keyboard or the pointer.
    public init(sections: [BrandSelectSection<Value>], selection: Value, highlighted: Value? = nil, onPick: @escaping @MainActor (Value) -> Void) {
        let rows = BrandSelectRows(sections)
        self.rows = rows
        self.selection = selection
        state = BrandSelectState(highlighted: highlighted.flatMap { rows.index(of: $0) })
        self.onPick = onPick
    }

    init(rows: BrandSelectRows<Value>, selection: Value, state: BrandSelectState, onPick: @escaping @MainActor (Value) -> Void) {
        self.rows = rows
        self.selection = selection
        self.state = state
        self.onPick = onPick
    }

    /// the height the rows take before any scrolling, to size a panel or a popover that holds them.
    public static func height(for sections: [BrandSelectSection<Value>]) -> CGFloat {
        BrandSelectMetrics.height(sections)
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                list
            }
            .scrollIndicators(.never)
            .onAppear { proxy.scrollTo(rows.index(of: selection) ?? 0, anchor: .center) }
            .onChange(of: state.highlighted) { _, index in
                if let index, state.byKeyboard { proxy.scrollTo(index) }
            }
        }
    }

    private var list: some View {
        let starts = rows.sectionStarts
        return VStack(alignment: .leading, spacing: BrandSelectMetrics.rowSpacing) {
            ForEach(rows.sections.indices, id: \.self) { s in
                let section = rows.sections[s]
                if s > 0 {
                    BrandHLine().padding(.vertical, 4).padding(.horizontal, BrandSelectMetrics.separatorInset)
                }
                if let title = section.title {
                    Text(title)
                        .font(.brandCaption)
                        .foregroundStyle(BrandColors.onTertiary)
                        .padding(.horizontal, BrandSelectMetrics.rowH)
                        .frame(height: BrandSelectMetrics.headerHeight, alignment: .bottomLeading)
                        .padding(.bottom, 2)
                        .accessibilityAddTraits(.isHeader)
                }
                ForEach(section.options.indices, id: \.self) { o in
                    let index = starts[s] + o
                    row(section.options[o], index: index)
                        .id(index)
                }
            }
        }
        .padding(BrandSelectMetrics.padding)
    }

    private func row(_ option: BrandSelectOption<Value>, index: Int) -> some View {
        let isChosen = option.value == selection
        let isLit = state.highlighted == index
        return HStack(spacing: 8) {
            if let symbol = option.symbol {
                Image(systemName: symbol)
                    .font(.system(size: BrandSelectMetrics.symbol, weight: .medium))
                    .foregroundStyle(isLit || isChosen ? BrandColors.accent : BrandColors.onSecondary)
                    .frame(width: BrandSelectMetrics.symbol + 4)
            }
            Text(option.label)
                .font(isChosen ? .brandNavSelected : .brandNav)
                .foregroundStyle(BrandColors.on)
                .lineLimit(1)
            Spacer(minLength: 12)
            Image(systemName: "checkmark")
                .font(.system(size: BrandSelectMetrics.symbol - 1, weight: .semibold))
                .foregroundStyle(BrandColors.accent)
                .opacity(isChosen ? 1 : 0)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, BrandSelectMetrics.rowH)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: BrandSelectMetrics.rowHeight)
        .background(isLit ? BrandColors.surfaceSelected : .clear, in: RoundedRectangle(cornerRadius: BrandSelectMetrics.rowRadius))
        .contentShape(Rectangle())
        .onHover { inside in
            if inside {
                state.byKeyboard = false
                state.highlighted = index
            } else if state.highlighted == index, !state.byKeyboard {
                state.highlighted = nil
            }
        }
        .onTapGesture { onPick(option.value) }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isChosen ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction(.default) { onPick(option.value) }
    }
}

/// which row of an open select is lit, shared by the panel's keys and the rows' hover.
@Observable
public final class BrandSelectState {
    var highlighted: Int?
    /// the last move came from the keyboard, so the list follows it
    var byKeyboard = false
    var typeAhead = BrandTypeAhead()

    init(highlighted: Int?) {
        self.highlighted = highlighted
    }
}

enum BrandSelectMetrics {
    static let padding: CGFloat = 5
    static let rowSpacing: CGFloat = 1
    #if os(macOS)
    static let rowHeight: CGFloat = 28 // BrandMenu.rowHeight
    static let rowH: CGFloat = 10
    static let rowRadius: CGFloat = 6
    static let headerHeight: CGFloat = 22
    static let symbol: CGFloat = 12
    static let separatorInset: CGFloat = 6
    static let separatorBlock: CGFloat = 9
    /// a long list (48 half hours) scrolls past this
    static let maxHeight: CGFloat = 320
    #else
    static let rowHeight: CGFloat = 48
    static let rowH: CGFloat = 14
    static let rowRadius: CGFloat = 10
    static let headerHeight: CGFloat = 30
    static let symbol: CGFloat = 16
    static let separatorInset: CGFloat = 14
    static let separatorBlock: CGFloat = 9
    #endif

    /// the height of every row, title and separator, before any scrolling
    static func height(_ sections: [BrandSelectSection<some Hashable>]) -> CGFloat {
        let count = sections.reduce(0) { $0 + $1.options.count }
        let titles = sections.filter { $0.title != nil }.count
        let blocks = CGFloat(count) * rowHeight + CGFloat(titles) * (headerHeight + 2)
        let separators = CGFloat(max(sections.count - 1, 0)) * separatorBlock
        let gaps = CGFloat(max(count + titles + sections.count - 1 - 1, 0)) * rowSpacing
        return padding * 2 + blocks + separators + gaps
    }
}

#if os(macOS)
// MARK: - macOS: the panel

/// where the field is on screen, so the panel opens right under it.
@MainActor
final class BrandSelectAnchor {
    weak var view: NSView?

    var screenFrame: NSRect? {
        guard let view, let window = view.window else { return nil }
        return window.convertToScreen(view.convert(view.bounds, to: nil))
    }
}

private struct BrandSelectAnchorView: NSViewRepresentable {
    let anchor: BrandSelectAnchor

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        anchor.view = view
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        anchor.view = view
    }
}

extension BrandMenu {
    /// opens a select's options under `frame` (a screen rect, AppKit coordinates), at least as wide as
    /// it, with the chosen row checked and in view. up and down move, return picks, escape closes,
    /// letters jump to the row that starts with them. above the field when there is no room below.
    public static func select<Value: Hashable>(
        below frame: NSRect, sections: [BrandSelectSection<Value>], selection: Value,
        onClose: (@MainActor () -> Void)? = nil, onPick: @escaping @MainActor (Value) -> Void
    ) {
        dismiss()
        let rows = BrandSelectRows(sections)
        guard !rows.options.isEmpty else { return }
        let state = BrandSelectState(highlighted: rows.index(of: selection))

        let pick: @MainActor (Value) -> Void = { value in
            dismiss()
            onPick(value)
        }
        let size = NSSize(
            width: max(frame.width, selectWidth(rows)),
            height: min(BrandSelectMetrics.height(sections), BrandSelectMetrics.maxHeight)
        )
        let root = BrandSelectMenu(rows: rows, selection: selection, state: state, onPick: pick)
            .frame(width: size.width, height: size.height)
            .brandHairlineBorder(cornerRadius: 9, fill: BrandColors.surfaceElevated)
        let host = NSHostingView(rootView: root)
        let gap: CGFloat = 4
        var origin = NSPoint(x: frame.minX, y: frame.minY - gap - size.height)
        if let screen = NSScreen.screens.first(where: { $0.frame.intersects(frame) }), origin.y < screen.visibleFrame.minY {
            origin.y = frame.maxY + gap
        }
        present(host, size: size, at: origin, onClose: onClose) { key in
            handle(key, rows: rows, state: state, pick: pick)
        }
    }

    private static func handle<Value: Hashable>(_ key: KeyPress, rows: BrandSelectRows<Value>, state: BrandSelectState, pick: @MainActor (Value) -> Void) -> Bool {
        // a space in the middle of typing a name is part of the name, not a pick
        let isTyping = !state.typeAhead.typed.isEmpty && Date().timeIntervalSince(state.typeAhead.last) <= BrandTypeAhead.pause
        switch key.keyCode {
        case 125, 126: // down, up
            state.byKeyboard = true
            state.highlighted = rows.move(from: state.highlighted, by: key.keyCode == 125 ? 1 : -1)
            return true
        case 36, 76: // return, enter
            if let index = state.highlighted { pick(rows.options[index].value) }
            return true
        case 49 where !isTyping: // space
            if let index = state.highlighted { pick(rows.options[index].value) }
            return true
        default:
            let letters = key.characters.filter { $0.isLetter || $0.isNumber || $0.isPunctuation || $0 == " " }
            guard !key.hasCommand, !letters.isEmpty else { return false }
            if let index = rows.match(state.typeAhead.add(letters)) {
                state.byKeyboard = true
                state.highlighted = index
            }
            return true
        }
    }

    /// wide enough for the longest label, its symbol and the check
    private static func selectWidth<Value>(_ rows: BrandSelectRows<Value>) -> CGFloat {
        let font = NSFont.brandOutfit(13, weight: .semibold)
        let widest = rows.options.map { ($0.label as NSString).size(withAttributes: [.font: font]).width }.max() ?? 0
        let symbol: CGFloat = rows.options.contains { $0.symbol != nil } ? 24 : 0
        return min(max(ceil(widest) + symbol + 12 + 12 + BrandSelectMetrics.rowH * 2 + BrandSelectMetrics.padding * 2, 120), 360)
    }
}
#else
// MARK: - iOS: the sheet

/// the options in a sheet: the select's label on top, the same rows at a finger's height.
struct BrandSelectSheet<Value: Hashable>: View {
    let title: String?
    let sections: [BrandSelectSection<Value>]
    let selection: Value
    let onPick: @MainActor (Value) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title {
                Text(title)
                    .font(.brandHeadline)
                    .foregroundStyle(BrandColors.on)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 8)
                    .accessibilityAddTraits(.isHeader)
            }
            BrandSelectMenu(sections: sections, selection: selection, onPick: onPick)
                .padding(.horizontal, 6)
        }
        .padding(.top, title == nil ? 16 : 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .presentationDetents(detents)
        .presentationDragIndicator(.visible)
        .presentationBackground(BrandColors.surfaceElevated)
        .presentationCornerRadius(20)
        .preferredColorScheme(.dark)
    }

    /// a short list gets a sheet its own height; a long one opens at half and pulls up to full
    private var detents: Set<PresentationDetent> {
        let fit = BrandSelectMetrics.height(sections) + (title == nil ? 40 : 90)
        return fit < 480 ? [.height(fit)] : [.medium, .large]
    }
}
#endif
