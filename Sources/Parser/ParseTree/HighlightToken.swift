//
//  HighlightToken.swift
//  JsonSyntax
//
//  Created by Oleg Ketrar on 06/06/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

public struct HighlightToken: Equatable {

    public enum Kind: Equatable {
        case syntax(SyntaxCharacter)
        case key
        case stringValue
        case numberValue
        case literalValue(Literal)
    }

    public var kind: Kind
    public var pos: Pos
}

public enum SyntaxCharacter: Character, Equatable {
    case openBrace = "{"
    case closeBrace = "}"
    case openBracket = "["
    case closeBracket = "]"
    case comma = ","
    case colon = ":"
}

public enum Literal: String, Equatable {
    case null
    case `false`
    case `true`
}
