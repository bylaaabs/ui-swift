import SwiftUI

/// the web kit's three buttons, for the apps: radius 10, 600, lowercase. the primary is the cyan wash
/// (20 % cyan, a 30 % ring, cyan text), never solid cyan: cyan is a signal, not a surface. one screen
/// has one wash button, the thing to do there.
///
///     Button("subscribe") { ... }.buttonStyle(BrandButtonStyle(.wash))
public struct BrandButtonStyle: ButtonStyle {
    public enum Kind: Sendable {
        /// the one thing to do on the screen
        case wash
        /// everything else
        case outline
        /// solid white on black, for the rare screen that needs a louder second
        case white
    }

    let kind: Kind
    let fill: Bool

    /// `fill` stretches the button to the width it is given, as a phone's bottom button does
    public init(_ kind: Kind = .outline, fill: Bool = false) {
        self.kind = kind
        self.fill = fill
    }

    public func makeBody(configuration: Configuration) -> some View {
        BrandButtonBody(configuration: configuration, kind: kind, fill: fill)
    }
}

private struct BrandButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let kind: BrandButtonStyle.Kind
    let fill: Bool

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        let pressed = configuration.isPressed
        configuration.label
            .font(.brandButton)
            .textCase(.lowercase)
            .lineLimit(1)
            .padding(.horizontal, 22)
            .padding(.vertical, 13)
            .frame(maxWidth: fill ? .infinity : nil)
            .foregroundStyle(foreground)
            .background(background(pressed), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(ring(pressed), lineWidth: 1))
            .opacity(isEnabled ? 1 : 0.5)
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .animation(.easeOut(duration: 0.2), value: pressed)
    }

    private var foreground: Color {
        switch kind {
        case .wash: BrandColors.accent
        case .outline: BrandColors.on
        case .white: BrandColors.surface
        }
    }

    private func background(_ pressed: Bool) -> Color {
        switch kind {
        case .wash: BrandColors.accent.opacity(pressed ? 0.30 : 0.20)
        case .outline: BrandColors.on.opacity(pressed ? 0.05 : 0)
        case .white: BrandColors.on.opacity(pressed ? 0.90 : 1)
        }
    }

    private func ring(_ pressed: Bool) -> Color {
        switch kind {
        case .wash: BrandColors.accent.opacity(0.30)
        case .outline: BrandColors.on.opacity(pressed ? 0.40 : 0.20)
        case .white: .clear
        }
    }
}
