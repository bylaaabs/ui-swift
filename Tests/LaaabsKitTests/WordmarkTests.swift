import SwiftUI
import Testing
@testable import LaaabsKit

@Suite struct WordmarkTests {
    @Test(arguments: WordmarkName.allCases)
    func everyShapeReadsAndStaysInItsBox(_ name: WordmarkName) {
        let data = Wordmarks.data(name)
        #expect(!data.paths.isEmpty)
        for shape in data.paths {
            let bounds = PathData.path(shape.d).boundingRect
            #expect(!bounds.isEmpty, "\(name.rawValue): an empty shape")
            // a round letter or the dot may overshoot by a hair; more than a unit is a misread path
            #expect(bounds.minX >= data.viewBox.x - 1 && bounds.maxX <= data.viewBox.x + data.viewBox.width + 1, "\(name.rawValue): x out of the box")
            #expect(bounds.minY >= data.viewBox.y - 1 && bounds.maxY <= data.viewBox.y + data.viewBox.height + 1, "\(name.rawValue): y out of the box")
        }
    }

    @Test(arguments: WordmarkName.allCases.filter { !$0.rawValue.contains("nodot") })
    func theDotIsTheLastShapeAndTheRightmost(_ name: WordmarkName) {
        let data = Wordmarks.data(name)
        let dots = data.paths.filter(\.isDot)
        #expect(dots.count == 1, "\(name.rawValue): one dot")
        #expect(data.paths.last?.isDot == true)
        let dotX = PathData.path(dots[0].d).boundingRect.minX
        for shape in data.paths where !shape.isDot {
            #expect(PathData.path(shape.d).boundingRect.minX < dotX)
        }
    }

    @Test func readsTheNumbersTheVectorsUse() {
        let p = PathData.path("M0 0L10 0V10H0Z").boundingRect
        #expect(p == CGRect(x: 0, y: 0, width: 10, height: 10))
        let q = PathData.path("M5 5C5-5 15-5 15 5Z").boundingRect
        #expect(q.minY < 5)
    }
}
