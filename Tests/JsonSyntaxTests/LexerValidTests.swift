//
//  LexerValidTests.swift
//  JsonSyntaxTests
//
//  Created by Oleg Ketrar on 21/05/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

import XCTest
@testable import JsonSyntax

final class LexerValidTests: XCTestCase {

    func testEmptyObject() {
        XCTAssert(try lex("{}") == [
            .syntax(.openBrace),
            .syntax(.closeBrace)
        ])
    }

    func testEmptyArray() {
        XCTAssert(try lex("[]") == [
            .syntax(.openBracket),
            .syntax(.closeBracket)
        ])
    }

    func testStringQuoteEscaping() {
        let str = #"{ "name": "escaped \" quote" }"#

        XCTAssert(try lex(str) == [
            .syntax(.openBrace),
            .string,
            .syntax(.colon),
            .string,
            .syntax(.closeBrace)
        ])
    }

    func testStringEscaping() {
        XCTAssert(try lex(#""abc\nde\tb \r \\aaa \/ a""#) == [.string])
    }

    func testInvalidStringUnbalancedQuotes() {
        XCTAssertThrowsError(try lex(#"{ "name": " }"#))
        XCTAssertThrowsError(try lex(#"{ "a": ""#))
        XCTAssertThrowsError(try lex(#""name"#))
    }

    // MARK: - Object

    func testObject1WithStringValue() {
        let str = #"{ "name" : "Ivan" }"#

        XCTAssert(try lex(str) == [
            .syntax(.openBrace),
            .string,
            .syntax(.colon),
            .string,
            .syntax(.closeBrace)
        ])
    }

    func testObject2WithStringValue() {
        let str = #"{ "name" : "Ivan", "surname" :"Petrovich"}"#

        XCTAssert(try lex(str) == [
            .syntax(.openBrace),
            .string,
            .syntax(.colon),
            .string,
            .syntax(.comma),
            .string,
            .syntax(.colon),
            .string,
            .syntax(.closeBrace)
        ])
    }

    func testObjectWithEmptyStringValue() {
        let str = #"{ "name" : "" }"#

        XCTAssert(try lex(str) == [
            .syntax(.openBrace),
            .string,
            .syntax(.colon),
            .string,
            .syntax(.closeBrace)
        ])
    }

    func testSimpleObjectWithIntValue() {
        let str = #"{ "age": 10 }"#

        XCTAssert(try lex(str) == [
            .syntax(.openBrace),
            .string,
            .syntax(.colon),
            .number("10"),
            .syntax(.closeBrace)
        ])
    }

    func testSimpleObject() {
        let str = #"{ "name" : "Ivan", "age": 10, "male": true }"#

        XCTAssert(try lex(str) == [
            .syntax(.openBrace),
            .string,
            .syntax(.colon),
            .string,
            .syntax(.comma),
            .string,
            .syntax(.colon),
            .number("10"),
            .syntax(.comma),
            .string,
            .syntax(.colon),
            .literal(.true),
            .syntax(.closeBrace)
        ])
    }

    // MARK: - Array

    func testStringArray() {
        let str = #"[ "a", "ab", "abc", "abcd" ]"#

        XCTAssert(try lex(str) == [
            .syntax(.openBracket),
            .string,
            .syntax(.comma),
            .string,
            .syntax(.comma),
            .string,
            .syntax(.comma),
            .string,
            .syntax(.closeBracket)
        ])
    }

    func testIntArray() {
        let str = #"[ 7, 89, -56, 2e+3, 400e-1, 0 ]"#

        XCTAssert(try lex(str) == [
            .syntax(.openBracket),
            .number("7"),
            .syntax(.comma),
            .number("89"),
            .syntax(.comma),
            .number("-56"),
            .syntax(.comma),
            .number("2e+3"),
            .syntax(.comma),
            .number("400e-1"),
            .syntax(.comma),
            .number("0"),
            .syntax(.closeBracket)
        ])
    }

    func testFloatArray() {
        let str = #"[ 7.3, 89.145, -56.230888, 2.56108884324e+3, 40.003444e-1, 0.00, 0 ]"#

        XCTAssert(try lex(str) == [
            .syntax(.openBracket),
            .number("7.3"),
            .syntax(.comma),
            .number("89.145"),
            .syntax(.comma),
            .number("-56.230888"),
            .syntax(.comma),
            .number("2.56108884324e+3"),
            .syntax(.comma),
            .number("40.003444e-1"),
            .syntax(.comma),
            .number("0.00"),
            .syntax(.comma),
            .number("0"),
            .syntax(.closeBracket)
        ])
    }
}

private func lex(_ str: String) throws -> [Token.Kind] {
    return try Lexer().lex(str).map { $0.kind }
}
