// a tab bar of the house's own instead of the system's: on iOS 26 the system bar ignores the title
// font, so its labels never come out in outfit (bylaaabs/paaager#45). icons over outfit labels, the
// chosen tab in white and the rest tertiary, a white badge with a count, and an optional central
// action raised above the bar in solid cyan (paaager's "new page"). docked to the bottom edge, as the
// design draws it, or floating over the content as a capsule.

#if os(macOS)
import AppKit
#else
import UIKit
#endif
import SwiftUI

// MARK: - the pieces

/// one tab: what it is, what it says, its symbol and an optional count.
public struct BrandTab<Value: Hashable> {
    public let value: Value
    public var title: String
    public var symbol: String
    /// the symbol when chosen; nil uses `symbol` (pass "tray.fill" for "tray" to fill the chosen one)
    public var selectedSymbol: String?
    /// a count on the tab; nil or 0 shows none
    public var badge: Int?

    public init(_ title: String, symbol: String, value: Value, selectedSymbol: String? = nil, badge: Int? = nil) {
        self.value = value
        self.title = title
        self.symbol = symbol
        self.selectedSymbol = selectedSymbol
        self.badge = badge
    }
}

extension BrandTab: Sendable where Value: Sendable {}

/// the central action: not a tab, a button that does something (paaager's "new page").
public struct BrandTabAction {
    public var title: String
    public var symbol: String
    public let action: @MainActor () -> Void

    public init(_ title: String, symbol: String, action: @escaping @MainActor () -> Void) {
        self.title = title
        self.symbol = symbol
        self.action = action
    }
}

/// where the bar sits.
public enum BrandTabBarStyle: Sendable {
    /// across the bottom edge, into the home indicator's area, a hairline on top (the design)
    case docked
    /// a capsule floating over the content, inset from the edges
    case floating
}

/// what a badge says: nothing for no count, the count, and "99+" past 99. apart from any view so the
/// tests can look at it.
enum BrandTabBadge {
    static func text(_ count: Int?) -> String? {
        guard let count, count > 0 else { return nil }
        return count > 99 ? "99+" : String(count)
    }
}

/// what goes where along the bar: the tabs in order, with the action, when there is one, in the middle
/// (or at `index`). apart from any view so the tests can look at it.
enum BrandTabSlot<Value: Hashable>: Equatable {
    case tab(Value)
    case action

    static func layout(_ tabs: [Value], hasAction: Bool, at index: Int?) -> [Self] {
        var slots = tabs.map { Self.tab($0) }
        guard hasAction else { return slots }
        let at = min(max(index ?? tabs.count / 2, 0), tabs.count)
        slots.insert(.action, at: at)
        return slots
    }
}

// MARK: - the bar

/// a brand tab bar, bound to the chosen tab.
///
///     BrandTabBar(selection: $tab, tabs: [
///         BrandTab("pages", symbol: "tray", value: .pages, badge: waiting),
///         BrandTab("agents", symbol: "terminal", value: .agents),
///         BrandTab("team", symbol: "person.2", value: .team),
///         BrandTab("settings", symbol: "gearshape", value: .settings),
///     ], action: BrandTabAction("new page", symbol: "square.and.pencil") { composing = true })
///
/// most screens want `BrandTabView`, which holds the bar and the tabs' screens together.
public struct BrandTabBar<Value: Hashable>: View {
    @Binding var selection: Value
    let tabs: [BrandTab<Value>]
    let action: BrandTabAction?
    let actionIndex: Int?
    let style: BrandTabBarStyle

    @Environment(\.displayScale) private var scale

    /// `actionIndex` is where the action goes among the tabs; nil puts it in the middle.
    public init(
        selection: Binding<Value>, tabs: [BrandTab<Value>], action: BrandTabAction? = nil, actionIndex: Int? = nil,
        style: BrandTabBarStyle = .docked
    ) {
        _selection = selection
        self.tabs = tabs
        self.action = action
        self.actionIndex = actionIndex
        self.style = style
    }

    var slots: [BrandTabSlot<Value>] {
        BrandTabSlot.layout(tabs.map(\.value), hasAction: action != nil, at: actionIndex)
    }

    public var body: some View {
        bar
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isTabBar)
            .sensoryFeedback(.selection, trigger: selection)
    }

    @ViewBuilder private var bar: some View {
        let row = HStack(alignment: .top, spacing: 0) {
            ForEach(Array(slots.enumerated()), id: \.offset) { _, slot in
                switch slot {
                case let .tab(value):
                    if let tab = tabs.first(where: { $0.value == value }) {
                        tabButton(tab)
                    }
                case .action:
                    if let action {
                        BrandTabActionButton(action: action, raised: style == .docked)
                    }
                }
            }
        }
        .padding(.horizontal, BrandTabMetrics.sidePadding)
        switch style {
        case .docked:
            row
                .padding(.top, BrandTabMetrics.topPadding)
                .frame(maxWidth: .infinity)
                .frame(height: BrandTabMetrics.barHeight, alignment: .top)
                .background(alignment: .top) {
                    BrandColors.surfaceElevated.opacity(0.97)
                        .overlay(alignment: .top) { BrandHLine() }
                        .ignoresSafeArea(edges: .bottom)
                }
        case .floating:
            row
                .padding(.vertical, 6)
                .padding(.horizontal, 6)
                .background(BrandColors.surfaceElevated.opacity(0.97), in: Capsule())
                .overlay(Capsule().strokeBorder(BrandColors.separatorSolid, lineWidth: 1 / scale))
                .shadow(color: BrandColors.shadowOverlay, radius: 18, y: 6)
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
        }
    }

    private func tabButton(_ tab: BrandTab<Value>) -> some View {
        let isChosen = tab.value == selection
        let badge = BrandTabBadge.text(tab.badge)
        return Button {
            selection = tab.value
        } label: {
            VStack(spacing: 4) {
                Image(systemName: isChosen ? (tab.selectedSymbol ?? tab.symbol) : tab.symbol)
                    .font(.system(size: BrandTabMetrics.symbol, weight: .medium))
                    .frame(width: BrandTabMetrics.icon, height: BrandTabMetrics.icon)
                    .overlay(alignment: .topLeading) {
                        if let badge {
                            Text(badge)
                                .font(.outfit(11, weight: .bold, relativeTo: .caption2))
                                .monospacedDigit()
                                .foregroundStyle(BrandColors.onGlyph)
                                .padding(.horizontal, 5)
                                .frame(minWidth: 18, minHeight: 18)
                                .background(BrandColors.on, in: Capsule())
                                .fixedSize()
                                .offset(x: BrandTabMetrics.icon - 6, y: -4)
                        }
                    }
                Text(tab.title)
                    .font(.outfit(BrandTabMetrics.label, weight: isChosen ? .semibold : .medium, relativeTo: .caption2))
                    .lineLimit(1)
            }
            .foregroundStyle(isChosen ? BrandColors.on : BrandColors.onTertiary)
            .frame(maxWidth: .infinity, minHeight: BrandTabMetrics.target)
            .contentShape(Rectangle())
        }
        .buttonStyle(BrandTabPress())
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .accessibilityLabel(tab.title)
        .accessibilityValue(badge ?? "")
        .accessibilityAddTraits(isChosen ? [.isButton, .isSelected] : .isButton)
    }
}

/// the raised cyan circle with its label under it.
private struct BrandTabActionButton: View {
    let action: BrandTabAction
    let raised: Bool

    var body: some View {
        Button(action: action.action) {
            VStack(spacing: 4) {
                Image(systemName: action.symbol)
                    .font(.system(size: BrandTabMetrics.actionSymbol, weight: .semibold))
                    .foregroundStyle(BrandColors.accentGlyph)
                    .frame(width: BrandTabMetrics.actionSize, height: BrandTabMetrics.actionSize)
                    .background(BrandColors.accent, in: Circle())
                    // a ring of the page's black cuts the circle out of the bar, as the design draws it
                    .padding(raised ? BrandTabMetrics.actionRing : 0)
                    .background(raised ? BrandColors.surface : .clear, in: Circle())
                if raised {
                    Text(action.title)
                        .font(.outfit(BrandTabMetrics.label, weight: .medium, relativeTo: .caption2))
                        .foregroundStyle(BrandColors.onSecondary)
                        .lineLimit(1)
                        .padding(.top, -BrandTabMetrics.actionRing)
                }
            }
            .padding(.top, raised ? -BrandTabMetrics.actionLift : 0)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(BrandTabPress())
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .accessibilityLabel(action.title)
        .accessibilityAddTraits(.isButton)
    }
}

/// a tab dims a little while pressed; nothing moves.
private struct BrandTabPress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.6 : 1)
    }
}

enum BrandTabMetrics {
    /// the bar above the home indicator: the 84 of the design less its 34 pt indicator area
    static let barHeight: CGFloat = 50
    static let topPadding: CGFloat = 7
    static let sidePadding: CGFloat = 6
    static let icon: CGFloat = 24
    static let symbol: CGFloat = 19
    static let label: CGFloat = 10.5
    /// a finger's target, whatever the label
    static let target: CGFloat = 44
    static let actionSize: CGFloat = 54
    static let actionSymbol: CGFloat = 21
    static let actionRing: CGFloat = 5
    /// how far the action rises above the bar's top padding
    static let actionLift: CGFloat = 23
}

// MARK: - the bar with its screens

/// the tabs' screens with the bar under them. every screen stays alive while another is shown, so a
/// scroll position or a half written page survives a trip to settings; only the chosen one is drawn,
/// hit and read by voiceover. the system's tab bar is never used.
///
///     BrandTabView(selection: $tab, tabs: tabs, action: newPage) { tab in
///         switch tab {
///         case .pages: PagesScreen()
///         ...
///         }
///     }
public struct BrandTabView<Value: Hashable, Content: View>: View {
    @Binding var selection: Value
    let tabs: [BrandTab<Value>]
    let action: BrandTabAction?
    let actionIndex: Int?
    let style: BrandTabBarStyle
    let content: (Value) -> Content

    public init(
        selection: Binding<Value>, tabs: [BrandTab<Value>], action: BrandTabAction? = nil, actionIndex: Int? = nil,
        style: BrandTabBarStyle = .docked, @ViewBuilder content: @escaping (Value) -> Content
    ) {
        _selection = selection
        self.tabs = tabs
        self.action = action
        self.actionIndex = actionIndex
        self.style = style
        self.content = content
    }

    public var body: some View {
        ZStack {
            ForEach(tabs.map(\.value), id: \.self) { value in
                let isShown = value == selection
                content(value)
                    .opacity(isShown ? 1 : 0)
                    .allowsHitTesting(isShown)
                    .accessibilityHidden(!isShown)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BrandTabBar(selection: $selection, tabs: tabs, action: action, actionIndex: actionIndex, style: style)
        }
        .background(BrandColors.surface)
    }
}
