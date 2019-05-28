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

    func testA() {
        XCTAssert( try parse("-2e9") == [.doubleValue(-2e9)])
    }

    // MARK: - Valid

    func testValid() {
        XCTAssert( try parse("0") == [.integerValue(0)])
        XCTAssert( try parse("10") == [.integerValue(10)])
        XCTAssert( try parse("-19") == [.integerValue(-19)])
        XCTAssert( try parse("15.234") == [.doubleValue(15.234)])
        XCTAssert( try parse("-0.2552") == [.doubleValue(-0.2552)])
        XCTAssert( try parse("67e2") == [.doubleValue(67e2)])
        XCTAssert( try parse("9e+2") == [.doubleValue(9e+2)])
        XCTAssert( try parse("1.0") == [.doubleValue(1.0)])
        XCTAssert( try parse("0E-17") == [.doubleValue(0E-17)])
        XCTAssert( try parse("-0e8") == [.doubleValue(-0e8)])
        XCTAssert( try parse("2323.2E4") == [.doubleValue(2323.2E4)])
//        XCTAssert( try parse("8E2971") == [.doubleValue(8E2971)])
        XCTAssert( try parse("81e-0255") == [.doubleValue(81e-0255)])
        XCTAssert( try parse("31e00") == [.doubleValue(31e00)])
        XCTAssert( try parse("0.244e7") == [.doubleValue(0.244e7)])
        XCTAssert( try parse("-56.230888") == [.doubleValue(-56.230888)])
    }

    // MARK: - Invalid

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

    func parse(_ str: String) throws -> [SyntaxToken] {
        return try SyntaxParser().parse([.number(str)])
    }
}
