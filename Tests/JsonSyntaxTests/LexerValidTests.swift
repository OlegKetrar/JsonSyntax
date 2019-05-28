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
        XCTAssert( try Lexer().lex("{}") == [
            .syntax(.leftBrace),
            .syntax(.rightBrace)
        ])
    }

    func testEmptyArray() {
        XCTAssert( try Lexer().lex("[]") == [
            .syntax(.leftBracket),
            .syntax(.rightBracket)
        ])
    }

    func testSimpleObject() {
        let str = #"{ "name" : "Ivan", "age": 10, "male": true }"#

        XCTAssert( try Lexer().lex(str) == [
            .syntax(.leftBrace),
            .string("name"),
            .syntax(.colon),
            .string("Ivan"),
            .syntax(.comma),
            .string("age"),
            .syntax(.colon),
            .number("10"),
            .syntax(.comma),
            .string("male"),
            .syntax(.colon),
            .literal(.true),
            .syntax(.rightBrace)
        ])
    }

    func testStringArray() {
        let str = #"[ "a", "ab", "abc", "abcd" ]"#

        XCTAssert( try Lexer().lex(str) == [
            .syntax(.leftBracket),
            .string("a"),
            .syntax(.comma),
            .string("ab"),
            .syntax(.comma),
            .string("abc"),
            .syntax(.comma),
            .string("abcd"),
            .syntax(.rightBracket)
        ])
    }
}
