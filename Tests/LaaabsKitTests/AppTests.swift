import Foundation
import Testing
@testable import LaaabsKit

/// every error the layer can say is written in both languages
@Test(arguments: ["en", "es"]) func theErrorsAreWrittenInBothLanguages(language: String) throws {
    let path = try #require(KitBundle.bundle.path(forResource: language, ofType: "lproj"))
    let bundle = try #require(Bundle(path: path))
    let keys = [
        "the app store cannot be reached. check the connection and try again.",
        "the payment did not go through. nothing was charged.",
        "this apple account has no plan to restore.",
    ]
    for key in keys {
        let said = bundle.localizedString(forKey: key, value: "missing", table: nil)
        #expect(said != "missing")
        if language == "es" { #expect(said != key) }
    }
}

@Test func anOnboardingHasFourScreensAtMost() {
    #expect(BrandOnboarding.maximumPages == 4)
}
