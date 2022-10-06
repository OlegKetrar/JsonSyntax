//
//  LexerStringTests.swift
//  JsonSyntaxTests
//
//  Created by Oleg Ketrar on 01/06/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

import XCTest
@testable import JsonSyntax

class LexerStringTests: XCTestCase {
    var isStrict: Bool = true

    func test_emptyString_empty() {
        XCTAssert(try Lexer(isStrictMode: true).lex("") == [])
    }

    func test_unicodeStringValue_softMode() throws {
        isStrict = false

        try lex(#""ывф фв""#)
        try lex(#""💩""#)
        try lex(#""€""#)
    }

    func test_strictMode_valid() throws {
        try lex("\"\"")
        try lex(#""name""#)
        try lex(#""name""#)
        try lex(#""str\nn""#)
        try lex(#""\t\n\r""#)
        try lex(#""\uFFFF nn""#)
        try lex(#""pd \u0020 \u0009""#)
        try lex(#""\\\r""#)
        try lex(#""\/""#)
        try lex(#""/""#)
        try lex(#""\uffff""#)
    }

    func test_strictMode_invalid() {
        XCTAssertThrowsError(try lex("\""))
        XCTAssertThrowsError(try lex(#""\u""#))
        XCTAssertThrowsError(try lex(#""\uFFFS""#))
        XCTAssertThrowsError(try lex(#""\u00F""#))
        XCTAssertThrowsError(try lex(#""\\\""#))
        XCTAssertThrowsError(try lex(#""\uD800""#))
        XCTAssertThrowsError(try lex(#""\z""#))
        XCTAssertThrowsError(try lex(#""\""#))
        XCTAssertThrowsError(try lex(#""\"#))
        XCTAssertThrowsError(try lex(#""ывф фв""#))
        XCTAssertThrowsError(try lex(#""💩""#))
    }
}

private extension LexerStringTests {

    func lex(
        _ str: String,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {

        let utf8Count = str.utf8.count
        let tokens = try Lexer(isStrictMode: isStrict).lex(str)

        let token = try XCTUnwrap(tokens.first, file: file, line: line)

        XCTAssertEqual(token.kind, .string, file: file, line: line)
        XCTAssertEqual(token.pos.start, 0, "start", file: file, line: line)
        XCTAssertEqual(token.pos.length, utf8Count, "length", file: file, line: line)
    }
}
