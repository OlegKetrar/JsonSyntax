//
//  DebugSupport.swift
//  JsonSyntax
//
//  Created by Oleg Ketrar on 17/05/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

extension Error: CustomStringConvertible {

    public var description: String {

        switch self {
        case let .lexer(str): return "lexer -> \(str)"
        case let .parser(str): return "parser -> \(str)"
        }
    }
}

extension Token: CustomStringConvertible {

    public var description: String {
        return "kind: \(kind), range: \(range.lowerBound) - \(range.upperBound)"
    }
}

extension Token.Kind: CustomStringConvertible {

    public var description: String {

        switch self {
        case let .syntax(s): return "syntax(\(s))"
        case let .string(s): return "string(\(s))"
        case let .number(d): return "number(\(d))"
        case let .literal(l): return "literal\(l)"
        }
    }
}

extension SyntaxToken: CustomStringConvertible {

    public var description: String {
        return "\(kind), range: \(range.lowerBound) - \(range.upperBound)"
    }
}
