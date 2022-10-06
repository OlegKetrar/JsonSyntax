//
//  CCharIterator.swift
//  JsonSyntax
//
//  Created by Oleg Ketrar on 02/07/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

struct CCharIterator {
    private(set) var index: Int = 0
    private let chars: ContiguousArray<CChar>

    init(_ str: String) {
        var chars = str.utf8CString
        chars.removeLast() // remove last `\0`

        self.chars = chars
    }

    mutating func consumeNext() -> CChar? {
        guard let item = chars.item(at: index) else { return nil }

        index += 1
        return item
    }

    mutating func consumePrefix(_ prefix: String) -> Bool {

        let oldIndex = index
        var charPrefix = prefix.utf8CString
        charPrefix.removeLast() // remove last `\0`

        for char in charPrefix {
            guard consumeNext() == char else {
                index = oldIndex
                return false
            }
        }

        return true
    }

    mutating func dropNext() {
        if hasMore {
            index += 1
        }
    }

    func getCurrent() -> CChar? {
        return chars.item(at: index)
    }

    var hasMore: Bool {
        return chars.indices.contains(index)
    }
}
