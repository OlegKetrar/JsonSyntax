//
//  SyntaxToken.swift
//  JsonSyntax
//
//  Created by Oleg Ketrar on 20/05/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

public enum SyntaxToken: Equatable {
    case key(String)
    case stringValue(String)
    case integerValue(Int)
    case doubleValue(Double)
    case braces
    case brackets
    case boolValue
    case null
    case comma
    case colon
}
