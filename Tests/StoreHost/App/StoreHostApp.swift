import SwiftUI

/// an empty app, only so storekit's local test store has an app to answer: the subscription tests
/// run inside it (`xcodegen generate && xcodebuild test -scheme StoreHost`, see the readme)
@main
struct StoreHostApp: App {
    var body: some Scene {
        WindowGroup { Text(verbatim: "the kit's store tests run here") }
    }
}
