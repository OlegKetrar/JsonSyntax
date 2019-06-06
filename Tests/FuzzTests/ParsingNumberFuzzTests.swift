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
        let strRange = numberStr.startIndex..<numberStr.endIndex
        let token = Token(kind: .number(numberStr), range: strRange)
        let expected = SyntaxToken(kind: .numberValue, range: strRange)

        let expr = { try Parser().parse([token]) }

        switch TrustedParser.parseNumber(numberStr) {
        case .double, .integer:
            XCTAssert( try expr() == [expected], numberStr)

        case .error:
            XCTAssertThrowsError(try expr(), numberStr)
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
