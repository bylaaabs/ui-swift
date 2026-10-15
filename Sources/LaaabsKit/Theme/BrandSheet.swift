// a sheet in the house's look instead of the system's menus and action sheets: the elevated black,
// radius 14 on top, our own grab handle, a title in the middle with "done" on the right, the content,
// and an optional hint under it. on iOS it is as tall as what it holds (paaager's sort sheet), or
// opens at half and pulls up to full when that is long. `BrandMenuList` is a menu's rows inside one:
// things to do, a symbol each, the destructive ones in red.

#if os(macOS)
import AppKit
#else
import UIKit
#endif
import SwiftUI

// MARK: - presenting

/// how tall a sheet opens.
public enum BrandSheetHeight: Sendable, Equatable {
    /// as tall as its content, up to half the screen; then half, pulling up to full
    case fit
    /// half, pulling up to full
    case half
    /// the whole screen
    case full
}

extension View {
    /// presents `content` in a brand sheet. put a `BrandSheet` in it for the grab, the title and done.
    ///
    ///     .brandSheet(isPresented: $sorting) {
    ///         BrandSheet("sort", hint: "the order is kept on this device.", done: { sorting = false }) {
    ///             BrandChoiceList(selection: $order, choices: orders, style: .plain)
    ///         }
    ///     }
    public func brandSheet<Content: View>(
        isPresented: Binding<Bool>, height: BrandSheetHeight = .fit, onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        sheet(isPresented: isPresented, onDismiss: onDismiss) {
            BrandSheetHost(height: height, content: content())
        }
    }

    /// the same, for an item: the sheet shows while `item` is not nil.
    public func brandSheet<Item: Identifiable, Content: View>(
        item: Binding<Item?>, height: BrandSheetHeight = .fit, onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        sheet(item: item, onDismiss: onDismiss) { item in
            BrandSheetHost(height: height, content: content(item))
        }
    }
}

/// the presentation around a sheet's content: the ground, the corners, the height.
struct BrandSheetHost<Content: View>: View {
    let height: BrandSheetHeight
    let content: Content

    @State private var measured: CGFloat = 0

    var body: some View {
        #if os(macOS)
        content
            .frame(minWidth: 360, idealWidth: 420)
            .fixedSize(horizontal: false, vertical: height == .fit)
            .background(BrandColors.surfaceElevated)
            .preferredColorScheme(.dark)
        #else
        content
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { measured = $0 }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .presentationDetents(BrandSheetDetents.detents(height, measured: measured))
            .presentationDragIndicator(.hidden)
            .presentationBackground(BrandColors.surfaceElevated)
            .presentationCornerRadius(BrandSheetMetrics.radius)
            .preferredColorScheme(.dark)
        #endif
    }
}

#if os(iOS)
/// which heights a sheet stops at, apart from any view so the tests can look at it.
enum BrandSheetDetents {
    /// past this a fitted sheet opens at half instead
    static let fitLimit: CGFloat = 480

    static func detents(_ height: BrandSheetHeight, measured: CGFloat) -> Set<PresentationDetent> {
        switch height {
        case .fit:
            // before the first measure, half: the sheet settles on its height a frame later
            guard measured > 0 else { return [.medium] }
            return measured < fitLimit ? [.height(ceil(measured))] : [.medium, .large]
        case .half:
            return [.medium, .large]
        case .full:
            return [.large]
        }
    }
}
#endif

// MARK: - the sheet

/// a sheet's chrome: the grab, the title with done, the content, and an optional hint under it.
public struct BrandSheet<Content: View>: View {
    let title: String?
    let hint: String?
    let doneTitle: String?
    let done: (() -> Void)?
    let content: Content

    /// `done` puts "done" (or `doneTitle`) on the right of the title; nil leaves it out, and the sheet
    /// closes with a swipe or by picking.
    public init(
        _ title: String? = nil, hint: String? = nil, doneTitle: String? = nil, done: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.hint = hint
        self.doneTitle = doneTitle
        self.done = done
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            #if os(iOS)
            Capsule()
                .fill(BrandColors.borderSolid)
                .frame(width: 38, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 2)
                .accessibilityHidden(true)
            #endif
            if title != nil || done != nil {
                header
            }
            content
            if let hint {
                Text(hint)
                    .font(.brandCaption)
                    .foregroundStyle(BrandColors.onTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, BrandSheetMetrics.side)
        .padding(.top, BrandSheetMetrics.top)
        .padding(.bottom, BrandSheetMetrics.bottom)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var header: some View {
        ZStack {
            if let title {
                Text(title)
                    .font(.outfit(BrandSheetMetrics.titleSize, weight: .bold, relativeTo: .headline))
                    .foregroundStyle(BrandColors.on)
                    .lineLimit(1)
                    .padding(.horizontal, 70)
                    .accessibilityAddTraits(.isHeader)
            }
            if let done {
                HStack {
                    Spacer()
                    Button(action: done) {
                        Text(doneTitle ?? String(localized: "done", bundle: .module))
                            .font(.outfit(BrandSheetMetrics.titleSize, weight: .medium, relativeTo: .body))
                            .foregroundStyle(BrandColors.accentText)
                            .frame(minWidth: BrandSheetMetrics.target, minHeight: BrandSheetMetrics.target, alignment: .trailing)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: BrandSheetMetrics.target)
    }
}

enum BrandSheetMetrics {
    static let radius: CGFloat = 14
    #if os(macOS)
    static let side: CGFloat = 16
    static let top: CGFloat = 12
    static let bottom: CGFloat = 16
    static let titleSize: CGFloat = 13
    static let target: CGFloat = 28
    #else
    static let side: CGFloat = 16
    static let top: CGFloat = 8
    static let bottom: CGFloat = 30
    static let titleSize: CGFloat = 16
    static let target: CGFloat = 44
    #endif
}

// MARK: - a menu's rows

/// the rows of a menu in a sheet: a symbol and a title each, the destructive ones in red, hairlines
/// between them, 44 pt on iOS. what an iOS app shows where it would use the system's `Menu` or
/// `confirmationDialog`. a row runs its action; closing the sheet is the caller's.
///
///     BrandMenuList([
///         BrandListAction("open on github", symbol: "arrow.up.right.square") { open() },
///         BrandListAction("forget", symbol: "trash", destructive: true) { forget() },
///     ])
public struct BrandMenuList: View {
    let actions: [BrandListAction]

    public init(_ actions: [BrandListAction]) {
        self.actions = actions
    }

    public var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(actions.enumerated()), id: \.offset) { index, action in
                if index > 0 { BrandHLine() }
                BrandMenuListRow(action: action)
            }
        }
    }
}

private struct BrandMenuListRow: View {
    let action: BrandListAction

    @State private var isHovered = false

    var body: some View {
        Button { action.action() } label: {
            HStack(spacing: 12) {
                if let symbol = action.symbol {
                    Image(systemName: symbol)
                        .font(.system(size: BrandMenuListMetrics.symbol, weight: .medium))
                        .foregroundStyle(action.isDestructive ? BrandColors.danger : BrandColors.onSecondary)
                        .frame(width: BrandMenuListMetrics.symbol + 6)
                        .accessibilityHidden(true)
                }
                Text(action.title)
                    .font(BrandMenuListMetrics.font)
                    .foregroundStyle(action.isDestructive ? BrandColors.danger : BrandColors.on)
                    .lineLimit(2)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, BrandMenuListMetrics.rowH)
            .frame(maxWidth: .infinity, minHeight: BrandMenuListMetrics.target, alignment: .leading)
            .background(isHovered ? BrandColors.surfaceHover : .clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(BrandMenuListPress())
        .onHover { isHovered = $0 }
        .accessibilityLabel(action.title)
    }
}

private struct BrandMenuListPress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.background(configuration.isPressed ? BrandColors.surfaceSelected : .clear)
    }
}

enum BrandMenuListMetrics {
    #if os(macOS)
    static let symbol: CGFloat = 12
    static let rowH: CGFloat = 10
    static let target: CGFloat = 28
    static var font: Font { .brandNav }
    #else
    static let symbol: CGFloat = 17
    static let rowH: CGFloat = 12
    static let target: CGFloat = 48
    static var font: Font { .outfit(16, weight: .medium, relativeTo: .body) }
    #endif
}
