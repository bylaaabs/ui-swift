import Foundation
// the marks are part of the kit: `import LaaabsKit` is enough to name one
@_exported import LaaabsWordmarks
// and so are the tokens brand generates (`BrandTokens.Colors.success`)
@_exported import LaaabsTokens

/// the kit's own resource bundle (fonts, its strings), for the tests, which have a bundle of their own
enum KitBundle {
    static var bundle: Bundle { .module }
}
