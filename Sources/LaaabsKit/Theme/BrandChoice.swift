// a choice among a few, each with its label and what it means, at a finger's height on iOS: the
// options of a question in paaager's batches, a pick from a list in a page, and the rows of a sort
// sheet (bylaaabs/paaager#53). one of them (a radio) or any of them (a check). the chosen row says so
// with the cyan mark, and in a card with the cyan wash too.

#if os(macOS)
import AppKit
#else
import UIKit
#endif
import SwiftUI

// MARK: - the pieces

/// one thing to choose: what it is, what it says, and what it means.
public struct BrandChoice<Value: Hashable> {
    public let value: Value
    public var label: String
    public var description: String?

    public init(_ label: String, description: String? = nil, value: Value) {
        self.value = value
        self.label = label
        self.description = description
    }
}

extension BrandChoice: Sendable where Value: Sendable {}

/// the mark in front of a choice.
public enum BrandChoiceMark: Sendable {
    /// a ring, filled cyan when chosen: one of them
    case radio
    /// a rounded square, solid cyan with a check when chosen: any of them
    case check
}

/// how a list of choices is drawn.
public enum BrandChoiceStyle: Sendable {
    /// in a ring of their own, hairlines between rows, the chosen one washed cyan (a page's options)
    case card
    /// rows on the ground they sit on, hairlines between them (a sheet, a settings block)
    case plain
}

/// what a tap does to a set of choices, apart from any view so the tests can look at it.
enum BrandChoicePick {
    /// one of them: the tapped one, always (tapping the chosen one keeps it)
    static func single<Value>(_ value: Value) -> Value { value }

    /// any of them: the tapped one comes in or goes out; past `limit`, nothing new comes in
    static func multi<Value: Hashable>(_ chosen: Set<Value>, toggling value: Value, limit: Int? = nil) -> Set<Value> {
        var chosen = chosen
        if chosen.contains(value) {
            chosen.remove(value)
        } else if limit.map({ chosen.count < $0 }) ?? true {
            chosen.insert(value)
        }
        return chosen
    }
}

// MARK: - one row

/// one choice: the mark, the label and an optional description under it, at least 44 pt high on iOS.
///
///     BrandChoiceRow("eu-west-3", description: "paris", isSelected: region == "eu-west-3") { region = "eu-west-3" }
public struct BrandChoiceRow: View {
    let label: String
    let description: String?
    let isSelected: Bool
    let mark: BrandChoiceMark
    let labelFont: Font?
    let washed: Bool
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false

    /// `labelFont` is the label's (`.brandMono` for regions and paths); `washed` lights the chosen row
    /// with the cyan wash, as a card's rows do.
    public init(
        _ label: String, description: String? = nil, isSelected: Bool, mark: BrandChoiceMark = .radio,
        labelFont: Font? = nil, washed: Bool = false, action: @escaping () -> Void
    ) {
        self.label = label
        self.description = description
        self.isSelected = isSelected
        self.mark = mark
        self.labelFont = labelFont
        self.washed = washed
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(alignment: description == nil ? .center : .firstTextBaseline, spacing: BrandChoiceMetrics.gap) {
                BrandChoiceMarkView(mark: mark, isOn: isSelected)
                    .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + BrandChoiceMetrics.markBaseline }
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(labelFont ?? BrandChoiceMetrics.labelFont)
                        .foregroundStyle(isSelected || !washed ? BrandColors.on : BrandColors.onBody)
                        .fixedSize(horizontal: false, vertical: true)
                    if let description {
                        Text(description)
                            .font(BrandChoiceMetrics.descriptionFont)
                            .foregroundStyle(BrandColors.onTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, BrandChoiceMetrics.rowH)
            .padding(.vertical, BrandChoiceMetrics.rowV)
            .frame(maxWidth: .infinity, minHeight: BrandChoiceMetrics.target, alignment: .leading)
            .background(background)
            .contentShape(Rectangle())
        }
        .buttonStyle(BrandChoicePress())
        .opacity(isEnabled ? 1 : 0.4)
        .onHover { isHovered = $0 }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(description.map { "\(label), \($0)" } ?? label)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var background: Color {
        if washed, isSelected { return BrandColors.accentWash }
        return isHovered ? BrandColors.surfaceHover : .clear
    }
}

/// the ring or the square in front of a choice.
struct BrandChoiceMarkView: View {
    let mark: BrandChoiceMark
    let isOn: Bool

    var body: some View {
        let size = BrandChoiceMetrics.mark
        Group {
            switch mark {
            case .radio:
                Circle()
                    .strokeBorder(isOn ? BrandColors.accent : BrandColors.border, lineWidth: isOn ? size * 0.3 : 1.5)
            case .check:
                RoundedRectangle(cornerRadius: size * 0.28)
                    .fill(isOn ? BrandColors.accent : .clear)
                    .overlay {
                        if isOn {
                            Image(systemName: "checkmark")
                                .font(.system(size: size * 0.6, weight: .bold))
                                .foregroundStyle(BrandColors.accentGlyph)
                        } else {
                            RoundedRectangle(cornerRadius: size * 0.28).strokeBorder(BrandColors.border, lineWidth: 1.5)
                        }
                    }
            }
        }
        .frame(width: size, height: size)
        .animation(.easeOut(duration: 0.12), value: isOn)
        .accessibilityHidden(true)
    }
}

private struct BrandChoicePress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? BrandColors.surfaceSelected : .clear)
    }
}

enum BrandChoiceMetrics {
    #if os(macOS)
    static let mark: CGFloat = 16
    static let gap: CGFloat = 10
    static let rowH: CGFloat = 11
    static let rowV: CGFloat = 8
    static let target: CGFloat = 32
    static let markBaseline: CGFloat = 4
    static var labelFont: Font { .outfit(13, weight: .semibold, relativeTo: .body) }
    #else
    static let mark: CGFloat = 20
    static let gap: CGFloat = 12
    static let rowH: CGFloat = 12
    static let rowV: CGFloat = 11
    /// a finger's target
    static let target: CGFloat = 44
    static let markBaseline: CGFloat = 5
    static var labelFont: Font { .outfit(15, weight: .semibold, relativeTo: .body) }
    #endif
    static var descriptionFont: Font { .brandCaption }
    static let cardRadius: CGFloat = 10
}

// MARK: - a list of them

/// a list of choices, one or any of them.
///
///     BrandChoiceList(selection: $order, choices: orders, style: .plain)            // one
///     BrandChoiceList(selection: $targets, choices: targets)                        // any of them
public struct BrandChoiceList<Value: Hashable>: View {
    let choices: [BrandChoice<Value>]
    let style: BrandChoiceStyle
    let mark: BrandChoiceMark
    let labelFont: Font?
    let isChosen: (Value) -> Bool
    let pick: (Value) -> Void

    @Environment(\.displayScale) private var scale

    /// one of them: a radio on each row.
    public init(selection: Binding<Value>, choices: [BrandChoice<Value>], style: BrandChoiceStyle = .card, labelFont: Font? = nil) {
        self.choices = choices
        self.style = style
        mark = .radio
        self.labelFont = labelFont
        isChosen = { $0 == selection.wrappedValue }
        pick = { selection.wrappedValue = BrandChoicePick.single($0) }
    }

    /// any of them: a check on each row; `limit` is how many can be chosen at once.
    public init(selection: Binding<Set<Value>>, choices: [BrandChoice<Value>], limit: Int? = nil, style: BrandChoiceStyle = .card, labelFont: Font? = nil) {
        self.choices = choices
        self.style = style
        mark = .check
        self.labelFont = labelFont
        isChosen = { selection.wrappedValue.contains($0) }
        pick = { selection.wrappedValue = BrandChoicePick.multi(selection.wrappedValue, toggling: $0, limit: limit) }
    }

    public var body: some View {
        let rows = VStack(spacing: 0) {
            ForEach(Array(choices.enumerated()), id: \.offset) { index, choice in
                if index > 0 {
                    BrandHLine(color: style == .card ? BrandColors.separator : BrandColors.separatorSolid)
                }
                BrandChoiceRow(
                    choice.label, description: choice.description, isSelected: isChosen(choice.value), mark: mark,
                    labelFont: labelFont, washed: style == .card
                ) { pick(choice.value) }
            }
        }
        switch style {
        case .card:
            rows
                .clipShape(RoundedRectangle(cornerRadius: BrandChoiceMetrics.cardRadius))
                .overlay(RoundedRectangle(cornerRadius: BrandChoiceMetrics.cardRadius).strokeBorder(BrandColors.separator, lineWidth: 1 / scale))
        case .plain:
            rows
        }
    }
}
