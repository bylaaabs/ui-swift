import SwiftUI
import Testing
@testable import LaaabsKit

/// the app's mark keeps the box the apps' own wordmark had: `height` from the top of the letters to the
/// bottom of the round ones, a descender below the view
@MainActor @Test func theAppMarkKeepsTheAppsBox() {
    Wordmark.appMark = .caaapture
    let app = NSHostingView(rootView: Wordmark(height: 28)).fittingSize
    let plain = NSHostingView(rootView: Wordmark(.caaapture, height: 28)).fittingSize
    #expect(app.height == 28)
    #expect(plain.height > 28)
    // the same type size as the apps' marks: 8594.2 units wide over a 1474 unit box (caaapture, outfit 700)
    #expect(abs(app.width - 8594.2 * 28 / 1474) < 12)
}
