//
//  ParseTree.swift
//  JsonSyntax
//
//  Created by Oleg Ketrar on 20/05/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

public enum ParseTree: Equatable {
    public typealias Index = Int
    public typealias Range = Swift.Range<Index>

    public struct Array: Equatable {
        public var pos: Pos
        public var items: [ParseTree]
        public var commas: [Pos]
    }

    public struct Object: Equatable {
        public var pos: Pos
        public var pairs: [KeyValue]
        public var commas: [Pos]
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
    }

    case string(Pos)
    case number(Pos)
    case literal(Pos, Literal)
    indirect case array(Array)
    indirect case object(Object)
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
        traversHighlightTokens(into: &tokens)

        return tokens
    }

    func getFoldableScopes() -> [SyntaxScope] {
        var scopes: [SyntaxScope] = []
        traverseFoldableScopes(into: &scopes)

        return scopes
    }
}

// MARK: - Traversing

private extension ParseTree {

    func traversHighlightTokens(into array: inout [HighlightToken]) {

        switch self {
        case let .string(p): array.append(.stringValue, p)
        case let .number(p): array.append(.numberValue, p)
        case let .literal(p, l): array.append(.literalValue(l), p)

        case let .array(node):
            array.append(.syntax(.openBracket), .one(node.pos.start))

            var commaIterator = node.commas.makeIterator()

            for item in node.items {
                item.traversHighlightTokens(into: &array)

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
                pair.value.traversHighlightTokens(into: &array)

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
