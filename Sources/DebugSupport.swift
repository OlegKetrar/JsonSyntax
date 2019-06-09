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

// MARK: -

extension HighlightToken: CustomStringConvertible {

    public var description: String {
        return "\(kind), pos: \(pos)"
    }
}

// MARK: -

extension Token: CustomStringConvertible {

    var description: String {
        return "kind: \(kind), pos: \(pos)"
    }
}

extension Token.Kind: CustomStringConvertible {

    var description: String {

        switch self {
        case .string: return "string"
        case let .syntax(s): return "syntax(\(s))"
        case let .number(d): return "number(\(d))"
        case let .literal(l): return "literal\(l)"
        }
    }
}

extension Pos: CustomStringConvertible {

    public var description: String {
        return "\(start) ..< \(end)"
    }
}
