//
//  Token.swift
//  JsonSyntax
//
//  Created by Oleg Ketrar on 20/05/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

public enum Token: Equatable {

    public enum Syntax: Character, Equatable {
        case leftBrace = "{"
        case rightBrace = "}"
        case leftBracket = "["
        case rightBracket = "]"
        case comma = ","
        case colon = ":"
    }

    public enum Literal: String, Equatable {
        case null
        case `false`
        case `true`
    }

    case syntax(Syntax)
    case string(String)
    case number(String)
    case literal(Literal)
}
