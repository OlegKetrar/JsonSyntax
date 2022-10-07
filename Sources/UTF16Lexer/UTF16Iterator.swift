//
//  UTF16Iterator.swift
//  JsonSyntax
//
//  Created by Oleg Ketrar on 07.10.2022.
//  Copyright © 2022 Oleg Ketrar. All rights reserved.
//

struct UTF16Iterator {
    private(set) var index: Int = 0
    private let characters: String.UTF16View
    private var iterator: String.UTF16View.Iterator

    init(_ str: String) {
        self.characters = str.utf16
        self.iterator = characters.makeIterator()
    }

    mutating func consumeNext() -> UInt16? {
        guard let item = iterator.next() else { return nil }

        index += 1
        return item
    }

    mutating func consumePrefix(_ prefix: String) -> Bool {
        let oldIndex = index

        for char in prefix.utf16 {
            guard getCurrent() == char else {
                index = oldIndex
                return false
            }

            dropNext()
        }

        return true
    }

    mutating func dropNext() {
        if iterator.next() != nil {
            index += 1
        }
    }

    func getCurrent() -> UInt16? {
        utf16Index.map { characters[$0] }
    }

    var hasMore: Bool {
        utf16Index != nil
    }

    private var utf16Index: String.UTF16View.Index? {
        let start = characters.startIndex
        let utf16 = characters.index(start, offsetBy: index)

        if characters.indices.contains(utf16) {
            return utf16
        } else {
            return nil
        }
    }
}
