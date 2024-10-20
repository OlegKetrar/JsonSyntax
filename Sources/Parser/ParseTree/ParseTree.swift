//
//  ParseTree.swift
//  JsonSyntax
//
//  Created by Oleg Ketrar on 20/05/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

import Foundation

public enum ParseTree: Equatable {

    public struct Arr: Equatable {
        public var pos: Pos
        public var items: [ParseTree]
        public var commas: [Pos]

        public init(pos: Pos, items: [ParseTree], commas: [Pos]) {
            self.pos = pos
            self.items = items
            self.commas = commas
        }
    }

    public struct Obj: Equatable {
        public var pos: Pos
        public var pairs: [KeyValue]
        public var commas: [Pos]

        public init(pos: Pos, pairs: [KeyValue], commas: [Pos]) {
            self.pos = pos
            self.pairs = pairs
            self.commas = commas
        }
    }

    public struct KeyValue: Equatable {
        public var pos: Pos
        public var keyPos: Pos
        public var value: ParseTree
        public var colonPos: Pos

        public init(keyPos: Pos, value: ParseTree, colonPos: Pos) {
            self.pos = .from(keyPos.start, to: value.pos.end)
            self.keyPos = keyPos
            self.value = value
            self.colonPos = colonPos
        }

        public var keyNamePos: Pos {
            var pos = Pos.from(keyPos.location + 1, keyPos.length - 2)

            if pos.length < 0 {
                pos.length = 0
            }

            return pos
        }
    }

    case string(Pos)
    case number(Pos)
    case literal(Pos, Literal)
    indirect case array(Arr)
    indirect case object(Obj)
}

public extension ParseTree {

    var pos: Pos {
        switch self {
        case let .literal(p, _): return p
        case let .number(p): return p
        case let .string(p): return p
        case let .array(node): return node.pos
        case let .object(node): return node.pos
        }
    }

    func getHighlightTokens() -> [HighlightToken] {
        var tokens: [HighlightToken] = []
        traverseHighlightTokens(into: &tokens)

        return tokens
    }

    func getFoldableScopes() -> [SyntaxScope] {
        var scopes: [SyntaxScope] = []
        traverseFoldableScopes(into: &scopes)

        return scopes
    }

    func getJsonKeyPath(for text: String, at position: Pos) -> JsonPath? {
        switch self {
        case .object, .array:
            guard
                let components = findPathRecursevelly(in: text, at: position),
                let first = components.first
            else { return nil }

            return JsonPath(
                head: first,
                tail: Swift.Array(components.dropFirst()))

        default:
            return nil
        }
    }
}

// MARK: - Traversing

private extension ParseTree {

    func resolveKeyPos(_ pos: Pos, _ text: String) -> String? {
        let nsRange = NSRange(location: pos.location, length: pos.length)

        if let range = Range<String.Index>(nsRange, in: text) {
            return String(text[range])
        } else {
            return nil
        }
    }

    func findPathRecursevelly(in text: String, at pos: Pos) -> [JsonPathComponent]? {

        switch self {
        case let .object(obj):
            for pair in obj.pairs {
                if pair.keyPos.contains(pos),
                   let keyName = resolveKeyPos(pair.keyNamePos, text) {
                    return [ .object(keyName) ]
                }

                if pair.value.pos.contains(pos),
                   let components = pair.value.findPathRecursevelly(in: text, at: pos),
                   let keyName = resolveKeyPos(pair.keyNamePos, text) {

                    return [ .object(keyName) ] + components
                }
            }

        case let .array(arr):
            for (index, item) in arr.items.enumerated() {
                if item.pos.contains(pos),
                   let components = item.findPathRecursevelly(in: text, at: pos) {

                    return [ .array(index) ] + components
                }
            }

        default:
            break
        }

        return nil
    }

    func traverseHighlightTokens(into array: inout [HighlightToken]) {

        switch self {
        case let .string(p): array.append(.stringValue, p)
        case let .number(p): array.append(.numberValue, p)
        case let .literal(p, l): array.append(.literalValue(l), p)

        case let .array(node):
            array.append(.syntax(.openBracket), .one(node.pos.start))

            var commaIterator = node.commas.makeIterator()

            for item in node.items {
                item.traverseHighlightTokens(into: &array)

                if let pos = commaIterator.next() {
                    array.append(.syntax(.comma), pos)
                }
            }

            array.append(.syntax(.closeBracket), .one(node.pos.end - 1))

        case let .object(node):
            array.append(.syntax(.openBrace), .one(node.pos.start))
            var commaIterator = node.commas.makeIterator()

            for pair in node.pairs {
                array.append(.key, pair.keyPos)
                array.append(.syntax(.colon), pair.colonPos)
                pair.value.traverseHighlightTokens(into: &array)

                if let pos = commaIterator.next() {
                    array.append(.syntax(.comma), pos)
                }
            }

            array.append(.syntax(.closeBrace), .one(node.pos.end - 1))
        }
    }

    func traverseFoldableScopes(into array: inout [SyntaxScope]) {

        switch self {
        case let .array(node):
            array.append(SyntaxScope(kind: .brackets, pos: node.pos))

            for value in node.items {
                value.traverseFoldableScopes(into: &array)
            }

        case let .object(node):
            array.append(SyntaxScope(kind: .braces, pos: node.pos))

            for pair in node.pairs {
                pair.value.traverseFoldableScopes(into: &array)
            }

        default:
            break
        }
    }
}

// MARK: - Convenience

private extension Array where Element == HighlightToken {

    mutating func append(_ kind: HighlightToken.Kind, _ pos: Pos) {
        append(HighlightToken(kind: kind, pos: pos))
    }
}
