import SwiftUI

/// the cyan of the dot, and nowhere else as a solid colour (the brand's one signal)
public extension Color {
    static let laaabsCyan = Color(red: 0, green: 181 / 255, blue: 226 / 255)
}

/// a mark from brand: the studio, a product, the lema. drawn from the vectors, never set as text.
///
///     Wordmark(.baaar, height: 22)
///     Wordmark(.laaabs, height: 26, dot: .ink)
///
/// `height` is the height of the letters (the ascender), as on the web: marks of the same height line
/// up whatever their descenders. the view is a little taller where a mark has a descender or a
/// round letter overshoots.
public struct Wordmark: View {
    public enum Dot: Sendable {
        /// the brand's cyan
        case cyan
        /// the colour of the letters: a mark in one colour
        case ink
        /// any colour, for a dot that lights up or dims
        case color(Color)
    }

    let name: WordmarkName
    let height: CGFloat
    let ink: Color
    let dot: Dot

    public init(_ name: WordmarkName, height: CGFloat = 22, ink: Color = .white, dot: Dot = .cyan) {
        self.name = name
        self.height = height
        self.ink = ink
        self.dot = dot
    }

    public var body: some View {
        let data = Wordmarks.data(name)
        let box = data.viewBox
        let scale = height / data.letterHeight
        return ZStack(alignment: .topLeading) {
            ForEach(Array(data.paths.enumerated()), id: \.offset) { _, shape in
                WordmarkShape(d: shape.d, box: box)
                    .fill(color(for: shape), style: FillStyle(eoFill: !shape.nonzero, antialiased: true))
            }
        }
        .frame(width: box.width * scale, height: box.height * scale)
        .accessibilityElement()
        .accessibilityLabel(name == .laaabs ? "laaabs." : name.rawValue)
    }

    private func color(for shape: WordmarkPath) -> Color {
        guard shape.isDot else { return ink }
        switch dot {
        case .cyan: return .laaabsCyan
        case .ink: return ink
        case let .color(c): return c
        }
    }
}

/// one shape of a mark, scaled from the mark's box to the space it is given
struct WordmarkShape: Shape {
    let d: String
    let box: (x: Double, y: Double, width: Double, height: Double)

    func path(in rect: CGRect) -> Path {
        let sx = rect.width / box.width
        let sy = rect.height / box.height
        return PathData.path(d)
            .applying(CGAffineTransform(translationX: -box.x, y: -box.y))
            .applying(CGAffineTransform(scaleX: sx, y: sy))
    }
}
