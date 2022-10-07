//
//  JsonSyntax.swift
//  JsonSyntax
//
//  Created by Oleg Ketrar on 20/05/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

import Foundation

public struct JsonSyntax {
    public init() {}

    public func parse(_ data: Data) throws -> ParseTree {
        guard let str = String(data: data, encoding: .utf8) else {
            throw JsonSyntaxError.conversionDataToStringUTF8
        }

        let tokens = try Lexer().lex(str)
        return try Parser().parse(tokens)
    }

    public func parse(prettyPrinted str: String) throws -> ParseTree {
        let tokens = try UTF16Lexer().lex(str)
        return try Parser().parse(tokens)
    }
}
