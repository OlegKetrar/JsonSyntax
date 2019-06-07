
//
//  JsonSyntax.swift
//  JsonSyntax
//
//  Created by Oleg Ketrar on 20/05/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

public struct JsonSyntax {
    public init() {}

    public func parse(_ str: String) throws -> ParseTree {
        let tokens = try Lexer().lex(str)
        return try Parser().parse(tokens)
    }
}
