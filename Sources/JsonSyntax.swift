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

        let tokens = try Lexer(isStrictMode: true).lex(str)
        return try Parser().parse(tokens)
    }

    public func parse(_ str: String) throws -> ParseTree {
        let tokens = try Lexer(isStrictMode: false).lex(str)
        return try Parser().parse(tokens)
    }
}
