import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// the three weights the studio's name is drawn in, to sit next to text of the same weight
public enum NameWeight: Int, Sendable {
    case medium = 500
    case semibold = 600
    case bold = 700
}

/// the trailing dot of the name: cyan (the mark), the colour of the letters, or none (a domain, an address)
public enum NameDot: Sendable {
    case cyan
    case text
    case none
}

public extension Text {
    /// the studio's name inside a line of text, as ui-web's `Laaabs`: at 1 em, on the baseline, with
    /// outfit's side bearings, so it reads as the word "laaabs." set in outfit. it is a `Text`, so it
    /// goes inside any other and wraps with it:
    ///
    ///     Text("things by \(Text.laaabs(size: 13))")
    ///
    /// `size` is the size of the text around it and `weight` its weight. screen readers hear "laaabs.".
    static func laaabs(size: CGFloat, weight: NameWeight = .medium, dot: NameDot = .cyan, color: Color = .white) -> Text {
        let mark: WordmarkName = switch (weight, dot) {
        case (.bold, .none): .laaabsNodot
        case (.semibold, .none): .laaabs600Nodot
        case (.medium, .none): .laaabs500Nodot
        case (.bold, _): .laaabs
        case (.semibold, _): .laaabs600
        case (.medium, _): .laaabs500
        }
        let side = NameGeometry.bearings[weight]!
        let right = dot == .none ? side.nodot : side.dot
        return inlineMark(mark, size: size, left: side.left, right: right, dotColor: dot == .cyan ? .laaabsCyan : color, color: color, label: dot == .none ? "laaabs" : "laaabs.")
    }

    /// a product's mark inside a line of text, at 1 em and on the baseline (the marks are outfit 700)
    static func mark(_ name: WordmarkName, size: CGFloat, color: Color = .white) -> Text {
        let side = NameGeometry.bearings[.bold]!
        return inlineMark(name, size: size, left: side.left, right: side.dot, dotColor: .laaabsCyan, color: color, label: name.rawValue)
    }

    /// text that comes as a string (copy, data, addresses) with every "laaabs" in it drawn, as ui-web's
    /// `Name`: "laaabs." at the end or before a space keeps its dot, "laaabs.com" and "bylaaabs" do not.
    ///
    ///     Text.name("hello@laaabs.com", size: 13)
    ///
    /// the plain pieces take the font and colour the caller gives the result.
    static func name(_ string: String, size: CGFloat, weight: NameWeight = .medium, dot: NameDot = .cyan, color: Color = .white) -> Text {
        NameGeometry.pieces(of: string).reduce(Text(verbatim: "")) { text, piece in
            switch piece {
            case let .plain(s): Text("\(text)\(Text(verbatim: s))")
            case .name(withDot: true): Text("\(text)\(Text.laaabs(size: size, weight: weight, dot: dot, color: color))")
            case .name(withDot: false): Text("\(text)\(Text.laaabs(size: size, weight: weight, dot: .none, color: color))")
            }
        }
    }

    private static func inlineMark(_ name: WordmarkName, size: CGFloat, left: Double, right: Double, dotColor: Color, color: Color, label: String) -> Text {
        let data = Wordmarks.data(name)
        let scale = size / NameGeometry.em
        // the box hangs below the baseline by the round letters' overshoot (and a descender)
        let overhang = (data.viewBox.height - data.letterHeight) * scale
        let image = NameGeometry.image(data, scale: scale, left: left * scale, right: right * scale, color: color, dotColor: dotColor, label: label)
        return Text(image).baselineOffset(-overhang)
    }
}

/// the numbers behind the inline name, shared with ui-web
enum NameGeometry {
    /// the marks are outfit at a 2000 unit em
    static let em: Double = 2000

    /// outfit's side bearings around the ink, measured at each weight (the same table as ui-web)
    static let bearings: [NameWeight: (left: Double, dot: Double, nodot: Double)] = [
        .bold: (108, 118, 37),
        .semibold: (115, 131, 48.5),
        .medium: (122, 144, 60),
    ]

    enum Piece: Equatable {
        case plain(String)
        case name(withDot: Bool)
    }

    /// splits a string around every "laaabs": the dot stays with the name unless a letter follows it
    /// (then it is a domain's dot)
    static func pieces(of string: String) -> [Piece] {
        var out: [Piece] = []
        var rest = Substring(string)
        while let range = rest.range(of: "laaabs", options: .caseInsensitive) {
            if range.lowerBound > rest.startIndex { out.append(.plain(String(rest[..<range.lowerBound]))) }
            var end = range.upperBound
            var withDot = false
            if end < rest.endIndex, rest[end] == "." {
                let next = rest.index(after: end)
                if next == rest.endIndex || !rest[next].isLetter {
                    withDot = true
                    end = next
                }
            }
            out.append(.name(withDot: withDot))
            rest = rest[end...]
        }
        if !rest.isEmpty { out.append(.plain(String(rest))) }
        return out
    }

    /// the mark drawn as an image the size of the text, with the side bearings as empty margins
    static func image(_ data: WordmarkData, scale: Double, left: Double, right: Double, color: Color, dotColor: Color, label: String) -> Image {
        let box = data.viewBox
        let size = CGSize(width: box.width * scale + left + right, height: box.height * scale)
        let paths = data.paths.map { (path: PathData.path($0.d).cgPath, eo: !$0.nonzero, dot: $0.isDot) }
        // both contexts below have their origin top left, as the vectors do
        let draw = { (context: CGContext) in
            context.saveGState()
            context.translateBy(x: left, y: 0)
            context.scaleBy(x: scale, y: scale)
            context.translateBy(x: -box.x, y: -box.y)
            for p in paths {
                context.addPath(p.path)
                context.setFillColor(resolve(p.dot ? dotColor : color))
                context.fillPath(using: p.eo ? .evenOdd : .winding)
            }
            context.restoreGState()
        }
        #if os(macOS)
        let image = NSImage(size: size, flipped: true) { _ in
            if let context = NSGraphicsContext.current?.cgContext { draw(context) }
            return true
        }
        image.accessibilityDescription = label
        return Image(nsImage: image)
        #else
        let image = UIGraphicsImageRenderer(size: size).image { draw($0.cgContext) }
        image.accessibilityLabel = label
        return Image(uiImage: image)
        #endif
    }

    private static func resolve(_ color: Color) -> CGColor {
        #if os(macOS)
        NSColor(color).cgColor
        #else
        UIColor(color).cgColor
        #endif
    }
}
