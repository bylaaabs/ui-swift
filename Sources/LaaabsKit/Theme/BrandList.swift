// a scrolling list in the house's look instead of the system's `List`: rows on black, the chosen one lit
// `surfaceSelected`, hairlines between rows, optional titled sections (paaager's history by day), and
// what to show when there is nothing. the actions on a row are a swipe on iOS (paaager's "seen" in the
// inbox) and a brand context menu on macOS; on macOS the arrows walk the rows.

#if os(macOS)
import AppKit
#else
import UIKit
#endif
import SwiftUI

/// something to do with one row: a swipe on iOS, a line of the context menu on macOS.
public struct BrandListAction {
    public let title: String
    public var symbol: String?
    public var isDestructive: Bool
    public let action: @MainActor () -> Void

    public init(_ title: String, symbol: String? = nil, destructive: Bool = false, action: @escaping @MainActor () -> Void) {
        self.title = title
        self.symbol = symbol
        isDestructive = destructive
        self.action = action
    }
}

/// rows under an optional title, as paaager groups its history into today, yesterday and dates.
public struct BrandListSection<Item: Identifiable> {
    public var title: String?
    public var items: [Item]

    public init(_ title: String? = nil, items: [Item]) {
        self.title = title
        self.items = items
    }
}

/// a brand list.
///
///     BrandList(pages, selection: $selected, actions: { [BrandListAction("seen") { ack($0) }] }) { page in
///         PageRow(page: page)
///     } empty: {
///         BrandEmptyState(symbol: "tray", title: "nothing waiting", message: "pages land here.")
///     }
public struct BrandList<Item: Identifiable, Row: View, Empty: View>: View {
    let sections: [BrandListSection<Item>]
    let selection: Binding<Item.ID?>?
    let separators: Bool
    let actions: (Item) -> [BrandListAction]
    let onOpen: ((Item) -> Void)?
    let row: (Item) -> Row
    let empty: Empty

    /// `selection` lights the chosen row and a tap chooses; `onOpen` runs on a tap (and on return on
    /// macOS), to push a detail. `actions` are the row's swipe (iOS) or context menu (macOS).
    public init(
        sections: [BrandListSection<Item>], selection: Binding<Item.ID?>? = nil, separators: Bool = true,
        actions: @escaping (Item) -> [BrandListAction] = { _ in [] }, onOpen: ((Item) -> Void)? = nil,
        @ViewBuilder row: @escaping (Item) -> Row, @ViewBuilder empty: () -> Empty
    ) {
        self.sections = sections
        self.selection = selection
        self.separators = separators
        self.actions = actions
        self.onOpen = onOpen
        self.row = row
        self.empty = empty()
    }

    public init(
        _ items: [Item], selection: Binding<Item.ID?>? = nil, separators: Bool = true,
        actions: @escaping (Item) -> [BrandListAction] = { _ in [] }, onOpen: ((Item) -> Void)? = nil,
        @ViewBuilder row: @escaping (Item) -> Row, @ViewBuilder empty: () -> Empty
    ) {
        self.init(sections: [BrandListSection(items: items)], selection: selection, separators: separators,
                  actions: actions, onOpen: onOpen, row: row, empty: empty)
    }

    var items: [Item] { sections.flatMap(\.items) }

    public var body: some View {
        if items.isEmpty {
            empty.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else {
            list
        }
    }

    private func choose(_ item: Item) {
        selection?.wrappedValue = item.id
        onOpen?(item)
    }

    private func isSelected(_ item: Item) -> Bool {
        selection?.wrappedValue == item.id
    }

    #if os(macOS)
    private var list: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(sections.indices, id: \.self) { s in
                        if let title = sections[s].title {
                            BrandListHeader(title: title)
                        }
                        let rows = sections[s].items
                        ForEach(rows.indices, id: \.self) { r in
                            let item = rows[r]
                            macRow(item)
                            if separators, r < rows.count - 1 {
                                BrandHLine().padding(.horizontal, 18)
                            }
                        }
                    }
                }
                .padding(.vertical, 6)
            }
            .scrollContentBackground(.hidden)
            .focusable(selection != nil)
            .focusEffectDisabled()
            .onKeyPress(.upArrow) { move(-1, proxy) }
            .onKeyPress(.downArrow) { move(1, proxy) }
            .onKeyPress(.return) {
                guard let item = items.first(where: isSelected) else { return .ignored }
                onOpen?(item)
                return .handled
            }
        }
    }

    private func macRow(_ item: Item) -> some View {
        let selected = isSelected(item)
        return BrandListRow(isSelected: selected) { row(item) }
            .padding(.horizontal, 8)
            .padding(.vertical, 1)
            .onTapGesture { choose(item) }
            .brandContextMenu {
                actions(item).map { BrandMenu.Item($0.title, symbol: $0.symbol, destructive: $0.isDestructive, action: $0.action) }
            }
            .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
            .id(item.id)
    }

    /// the arrows walk the rows, as paaager's history does
    private func move(_ step: Int, _ proxy: ScrollViewProxy) -> KeyPress.Result {
        guard let selection else { return .ignored }
        let list = items
        guard let next = BrandListRows.step(list.map(\.id), from: selection.wrappedValue, by: step) else { return .ignored }
        selection.wrappedValue = next
        proxy.scrollTo(next)
        return .handled
    }
    #else
    private var list: some View {
        List {
            ForEach(sections.indices, id: \.self) { s in
                if let title = sections[s].title {
                    BrandListHeader(title: title)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                ForEach(sections[s].items) { item in
                    iosRow(item)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListRowHeight, 0)
    }

    private func iosRow(_ item: Item) -> some View {
        let selected = isSelected(item)
        return row(item)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { choose(item) }
            .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
            .listRowBackground(selected ? BrandColors.surfaceSelected : Color.clear)
            .listRowSeparator(separators ? .visible : .hidden)
            .listRowSeparatorTint(BrandColors.separatorSolid)
            .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
            .alignmentGuide(.listRowSeparatorTrailing) { $0[.trailing] }
            .listSectionSeparator(.hidden)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                ForEach(Array(actions(item).enumerated()), id: \.offset) { _, action in
                    Button(role: action.isDestructive ? .destructive : nil) {
                        action.action()
                    } label: {
                        if let symbol = action.symbol {
                            Label(action.title, systemImage: symbol)
                        } else {
                            Text(action.title)
                        }
                    }
                    .tint(action.isDestructive ? BrandColors.danger : BrandColors.borderSolid)
                }
            }
            .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }
    #endif
}

extension BrandList where Empty == EmptyView {
    public init(
        _ items: [Item], selection: Binding<Item.ID?>? = nil, separators: Bool = true,
        actions: @escaping (Item) -> [BrandListAction] = { _ in [] }, onOpen: ((Item) -> Void)? = nil,
        @ViewBuilder row: @escaping (Item) -> Row
    ) {
        self.init(items, selection: selection, separators: separators, actions: actions, onOpen: onOpen, row: row) { EmptyView() }
    }
}

/// where the arrows go in a list, apart from any view so the tests can look at it.
enum BrandListRows {
    /// the id `step` rows away from `current`, stopping at the ends; from nothing, the first row
    static func step<ID: Hashable>(_ ids: [ID], from current: ID?, by step: Int) -> ID? {
        guard !ids.isEmpty else { return nil }
        guard let current, let index = ids.firstIndex(of: current) else { return ids.first }
        return ids[min(max(index + step, 0), ids.count - 1)]
    }
}

/// a section's title over its rows: caption, tertiary white.
public struct BrandListHeader: View {
    let title: String

    public init(title: String) { self.title = title }

    public var body: some View {
        Text(title)
            .font(.brandCaption)
            .foregroundStyle(BrandColors.onTertiary)
            .padding(.leading, Self.leading)
            .padding(.top, 12)
            .padding(.bottom, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }

    #if os(macOS)
    static let leading: CGFloat = 18
    #else
    static let leading: CGFloat = 20
    #endif
}

/// one row's ground on macOS: `surfaceSelected` when chosen, `surfaceHover` under the pointer, radius 7.
public struct BrandListRow<Content: View>: View {
    let isSelected: Bool
    @ViewBuilder let content: Content

    @State private var isHovered = false

    public init(isSelected: Bool, @ViewBuilder content: () -> Content) {
        self.isSelected = isSelected
        self.content = content()
    }

    public var body: some View {
        content
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected ? BrandColors.surfaceSelected : (isHovered ? BrandColors.surfaceHover : .clear),
                in: RoundedRectangle(cornerRadius: 7)
            )
            .contentShape(Rectangle())
            .onHover { isHovered = $0 }
            .animation(.easeOut(duration: 0.12), value: isHovered)
    }
}

/// nothing to show yet: a symbol, one line, what to do, and the action when there is one. paaager's
/// empty inbox and history.
public struct BrandEmptyState: View {
    let symbol: String?
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    public init(symbol: String? = nil, title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.symbol = symbol
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: 10) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(BrandColors.onTertiary)
                    .accessibilityHidden(true)
            }
            Text(title)
                .font(.brandHeadline)
                .foregroundStyle(BrandColors.on)
            Text(message)
                .font(.brandCallout)
                .foregroundStyle(BrandColors.onSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 320)
            if let actionTitle, let action {
                PillButton(actionTitle, kind: .secondary, action: action)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .accessibilityElement(children: .contain)
    }
}
