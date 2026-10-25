// a text field in the house's look, for what `.brandField()` left to each app: the placeholder in the
// tertiary white, a cyan ring while typing, return to submit, a clear button, a secret variant, and a
// multi line field that grows with what is written up to a limit (paaager's reply under a page).

#if os(macOS)
import AppKit
#else
import UIKit
#endif
import SwiftUI

/// what kind of text a `BrandTextField` takes.
public enum BrandTextFieldKind: Equatable, Sendable {
    /// one line; return submits
    case single
    /// grows from one line up to `maxLines`, then scrolls. on macOS return submits and option-return
    /// starts a new line; on iOS return starts a new line, as the system keyboard does
    case multiline(maxLines: Int = 5)
    /// a password or a key: dots, never shown, never offered to autocorrect
    case secure

    /// the lines a multi line field may take, at least one
    var lines: ClosedRange<Int> {
        switch self {
        case .single, .secure: 1 ... 1
        case let .multiline(maxLines): 1 ... max(maxLines, 1)
        }
    }
}

/// a brand text field.
///
///     BrandTextField("answer in your own words", text: $reply, kind: .multiline(maxLines: 4), onSubmit: send)
///     BrandTextField("api key", text: $key, kind: .secure, clearable: true)
public struct BrandTextField: View {
    let placeholder: String
    @Binding var text: String
    let kind: BrandTextFieldKind
    let clearable: Bool
    let mono: Bool
    let onSubmit: (() -> Void)?
    let focus: FocusState<Bool>.Binding?

    @FocusState private var ownFocus: Bool
    @Environment(\.isEnabled) private var isEnabled

    /// `focus` lets the screen move the cursor into the field (paaager focuses the reply when a page
    /// opens); without it the field keeps its own. `mono` writes in geist mono, for keys and commands.
    public init(
        _ placeholder: String, text: Binding<String>, kind: BrandTextFieldKind = .single, clearable: Bool = false,
        mono: Bool = false, focus: FocusState<Bool>.Binding? = nil, onSubmit: (() -> Void)? = nil
    ) {
        self.placeholder = placeholder
        _text = text
        self.kind = kind
        self.clearable = clearable
        self.mono = mono
        self.focus = focus
        self.onSubmit = onSubmit
    }

    private var isFocused: Bool { focus?.wrappedValue ?? ownFocus }

    /// return submits everywhere but in a multi line field on iOS, where it starts a new line: a
    /// vertical field with `onSubmit` attached sends on return, so it gets none there and the screen
    /// sends with its own button.
    private var returnSubmits: Bool {
        #if os(iOS)
        if case .multiline = kind { return false }
        #endif
        return true
    }

    /// the clear button shows only when there is something to clear
    var showsClear: Bool { clearable && !text.isEmpty && isEnabled }

    public var body: some View {
        HStack(alignment: kind == .single || kind == .secure ? .center : .top, spacing: 6) {
            focused(field)
                .textFieldStyle(.plain)
                .font(mono ? .brandMono : .brandBody)
                .foregroundStyle(isEnabled ? BrandColors.on : BrandColors.onDisabled)
                .tint(BrandColors.accent)
                .modifier(SubmitOnReturn(action: returnSubmits ? onSubmit : nil))
                #if os(macOS)
                .focusEffectDisabled()
                #endif
            if showsClear {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: Metrics.clear))
                        .foregroundStyle(BrandColors.onTertiary)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "clear", bundle: .module))
                .transition(.opacity)
            }
        }
        .padding(.horizontal, Metrics.h)
        .padding(.vertical, Metrics.v)
        .frame(minHeight: Metrics.minHeight)
        .background(BrandColors.surfaceField, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(isFocused ? BrandColors.accentOutline : BrandColors.border, lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture { setFocus(true) }
        .animation(.easeOut(duration: 0.12), value: isFocused)
        .animation(.easeOut(duration: 0.12), value: showsClear)
    }

    @ViewBuilder private var field: some View {
        let prompt = Text(placeholder).foregroundStyle(BrandColors.onTertiary)
        switch kind {
        case .single:
            TextField("", text: $text, prompt: prompt)
                .accessibilityLabel(placeholder)
        case .multiline:
            TextField("", text: $text, prompt: prompt, axis: .vertical)
                .lineLimit(kind.lines)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(placeholder)
        case .secure:
            SecureField("", text: $text, prompt: prompt)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .accessibilityLabel(placeholder)
        }
    }

    @ViewBuilder private func focused(_ content: some View) -> some View {
        if let focus {
            content.focused(focus)
        } else {
            content.focused($ownFocus)
        }
    }

    private func setFocus(_ value: Bool) {
        if let focus { focus.wrappedValue = value } else { ownFocus = value }
    }

    private enum Metrics {
        #if os(macOS)
        static let h: CGFloat = 10
        static let v: CGFloat = 7
        static let minHeight: CGFloat = 32
        static let clear: CGFloat = 12
        #else
        static let h: CGFloat = 14
        static let v: CGFloat = 11
        static let minHeight: CGFloat = 44
        static let clear: CGFloat = 16
        #endif
    }
}

/// `onSubmit` only when there is something to do on return: attached at all, it turns return in a
/// vertical iOS field into a submit.
private struct SubmitOnReturn: ViewModifier {
    let action: (() -> Void)?

    func body(content: Content) -> some View {
        if let action {
            content.onSubmit(action)
        } else {
            content
        }
    }
}
