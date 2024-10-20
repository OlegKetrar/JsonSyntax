//
//  JsonPathTests.swift
//
//  Created by Oleg Ketrar on 20.10.2024.
//

import XCTest
import JsonSyntax

class JsonPathTests: XCtestCase {

    func test() {
        let

    }
}

class ParseTreeTests: XCTestCase {

    func test_findPath_rootValues_returnsNull() {
        XCTAssertNil(ParseTree.string(.one(1)).getPath(at: 1))
        XCTAssertNil(ParseTree.number(.one(1)).getPath(at: 1))
        XCTAssertNil(ParseTree.literal(.one(1), .true).getPath(at: 1))
        XCTAssertNil(ParseTree.literal(.one(1), .false).getPath(at: 1))
        XCTAssertNil(ParseTree.literal(.one(1), .null).getPath(at: 1))
    }

    func test_findPath_emptyObject_returnsNull() {
        let sut = ParseTree.object(Object(
            pos: Pos.from(0, 2),
            pairs: [],
            commas: []))

        XCTAssertNil(sut.getPath(at: .from(0, 2)))
    }

    func test_findPath_emptyArray_returnsNull() {
        let sut = ParseTree.array(Array(
            pos: Pos.from(0, 2),
            pairs: [],
            commas: []))

        XCTAssertNil(sut.getPath(at: .from(0, 2)))
    }
}
