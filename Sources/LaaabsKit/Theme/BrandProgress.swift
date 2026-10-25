// waiting, in the house's look instead of the system's `ProgressView`: a thin spinning arc in the
// secondary white over a hairline ring (paaager's inbox while it loads), and a bar that fills in cyan,
// the signal colour, for something that knows how far it has got.

import SwiftUI

/// a spinner, or a bar when the progress is known.
///
///     BrandProgress()                                   // the spinner
///     BrandProgress(value: 0.4, label: "uploading")     // the bar, with what it is and its percent
public struct BrandProgress: View {
    enum Kind: Equatable {
        case spinner(size: CGFloat)
        case bar(fraction: Double)
    }

    let kind: Kind
    let label: String?
    let showsPercent: Bool
    let tint: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// the spinner. `size` is its diameter.
    public init(size: CGFloat = 16, label: String? = nil) {
        kind = .spinner(size: size)
        self.label = label
        showsPercent = false
        tint = BrandColors.onSecondary
    }

    /// the bar: `value` of `total`, clamped. `label` and the percent sit over it when given.
    public init(value: Double, total: Double = 1, label: String? = nil, showsPercent: Bool = true, tint: Color = BrandColors.accent) {
        kind = .bar(fraction: Self.fraction(value, of: total))
        self.label = label
        self.showsPercent = showsPercent && label != nil
        self.tint = tint
    }

    /// how full the bar is, from 0 to 1, whatever it is given
    static func fraction(_ value: Double, of total: Double) -> Double {
        guard total > 0, value.isFinite, total.isFinite else { return 0 }
        return min(max(value / total, 0), 1)
    }

    static func percent(_ fraction: Double) -> String {
        "\(Int((fraction * 100).rounded())) %"
    }

    public var body: some View {
        switch kind {
        case let .spinner(size):
            HStack(spacing: 8) {
                spinner(size)
                if let label {
                    Text(label).font(.brandCaption).foregroundStyle(BrandColors.onSecondary)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label ?? String(localized: "loading", bundle: .module))
        case let .bar(fraction):
            VStack(alignment: .leading, spacing: 6) {
                if let label {
                    HStack {
                        Text(label).foregroundStyle(BrandColors.onSecondary)
                        Spacer(minLength: 8)
                        if showsPercent {
                            Text(verbatim: Self.percent(fraction)).foregroundStyle(BrandColors.on).monospacedDigit()
                        }
                    }
                    .font(.brandCaption)
                }
                bar(fraction)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label ?? String(localized: "progress", bundle: .module))
            .accessibilityValue(Self.percent(fraction))
        }
    }

    private func spinner(_ size: CGFloat) -> some View {
        let line = max(size / 9, 1.5)
        return TimelineView(.animation(paused: reduceMotion)) { context in
            let turn = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 0.9) / 0.9
            ZStack {
                Circle().stroke(BrandColors.separator, lineWidth: line)
                Circle()
                    .trim(from: 0, to: 0.28)
                    .stroke(tint, style: StrokeStyle(lineWidth: line, lineCap: .round))
                    .rotationEffect(.degrees(reduceMotion ? -90 : turn * 360 - 90))
            }
            .padding(line / 2)
        }
        .frame(width: size, height: size)
    }

    private func bar(_ fraction: Double) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(BrandColors.surfaceSelected)
                Capsule()
                    .fill(tint)
                    .frame(width: fraction > 0 ? max(proxy.size.width * fraction, Self.barHeight) : 0)
            }
        }
        .frame(height: Self.barHeight)
        .animation(.easeOut(duration: 0.2), value: fraction)
    }

    #if os(macOS)
    static let barHeight: CGFloat = 4
    #else
    static let barHeight: CGFloat = 5
    #endif
}
