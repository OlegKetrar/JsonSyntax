//
//  LexerStringTests.swift
//  JsonSyntaxTests
//
//  Created by Oleg Ketrar on 01/06/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

import XCTest
@testable import JsonSyntax

final class LexerStringTests: XCTestCase {

    func testValid() {
        XCTAssert(try lex(#" """#) == "")
        XCTAssert(try lex(#""name""#) == "name")
        XCTAssert(try lex(#"  "name"   "#) == "name")
        XCTAssert(try lex(#" "str\nn" "#) == "str\nn")
        XCTAssert(try lex(#" "\t\n\r" "#) == "\t\n\r")
        XCTAssert(try lex(#" "\uFFFF nn" "#) == "\u{FFFF} nn")
        XCTAssert(try lex(#" "pd \u0020 \u0009" "#) == "pd   \u{0009}")
        XCTAssert(try lex(#" "\\\r" "#) == "\\\r")
        XCTAssert(try lex(#" "\/" "#) == "/")
        XCTAssert(try lex(#" "/" "#) == "/")
    }

    func testInvalid() {
        XCTAssertThrowsError(try lex(#" ""#))
        XCTAssertThrowsError(try lex(#" "\u" "#))
        XCTAssertThrowsError(try lex(#" "\uFFFS" "#))
        XCTAssertThrowsError(try lex(#" "\u00F" "#))
        XCTAssertThrowsError(try lex(#" "\\\" "#))
        XCTAssertThrowsError(try lex(#" "\uD800" "#))
        XCTAssertThrowsError(try lex(#" "\z" "#))
        XCTAssertThrowsError(try lex(#" "\" "#))
        XCTAssertThrowsError(try lex(#" "\"#))
    }
}

private extension LexerStringTests {

    func lex(_ str: String) throws -> String? {

        guard
            let token = try Lexer().lex(str).first,
            case let .string(parsedStr) = token.kind
        else {
            return nil
        }

        return parsedStr
    }
}
