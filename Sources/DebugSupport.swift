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

        switch self {
        case let .syntax(s): return "syntax(\(s))"
        case let .string(s): return "string(\(s))"
        case let .double(d): return "double(\(d))"
        case let .integer(n): return "integer(\(n))"
        case let .literal(l): return "literal\(l)"
        }
    }
}

extension SyntaxToken: CustomStringConvertible {

    public var description: String {

        switch self {
        case let .key(name): return "key(\(name))"
        case let .stringValue(val): return "string(\"\(val)\")"
        case let .integerValue(val): return "integer(\(val))"
        case let .doubleValue(val): return "double(\(val))"
        case .braces: return "braces"
        case .brackets: return "brackets"
        case .boolValue: return "boolValue"
        case .null: return "null"
        case .comma: return "comma"
        case .colon: return "colon"
        }
    }
}
