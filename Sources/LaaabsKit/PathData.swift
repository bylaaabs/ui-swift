import SwiftUI

/// svg path data as a SwiftUI `Path`. the vectors from brand only use absolute M, L, H, V, C and Z
/// (checked when brand generates them), so that is all this reads; anything else is a bug in brand.
enum PathData {
    static func path(_ d: String) -> Path {
        var path = Path()
        var numbers: [Double] = []
        var command: Character = " "
        var current = CGPoint.zero
        var start = CGPoint.zero

        func flush() {
            switch command {
            case "M":
                var i = 0
                while i + 1 < numbers.count {
                    let p = CGPoint(x: numbers[i], y: numbers[i + 1])
                    // pairs after the first moveto are implicit linetos
                    if i == 0 { path.move(to: p); start = p } else { path.addLine(to: p) }
                    current = p
                    i += 2
                }
            case "L":
                var i = 0
                while i + 1 < numbers.count {
                    current = CGPoint(x: numbers[i], y: numbers[i + 1])
                    path.addLine(to: current)
                    i += 2
                }
            case "H":
                for x in numbers { current = CGPoint(x: x, y: current.y); path.addLine(to: current) }
            case "V":
                for y in numbers { current = CGPoint(x: current.x, y: y); path.addLine(to: current) }
            case "C":
                var i = 0
                while i + 5 < numbers.count {
                    let c1 = CGPoint(x: numbers[i], y: numbers[i + 1])
                    let c2 = CGPoint(x: numbers[i + 2], y: numbers[i + 3])
                    current = CGPoint(x: numbers[i + 4], y: numbers[i + 5])
                    path.addCurve(to: current, control1: c1, control2: c2)
                    i += 6
                }
            case "Z":
                path.closeSubpath()
                current = start
            default:
                break
            }
            numbers.removeAll(keepingCapacity: true)
        }

        var token = ""
        func endNumber() {
            if !token.isEmpty, let n = Double(token) { numbers.append(n) }
            token = ""
        }
        for ch in d {
            if "MLHVCZ".contains(ch) {
                endNumber()
                flush()
                command = ch
            } else if ch == " " || ch == "," {
                endNumber()
            } else if ch == "-" && !token.isEmpty && token.last != "e" {
                // a minus starts a new number when it follows digits: "10-5" is 10 and -5
                endNumber()
                token = "-"
            } else {
                token.append(ch)
            }
        }
        endNumber()
        flush()
        return path
    }
}
