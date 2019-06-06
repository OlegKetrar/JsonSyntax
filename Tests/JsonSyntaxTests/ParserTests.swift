//
//  ParserTests.swift
//  JsonSyntaxTests
//
//  Created by Oleg Ketrar on 01/06/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

import XCTest
@testable import JsonSyntax

final class ParserTests: XCTestCase {

    func testObject1() {
        let str = #"{ "age" : 16 }"#

        XCTAssert(try parse(str) == [
            .syntax(.openBrace),
            .key,
            .syntax(.colon),
            .numberValue,
            .syntax(.closeBrace)
        ])
    }

    func testObject2() {

        let str = #"{ "age" : 16, "name": "Alex" }"#

        XCTAssert(try parse(str) == [
            .syntax(.openBrace),
            .key,
            .syntax(.colon),
            .numberValue,
            .syntax(.comma),
            .key,
            .syntax(.colon),
            .stringValue,
            .syntax(.closeBrace)
        ])
    }

    func testNestedObject() {
        let str = #" { "nested": { "age" : 10 }, "first": "", "last": "bb" } "#

        XCTAssert(try parse(str) == [
            .syntax(.openBrace),
            .key,
            .syntax(.colon),
            .syntax(.openBrace),
            .key,
            .syntax(.colon),
            .numberValue,
            .syntax(.closeBrace),
            .syntax(.comma),
            .key,
            .syntax(.colon),
            .stringValue,
            .syntax(.comma),
            .key,
            .syntax(.colon),
            .stringValue,
            .syntax(.closeBrace)
        ])
    }

    func testDoubleNestedObject() {
        let str = #" { "a": { "b" : { "c": 1 } }, "first": "" } "#

        XCTAssert(try parse(str) == [
            .syntax(.openBrace),
            .key,
            .syntax(.colon),
            .syntax(.openBrace),
            .key,
            .syntax(.colon),
            .syntax(.openBrace),
            .key,
            .syntax(.colon),
            .numberValue,
            .syntax(.closeBrace),
            .syntax(.closeBrace),
            .syntax(.comma),
            .key,
            .syntax(.colon),
            .stringValue,
            .syntax(.closeBrace)
        ])
    }

    func testNestedArrayOfObjects() {
        let str = #" { "a": [ { "b": 1 }, { "c" : 3 } ], "e": "" }"#

        XCTAssert(try parse(str) == [
            .syntax(.openBrace),
            .key,
            .syntax(.colon),
            .syntax(.openBracket),

            .syntax(.openBrace),
            .key,
            .syntax(.colon),
            .numberValue,
            .syntax(.closeBrace),

            .syntax(.comma),

            .syntax(.openBrace),
            .key,
            .syntax(.colon),
            .numberValue,
            .syntax(.closeBrace),
            .syntax(.closeBracket),

            .syntax(.comma),
            .key,
            .syntax(.colon),
            .stringValue,
            .syntax(.closeBrace)
        ])
    }
}

private func parse(_ str: String) throws -> [HighlightToken.Kind] {
    return try JsonSyntax().parse(str).map { $0.kind }
}
