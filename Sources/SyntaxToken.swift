//
//  SyntaxToken.swift
//  JsonSyntax
//
//  Created by Oleg Ketrar on 20/05/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

public struct SyntaxToken: Equatable {

    public enum Kind: Equatable {
        case syntax(SyntaxCharacter)
        case key
        case stringValue
        case numberValue
        case literalValue(Literal)
    }

    public var kind: Kind
    public var range: Range<String.Index>
}
