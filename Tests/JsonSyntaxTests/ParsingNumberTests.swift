//
//  ParsingNumberTests.swift
//  JsonSyntaxTests
//
//  Created by Oleg Ketrar on 25/05/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

import XCTest
@testable import JsonSyntax

final class ParsingNumberTests: XCTestCase {

    func testValid() {
        XCTAssert(try parse("0"))
        XCTAssert(try parse("10"))
        XCTAssert(try parse("-19"))
        XCTAssert(try parse("15.234"))
        XCTAssert(try parse("-0.2552"))
        XCTAssert(try parse("67e2"))
        XCTAssert(try parse("9e+2"))
        XCTAssert(try parse("1.0"))
        XCTAssert(try parse("0E-17"))
        XCTAssert(try parse("-0e8"))
        XCTAssert(try parse("2323.2E4"))
        XCTAssert(try parse("81e-0255"))
        XCTAssert(try parse("31e00"))
        XCTAssert(try parse("0.244e7"))
        XCTAssert(try parse("-56.230888"))
    }

    func testInvalid() {
        XCTAssertThrowsError(try parse("024"))
        XCTAssertThrowsError(try parse(".231232"))
        XCTAssertThrowsError(try parse("-0705"))
        XCTAssertThrowsError(try parse("-533."))
        XCTAssertThrowsError(try parse(".1"))
        XCTAssertThrowsError(try parse(".03"))
        XCTAssertThrowsError(try parse(".5e7"))
        XCTAssertThrowsError(try parse("+34"))
        XCTAssertThrowsError(try parse("+034"))
        XCTAssertThrowsError(try parse("1."))
        XCTAssertThrowsError(try parse("9E"))
    }
}

private extension ParsingNumberTests {

    func parse(_ str: String) throws -> Bool {

        let strRange = str.startIndex..<str.endIndex
        let token = Token(kind: .number(str), range: strRange)
        let expected = HighlightToken(kind: .numberValue, range: strRange)
        let parsedTokens = try Parser().parse([token]).getHighlightTokens()

        return parsedTokens.first == expected
    }
}
