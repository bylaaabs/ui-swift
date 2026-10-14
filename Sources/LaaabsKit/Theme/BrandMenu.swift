#if os(macOS)
// A brand context menu: a floating dark panel of rows on `surfaceElevated`, a one-pixel
// `separatorSolid` ring at radius 9, rows that light up `surfaceSelected` at radius 6.

import AppKit
import SwiftUI

@MainActor
public enum BrandMenu {
    public struct Item {
        public let title: String
        public var symbol: String?
        public var isDestructive = false
        public let action: () -> Void

        public init(_ title: String, symbol: String? = nil, destructive: Bool = false, action: @escaping () -> Void) {
            self.title = title
            self.symbol = symbol
            self.isDestructive = destructive
            self.action = action
        }
    }

    public static let width: CGFloat = 200
    public static let rowHeight: CGFloat = 28

    private static var panel: NSPanel?
    private static var localMonitor: Any?
    private static var globalMonitor: Any?
    private static var resignObserver: NSObjectProtocol?
    private static var keyHandler: (@MainActor (KeyPress) -> Bool)?
    private static var closeHandler: (@MainActor () -> Void)?

    /// Shows the menu with its top-left corner at a screen point (AppKit coordinates).
    public static func show(at point: NSPoint, items: [Item]) {
        dismiss()
        guard !items.isEmpty else { return }

        let padding: CGFloat = 5
        let height = padding * 2 + CGFloat(items.count) * rowHeight + CGFloat(items.count - 1)
        let host = NSHostingView(rootView: BrandMenuView(items: items, padding: padding) { item in
            dismiss()
            item.action()
        })
        present(host, size: NSSize(width: width, height: height), at: NSPoint(x: point.x, y: point.y - height))
    }

    /// puts `content` in the floating panel at `origin` (its bottom-left, AppKit coordinates, kept on
    /// screen), and closes it on escape, a click outside or the app going to the background, then calls
    /// `onClose`. `onKey`
    /// sees every other key first: true means it used it, and the window under the panel never gets it.
    static func present(_ content: NSView, size: NSSize, at origin: NSPoint, onClose: (@MainActor () -> Void)? = nil, onKey: (@MainActor (KeyPress) -> Bool)? = nil) {
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.hasShadow = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.appearance = NSAppearance(named: .darkAqua)
        panel.isReleasedWhenClosed = false
        panel.contentView = content

        var origin = origin
        let probe = NSPoint(x: origin.x, y: origin.y + size.height)
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(probe) }) ?? NSScreen.main {
            let visible = screen.visibleFrame
            origin.x = min(max(origin.x, visible.minX + 4), visible.maxX - size.width - 4)
            origin.y = min(max(origin.y, visible.minY + 4), visible.maxY - size.height - 4)
        }
        panel.setFrameOrigin(origin)
        panel.alphaValue = 0
        panel.orderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }
        self.panel = panel
        keyHandler = onKey
        closeHandler = onClose

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown]) { event in
            let window = event.window
            let isKey = event.type == .keyDown
            let isEscape = isKey && event.keyCode == 53
            let press = isKey ? KeyPress(event) : nil
            let passes = MainActor.assumeIsolated {
                if isEscape || (!isKey && window !== BrandMenu.panel) {
                    dismiss()
                    return !isEscape
                }
                if let press, let handler = keyHandler, handler(press) { return false }
                return true
            }
            return passes ? event : nil
        }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { _ in
            MainActor.assumeIsolated { dismiss() }
        }
        resignObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification, object: nil, queue: .main
        ) { _ in
            MainActor.assumeIsolated { dismiss() }
        }
    }

    /// a key pressed while the panel is open, as much of it as a panel needs.
    struct KeyPress: Sendable {
        let keyCode: UInt16
        let characters: String
        let hasCommand: Bool

        init(_ event: NSEvent) {
            keyCode = event.keyCode
            characters = event.charactersIgnoringModifiers ?? ""
            hasCommand = event.modifierFlags.contains(.command) || event.modifierFlags.contains(.control)
        }
    }

    /// true while a brand menu or a select's panel is open.
    public static var isShown: Bool { panel != nil }

    public static func dismiss() {
        panel?.orderOut(nil)
        panel = nil
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let resignObserver { NotificationCenter.default.removeObserver(resignObserver) }
        localMonitor = nil
        globalMonitor = nil
        resignObserver = nil
        keyHandler = nil
        let close = closeHandler
        closeHandler = nil
        close?()
    }
}

private struct BrandMenuView: View {
    let items: [BrandMenu.Item]
    let padding: CGFloat
    let onPick: (BrandMenu.Item) -> Void

    var body: some View {
        VStack(spacing: 1) {
            ForEach(items.indices, id: \.self) { index in
                BrandMenuRow(title: items[index].title, symbol: items[index].symbol, isDestructive: items[index].isDestructive) {
                    onPick(items[index])
                }
            }
        }
        .padding(padding)
        .brandHairlineBorder(cornerRadius: 9, fill: BrandColors.surfaceElevated)
    }
}

/// One menu row: 28 pt high, nav type, `surfaceSelected` at radius 6 on hover.
public struct BrandMenuRow: View {
    public init(title: String, symbol: String? = nil, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.symbol = symbol
        self.isDestructive = isDestructive
        self.action = action
    }

    public let title: String
    public var symbol: String?
    public var isDestructive = false
    public let action: () -> Void

    @State private var isHovered = false

    public var body: some View {
        HStack(spacing: 8) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isDestructive ? BrandColors.danger : (isHovered ? BrandColors.accent : BrandColors.onSecondary))
                    .frame(width: 16)
            }
            Text(title)
                .font(.brandNav)
                .foregroundStyle(isDestructive ? BrandColors.danger : BrandColors.on)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: BrandMenu.rowHeight)
        .background(isHovered ? BrandColors.surfaceSelected : .clear, in: RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture(perform: action)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(.default, action)
    }
}

extension View {
    /// Shows a brand menu on right-click (or control-click) instead of the system context menu.
    public func brandContextMenu(_ items: @escaping @MainActor () -> [BrandMenu.Item]) -> some View {
        overlay(RightClickCatcher { BrandMenu.show(at: NSEvent.mouseLocation, items: items()) })
    }
}

/// Transparent to every click but a right-click (or control-click), which it turns into `onRight`.
private struct RightClickCatcher: NSViewRepresentable {
    var onRight: @MainActor () -> Void

    func makeNSView(context: Context) -> CatcherView {
        CatcherView(onRight: onRight)
    }

    func updateNSView(_ view: CatcherView, context: Context) {
        view.onRight = onRight
    }

    final class CatcherView: NSView {
        public var onRight: @MainActor () -> Void

        public init(onRight: @escaping @MainActor () -> Void) {
            self.onRight = onRight
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        public required init?(coder: NSCoder) {
            fatalError("init(coder:) is not supported")
        }

        public override func hitTest(_ point: NSPoint) -> NSView? {
            guard let event = NSApp.currentEvent else { return nil }
            let isSecondary = event.type == .rightMouseDown
                || (event.type == .leftMouseDown && event.modifierFlags.contains(.control))
            return isSecondary ? super.hitTest(point) : nil
        }

        public override func rightMouseDown(with event: NSEvent) { onRight() }
        public override func mouseDown(with event: NSEvent) { onRight() }
    }
}
#endif
