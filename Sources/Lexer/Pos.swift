//
//  Pos.swift
//  JsonSyntax
//
//  Created by Oleg Ketrar on 07.10.2022.
//  Copyright © 2022 Oleg Ketrar. All rights reserved.
//

public struct Pos: Equatable {
    public var line: Int

    /// start location in whole string.
    public var location: Int
    public var length: Int

    private init(line: Int = 0, location: Int, length: Int) {
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

    public func contains(_ pos: Pos) -> Bool {
        pos.start >= start && pos.end <= end
    }

    public static func range(_ r: Range<Int>) -> Pos {
        return .init(location: r.lowerBound, length: r.upperBound - r.lowerBound)
    }

    public static func from(_ location: Int, _ length: Int) -> Pos {
        return .init(location: location, length: length)
    }

    public static func from(_ start: Int, to end: Int) -> Pos {
        return range(start..<end)
    }

    public static func one(_ location: Int) -> Pos {
        return .from(location, 1)
    }
}
