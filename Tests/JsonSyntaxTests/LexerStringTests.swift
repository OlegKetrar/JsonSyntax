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
        XCTAssert(try lex("\"\""))
        XCTAssert(try lex(#""name""#))
        XCTAssert(try lex(#""name""#))
        XCTAssert(try lex(#""str\nn""#))
        XCTAssert(try lex(#""\t\n\r""#))
        XCTAssert(try lex(#""\uFFFF nn""#))
        XCTAssert(try lex(#""pd \u0020 \u0009""#))
        XCTAssert(try lex(#""\\\r""#))
        XCTAssert(try lex(#""\/""#))
        XCTAssert(try lex(#""/""#))
        XCTAssert(try lex(#""\uffff""#))
    }

    func testInvalid() {
        XCTAssertThrowsError(try lex("\""))
        XCTAssertThrowsError(try lex(#""\u""#))
        XCTAssertThrowsError(try lex(#""\uFFFS""#))
        XCTAssertThrowsError(try lex(#""\u00F""#))
        XCTAssertThrowsError(try lex(#""\\\""#))
//        XCTAssertThrowsError(try lex(#""\uD800""#))
        XCTAssertThrowsError(try lex(#""\z""#))
        XCTAssertThrowsError(try lex(#""\""#))
        XCTAssertThrowsError(try lex(#""\"#))
        XCTAssertThrowsError(try lex(#""ывф фв""#))
        XCTAssertThrowsError(try lex(#""💩""#))
    }
}

private extension LexerStringTests {

    func lex(_ str: String) throws -> Bool {
        guard
            let token = try Lexer().lex(str).first,
            token.kind == .string,
            token.pos.start == 0,
            token.pos.length == (str as NSString).length
        else {
            return false
        }

        return true
    }
}
