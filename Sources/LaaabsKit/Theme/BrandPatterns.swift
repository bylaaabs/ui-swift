#if os(macOS)
// the pieces every laaabs. app wrote inside its own files, gathered by speaaak and kept here as they
// were written there: the settings sidebar row (baaar, taaab and caaapture's settings), rows in a
// card (caaapture), a text field and a text area (caaapture's file name field, terminaaal's startup
// commands), the permission row (baaar's permissions pane), a dark confirmation (caaapture) and a
// menu item that runs a closure (caaapture's status item).

import AppKit
import SwiftUI

/// one sidebar row: 30 pt high, radius 7, cyan symbol and white label when selected.
public struct BrandNavRow: View {
    let symbol: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    public init(symbol: String, title: String, isSelected: Bool, action: @escaping () -> Void) {
        self.symbol = symbol
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 16)
                    .foregroundStyle(isSelected ? BrandColors.accent : BrandColors.onSecondary)
                Text(title)
                    .font(isSelected ? .brandNavSelected : .brandNav)
                    .foregroundStyle(isSelected ? BrandColors.on : BrandColors.onSecondary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .frame(height: 30)
            .background(
                isSelected ? BrandColors.surfaceSelected : (isHovered ? BrandColors.surfaceField : .clear),
                in: RoundedRectangle(cornerRadius: 7)
            )
            .contentShape(Rectangle())
            .animation(.easeOut(duration: 0.12), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// rows in one card, with hairlines between them.
public struct CardRows<Content: View>: View {
    @ViewBuilder let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) { content }.brandCard()
    }
}

public extension View {
    /// a text field as caaapture draws its file name field.
    func brandField(mono: Bool = false) -> some View {
        self
            .textFieldStyle(.plain)
            .font(mono ? .brandMono : .brandBody)
            .foregroundStyle(BrandColors.on)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(BrandColors.surfaceField, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(BrandColors.border, lineWidth: 1))
    }

    /// a text area as terminaaal draws its startup commands.
    func brandTextArea(height: CGFloat = 88) -> some View {
        self
            .font(.brandBody)
            .foregroundStyle(BrandColors.on)
            .scrollContentBackground(.hidden)
            .frame(height: height)
            .padding(8)
            .background(BrandColors.surfaceField, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(BrandColors.border, lineWidth: 1))
    }
}

/// a permission: its symbol, name, a required or optional badge, what it is for, and grant or
/// the green granted mark.
public struct PermissionRow: View {
    let title: String
    let badge: String
    let message: String
    let systemImage: String
    let isGranted: Bool
    var grantTitle = String(localized: "grant", bundle: .module)
    let grant: () -> Void

    public init(
        title: String, badge: String, message: String, systemImage: String, isGranted: Bool,
        grantTitle: String? = nil, grant: @escaping () -> Void
    ) {
        self.title = title
        self.badge = badge
        self.message = message
        self.systemImage = systemImage
        self.isGranted = isGranted
        self.grantTitle = grantTitle ?? String(localized: "grant", bundle: .module)
        self.grant = grant
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isGranted ? BrandColors.accent : BrandColors.onSecondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.brandBody)
                        .foregroundStyle(BrandColors.on)
                    BrandBadge(text: badge)
                }
                Text(message)
                    .font(.brandCaption)
                    .foregroundStyle(BrandColors.onSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            if isGranted {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .medium))
                    Text(String(localized: "granted", bundle: .module))
                        .font(.brandCaption)
                }
                .foregroundStyle(BrandColors.success)
                .transition(.opacity)
            } else {
                PillButton(grantTitle, action: grant)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.14), value: isGranted)
        .accessibilityElement(children: .combine)
    }
}

/// asks before something that cannot be undone, in a dark alert. true when confirmed.
@MainActor
public func confirm(_ title: String, _ message: String, action: String) -> Bool {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.addButton(withTitle: action)
    alert.addButton(withTitle: String(localized: "cancel", bundle: .module))
    alert.window.appearance = NSAppearance(named: .darkAqua)
    return alert.runModal() == .alertFirstButtonReturn
}

/// a menu item that runs a closure.
@MainActor
public final class ClosureMenuItem: NSMenuItem {
    private let handler: @MainActor () -> Void

    public init(title: String, handler: @escaping @MainActor () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(run), keyEquivalent: "")
        target = self
    }

    @available(*, unavailable)
    public required init(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    @objc private func run() {
        handler()
    }
}
#endif
