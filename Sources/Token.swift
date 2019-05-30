//
//  Token.swift
//  JsonSyntax
//
//  Created by Oleg Ketrar on 20/05/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

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

public struct Token: Equatable {

    public enum Kind: Equatable {
        case syntax(SyntaxCharacter)
        case string(String)
        case number(String)
        case literal(Literal)
    }

    public var kind: Kind
    public var range: Range<String.Index>
}
