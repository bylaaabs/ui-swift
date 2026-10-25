import Foundation
import Testing
@testable import LaaabsKit

/// the words the kit says itself ship in english and spanish, like every app's own
@Test(arguments: [("en", "granted"), ("es", "concedido")])
func theKitSpeaksBothLanguages(language: String, granted: String) throws {
    let path = try #require(KitBundle.bundle.path(forResource: language, ofType: "lproj"))
    let bundle = try #require(Bundle(path: path))
    #expect(bundle.localizedString(forKey: "granted", value: nil, table: nil) == granted)
}
