//
//  Error.swift
//  JsonSyntax
//
//  Created by Oleg Ketrar on 20/05/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

#warning("add `Pos` to error")

public enum Error: Swift.Error {
    case lexer(String)
    case parser(String)
}
