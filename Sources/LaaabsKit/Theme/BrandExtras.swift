#if os(macOS)
// what taaab and caaapture added on top of baaar's theme (BrandColors, BrandFonts, BrandControls and
// BrandWindow are copied from baaar unchanged): the web kit's surfaces and the dot, a status pill,
// an eyebrow label, a chip, the title row, geist mono, and colour helpers for core graphics.
// everything here moves to bylaaabs/ui-swift#2 with the rest.

import AppKit
import SwiftUI

extension BrandColors {
    /// white 80 %: body text.
    public static let onBody = on.opacity(0.80)
    /// white 40 %: eyebrows and hints.
    public static let onLabel = on.opacity(0.40)
    /// white 10 % and 8 %: section and card hairlines.
    public static let hairline = on.opacity(0.10)
    public static let hairlineSoft = on.opacity(0.08)
    /// ui-web `--color-cyan-text`: text on a cyan tint.
    public static let accentText = Color(hex: 0x8FDDF2)

}

extension NSColor {
    /// hex literal (rgb) in display p3.
    public convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        self.init(
            displayP3Red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

extension CGColor {
    /// hex literal (rgb) in display p3.
    public static func p3(hex: UInt32, alpha: CGFloat = 1.0) -> CGColor {
        NSColor(hex: hex, alpha: alpha).cgColor
    }
}

// MARK: - geist mono

@MainActor
public enum BrandMonoFont {
    private static var isRegistered = false

    /// registers the bundled geist mono (ofl) for numbers that must align, as the web kit does.
    public static func register() {
        guard !isRegistered else { return }
        for name in ["GeistMono-Regular", "GeistMono-Medium"] {
            if let url = Bundle.module.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts") ?? Bundle.main.url(forResource: name, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
        isRegistered = true
    }
}

extension NSFont {
    /// geist mono, falling back to the system's monospaced font.
    public static func brandMono(_ size: CGFloat, weight: NSFont.Weight = .medium) -> NSFont {
        let name = weight >= .medium ? "GeistMono-Medium" : "GeistMono-Regular"
        return NSFont(name: name, size: size) ?? .monospacedSystemFont(ofSize: size, weight: weight)
    }
}

extension Font {
    /// geist mono for digits that must align: sizes, coordinates, colours, values.
    public static var brandDigits: Font { .custom("GeistMono-Medium", size: 12, relativeTo: .callout) }
}

// MARK: - the dot, pills, labels, chips

/// the dot: the one signal. cyan when something is on, white 20 % when it is not.
public struct BrandDot: View {
    public init(size: CGFloat = 6, isOn: Bool = true) {
        self.size = size
        self.isOn = isOn
    }

    public var size: CGFloat = 6
    public var isOn = true

    public var body: some View {
        Circle()
            .fill(isOn ? BrandColors.accent : BrandColors.onDisabled)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// a status pill with its led (ui-web `StatusPill`): radius 6, 12 pt 600, cyan tint when live.
public struct BrandStatusPill: View {
    public init(text: String, isLive: Bool = true) {
        self.text = text
        self.isLive = isLive
    }

    public let text: String
    public var isLive = true

    public var body: some View {
        HStack(spacing: 7) {
            BrandDot(size: 6, isOn: isLive)
            Text(text).font(.outfit(12, weight: .semibold)).tracking(0.6)
        }
        .foregroundStyle(isLive ? BrandColors.accentText : BrandColors.onSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(isLive ? BrandColors.accent.opacity(0.16) : BrandColors.on.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
    }
}

/// a pick among a few, as a row of chips: outlined, and with the dot and the cyan tint when on.
public struct ActionChip: View {
    public init(label: String, isOn: Bool, action: @escaping () -> Void) {
        self.label = label
        self.isOn = isOn
        self.action = action
    }

    public let label: String
    public let isOn: Bool
    public let action: () -> Void

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isOn { BrandDot(size: 5) }
                Text(label).font(isOn ? .brandButton : .brandCallout)
            }
            .foregroundStyle(isOn ? BrandColors.on : BrandColors.onSecondary)
            .padding(.horizontal, 10)
            .frame(height: 26)
            .background(isOn ? BrandColors.accentSoft : .clear, in: RoundedRectangle(cornerRadius: 7))
            .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(isOn ? BrandColors.accentTint : BrandColors.separator, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

// MARK: - the title row

/// the title row a laaabs. window draws under its transparent titlebar, as baaar's settings: the
/// wordmark at 10 pt, then "- " and what the window is. click-through, so dragging it moves the window.
public struct BrandTitleRow: View {
    public init(title: String) { self.title = title }

    public let title: String

    public var body: some View {
        HStack(spacing: 6) {
            Wordmark(height: 10)
            Text(verbatim: "- \(title)")
                .font(.brandBody)
                .foregroundStyle(BrandColors.on)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: NSWindow.brandTitleRowHeight)
        .background(BrandColors.surface)
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - a menu with shortcuts

/// baaar's menu (a floating dark panel on `surfaceElevated`, a one-pixel ring at radius 9, 28 pt
/// rows) with each row's shortcut on the trailing edge, separators, and rows that can be disabled.
@MainActor
public enum BrandShortcutMenu {
    public enum Entry {
        case item(String, shortcut: String?, enabled: Bool, action: @MainActor () -> Void)
        case separator
    }

    public static let width: CGFloat = 220
    private static var panel: NSPanel?
    private static var localMonitor: Any?
    private static var globalMonitor: Any?

    public static func show(at point: NSPoint, entries: [Entry]) {
        dismiss()
        let host = NSHostingView(rootView: ShortcutMenuView(entries: entries) { action in
            dismiss()
            action()
        })
        let height = host.fittingSize.height
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
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
        panel.sharingType = BrandPanels.sharingType
        panel.contentView = host

        var origin = NSPoint(x: point.x, y: point.y - height)
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(point) }) {
            let visible = screen.visibleFrame
            origin.x = min(max(origin.x, visible.minX + 4), visible.maxX - width - 4)
            origin.y = max(origin.y, visible.minY + 4)
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

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown]) { event in
            let window = event.window
            let isEscape = event.type == .keyDown && event.keyCode == 53
            MainActor.assumeIsolated {
                if isEscape || (event.type != .keyDown && window !== BrandShortcutMenu.panel) { dismiss() }
            }
            return isEscape ? nil : event
        }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { _ in
            MainActor.assumeIsolated { dismiss() }
        }
    }

    public static func dismiss() {
        panel?.orderOut(nil)
        panel = nil
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        localMonitor = nil
        globalMonitor = nil
    }
}

private struct ShortcutMenuView: View {
    let entries: [BrandShortcutMenu.Entry]
    let pick: (@escaping @MainActor () -> Void) -> Void

    var body: some View {
        VStack(spacing: 1) {
            ForEach(entries.indices, id: \.self) { index in
                switch entries[index] {
                case .separator:
                    BrandHLine().padding(.vertical, 4).padding(.horizontal, 6)
                case let .item(title, shortcut, enabled, action):
                    ShortcutMenuRow(title: title, shortcut: shortcut, isEnabled: enabled) { pick(action) }
                }
            }
        }
        .padding(5)
        .frame(width: BrandShortcutMenu.width)
        .brandHairlineBorder(cornerRadius: 9, fill: BrandColors.surfaceElevated)
    }
}

private struct ShortcutMenuRow: View {
    let title: String
    let shortcut: String?
    let isEnabled: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.brandNav)
                .foregroundStyle(isEnabled ? BrandColors.on : BrandColors.onDisabled)
                .lineLimit(1)
            Spacer(minLength: 8)
            if let shortcut {
                Text(verbatim: shortcut)
                    .font(.brandCallout)
                    .foregroundStyle(isEnabled ? BrandColors.onSecondary : BrandColors.onDisabled)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: BrandMenu.rowHeight)
        .background(isHovered && isEnabled ? BrandColors.surfaceSelected : .clear, in: RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture { if isEnabled { action() } }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - stepper

/// a number with minus and plus, on baaar's recessed track: the self-timer's seconds.
public struct BrandStepper: View {
    public init(value: Binding<UInt32>, range: ClosedRange<UInt32>, unit: String = "") {
        _value = value
        self.range = range
        self.unit = unit
    }

    @Binding public var value: UInt32
    public let range: ClosedRange<UInt32>
    public var unit = ""

    public var body: some View {
        HStack(spacing: 2) {
            step("minus", enabled: value > range.lowerBound) { value = max(value - 1, range.lowerBound) }
            Text(verbatim: unit.isEmpty ? "\(value)" : "\(value) \(unit)")
                .font(.brandCallout)
                .monospacedDigit()
                .foregroundStyle(BrandColors.on)
                .frame(minWidth: 48)
            step("plus", enabled: value < range.upperBound) { value = min(value + 1, range.upperBound) }
        }
        .padding(3)
        .background(BrandColors.surfaceTrack, in: RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(BrandColors.separator, lineWidth: 1))
    }

    private func step(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(enabled ? BrandColors.on : BrandColors.onDisabled)
                .frame(width: 26, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}
#endif
