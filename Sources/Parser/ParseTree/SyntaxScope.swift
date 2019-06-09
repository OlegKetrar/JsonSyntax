//
//  SyntaxScope.swift
//  JsonSyntax
//
//  Created by Oleg Ketrar on 12/06/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

public struct SyntaxScope: Equatable {

    public enum Kind: Equatable {
        case braces
        case brackets
        case quotes
    }

    public var kind: Kind
    public var pos: Pos
}
