//
//  ParsingNumberFuzzTests.swift
//  JsonSyntaxTests
//
//  Created by Oleg Ketrar on 25/05/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

import XCTest
@testable import JsonSyntax

final class ParsingNumberFuzzTests: XCTestCase {

    override func invokeTest() {
        for _ in 0..<10000 {
            super.invokeTest()
        }
    }

    func testRandom() {

        let numberStr = NumericTokenGenerator().generateRandom()
        let expr = { try SyntaxParser().parse([.number(numberStr)]) }

        switch TrustedParser.parseNumber(numberStr) {
        case let .double(val):
            XCTAssert( try expr() == [.doubleValue(val)], numberStr)

        case let .integer(val):
            XCTAssert( try expr() == [.integerValue(val)], numberStr)

        case .error:
            XCTAssertThrowsError(try expr(), numberStr)
        }
    }
}

private struct TrustedParser {

    enum NumberResult {
        case double(Double)
        case integer(Int)
        case error
    }

    static func parseNumber(_ str: String) -> NumberResult {
        guard let data = "[\(str)]".data(using: .utf8) else { return .error }

        func parse<T: Decodable>() -> T? {
            return try? JSONDecoder().decode([T].self, from: data).first
        }

        if let val: Int = parse() {
            return .integer(val)
        } else if let val: Double = parse() {
            return .double(val)
        } else {
            return .error
        }
    }
}

private struct NumericTokenGenerator {
    private let chars = "0123456789-+eE.".map { $0 }

    func generateRandom() -> String {

        let tokenLength = Int.random(in: 1...10)
        let indexRange = 0..<chars.count

        return (0..<tokenLength)
            .map { _ in Int.random(in: indexRange) }
            .map { String(chars[$0]) }
            .joined()
    }
}
