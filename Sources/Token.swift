//
//  Token.swift
//  JsonSyntax
//
//  Created by Oleg Ketrar on 20/05/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

struct Token: Equatable {

    enum Kind: Equatable {
        case syntax(SyntaxCharacter)
        case string(String)
        case number(String)
        case literal(Literal)
    }

    var kind: Kind
    var range: Range<String.Index>
}
