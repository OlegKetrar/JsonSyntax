//
//  PerformanceTests.swift
//  JsonSyntaxTests
//
//  Created by Oleg Ketrar on 25/05/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

import XCTest
@testable import JsonSyntax

final class PerformanceTests: XCTestCase {

    func testLexerPerformance() {

        let sampleStr = SampleData(count: 35).getRawStr()
        print("-- \(sampleStr.count)")

        measure {
            do {
                _ = try Lexer().lex(sampleStr)
            } catch {
                XCTFail(error.description)
            }
        }
    }

    func testParserPerformance() {

        let jsonStr = SampleData(count: 35).getRawStr()
        let tokens = try! Lexer().lex(jsonStr)
        print("-- \(tokens.count)")

        measure {
            do {
                _ = try SyntaxParser().parse(tokens)
            } catch {
                XCTFail(error.description)
            }
        }
    }
}

extension Swift.Error {

    var description: String {
        return (self as? Error)?.description ?? localizedDescription
    }
}
