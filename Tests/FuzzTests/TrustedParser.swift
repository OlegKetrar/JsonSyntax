//
//  TrustedParser.swift
//  FuzzTests
//
//  Created by Oleg Ketrar on 01/06/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

import Foundation

struct TrustedParser {

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

    enum StringResult {
        case parsed(String)
        case error(String)
    }

    static func parseString(_ str: String) -> StringResult {
        guard let data = "[\(str)]".data(using: .utf8) else {
            return .error("can't convert to data")
        }

        do {
            let parsedArray = try JSONDecoder().decode([String].self, from: data)

            if let parsedStr = parsedArray.first {
                return .parsed(parsedStr)
            } else {
                return .error("parsed string is null")
            }

        } catch {
            return .error(error.localizedDescription)
        }
    }
}
