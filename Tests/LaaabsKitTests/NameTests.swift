import Testing
@testable import LaaabsKit

/// a string's "laaabs" is split out as ui-web's `Name` does: the dot stays with the name unless a
/// letter follows it
@Test func theNameIsFoundInText() {
    typealias P = NameGeometry.Piece
    #expect(NameGeometry.pieces(of: "things by laaabs.") == [P.plain("things by "), .name(withDot: true)])
    #expect(NameGeometry.pieces(of: "hello@laaabs.com") == [P.plain("hello@"), .name(withDot: false), .plain(".com")])
    #expect(NameGeometry.pieces(of: "bylaaabs on github") == [P.plain("by"), .name(withDot: false), .plain(" on github")])
    #expect(NameGeometry.pieces(of: "laaabs. makes tools") == [P.name(withDot: true), .plain(" makes tools")])
    #expect(NameGeometry.pieces(of: "no name here") == [P.plain("no name here")])
}
