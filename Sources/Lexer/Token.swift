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
        case string
        case number(String)
        case literal(Literal)
    }

    var kind: Kind
    var pos: Pos
}

public struct Pos: Equatable {
    public var line: Int

    /// start location in whole string.
    public var location: Int
    public var length: Int

    init(line: Int = 0, location: Int, length: Int) {
        self.line = line
        self.location = location
        self.length = length
    }

    public var start: Int {
        return location
    }

    public var end: Int {
        return location + length
    }

    static func range(_ r: Range<Int>) -> Pos {
        return .init(location: r.lowerBound, length: r.upperBound - r.lowerBound)
    }

    static func from(_ location: Int, _ length: Int) -> Pos {
        return .init(location: location, length: length)
    }

    static func from(_ start: Int, to end: Int) -> Pos {
        return range(start..<end)
    }

    static func one(_ location: Int) -> Pos {
        return .from(location, 1)
    }
}
