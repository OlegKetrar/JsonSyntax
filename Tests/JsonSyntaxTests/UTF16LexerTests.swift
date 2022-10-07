//
//  UTF16LexerTests.swift
//  JsonSyntax
//
//  Created by Oleg Ketrar on 07.10.2022.
//

import XCTest
@testable import JsonSyntax

final class UTF16LexerTests: XCTestCase {

    func test_emptyString_empty() {
        XCTAssert(try UTF16Lexer().lex("") == [])
    }

    func test_unicodeStringValue() throws {
        try lex(#""ывф фв""#)
        try lex(#""💩""#)
        try lex(#""€""#)
    }

    func test_valid() throws {
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

    func test_invalid() {
        XCTAssertThrowsError(try lex("\""))
        XCTAssertThrowsError(try lex(#""\u""#))
        XCTAssertThrowsError(try lex(#""\uFFFS""#))
        XCTAssertThrowsError(try lex(#""\u00F""#))
        XCTAssertThrowsError(try lex(#""\\\""#))
        XCTAssertThrowsError(try lex(#""\uD800""#))
        XCTAssertThrowsError(try lex(#""\z""#))
        XCTAssertThrowsError(try lex(#""\""#))
        XCTAssertThrowsError(try lex(#""\"#))
    }
}

private extension UTF16LexerTests {

    func lex(
        _ str: String,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {

        let utf16Count = (str as NSString).length
        let tokens = try UTF16Lexer().lex(str)

        let token = try XCTUnwrap(tokens.first, file: file, line: line)

        XCTAssertEqual(token.kind, .string, file: file, line: line)
        XCTAssertEqual(token.pos.start, 0, "start", file: file, line: line)
        XCTAssertEqual(token.pos.length, utf16Count, "length", file: file, line: line)
    }
}
