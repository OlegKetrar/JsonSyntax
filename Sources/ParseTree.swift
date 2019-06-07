//
//  ParseTree.swift
//  JsonSyntax
//
//  Created by Oleg Ketrar on 20/05/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

public enum ParseTree {
    public typealias Index = String.Index
    public typealias Range = Swift.Range<Index>

    case literal(LiteralNode)
    case number(NumberNode)
    case string(StringNode)
    case array(ArrayNode)
    case object(ObjectNode)
}

// MARK: -

public struct LiteralNode {
    public var range: ParseTree.Range
    public var value: Literal
}

public struct StringNode {
    public var range: ParseTree.Range
}

public struct NumberNode {
    public var range: ParseTree.Range
}

public struct ArrayNode {
    public var range: ParseTree.Range
    public var items: [ParseTree]
    public var commaRanges: [ParseTree.Range]
    public var openBracketRange: ParseTree.Range
    public var closeBracketRange: ParseTree.Range

    init(
        range: ParseTree.Range,
        items: [ParseTree],
        commaRanges: [ParseTree.Range],
        openBracketRange: ParseTree.Range,
        closeBracketRange: ParseTree.Range) {

        if items.isEmpty {
            assert(commaRanges.isEmpty, """
                `pairs.count = \(items.count)` not in sync with \
                `commaRanges.count = \(commaRanges.count)`
                """)
        } else {
            assert(items.count - 1 == commaRanges.count, """
                pairs.count = \(items.count)` not in sync with \
                `commaRanges.count = \(commaRanges.count)`
                """)
        }

        self.range = range
        self.items = items
        self.commaRanges = commaRanges
        self.openBracketRange = openBracketRange
        self.closeBracketRange = closeBracketRange
    }
}

public struct ObjectNode {
    public var range: ParseTree.Range
    public var pairs: [KeyValuePairNode]
    public var commaRanges: [ParseTree.Range]
    public var openBraceRange: ParseTree.Range
    public var closeBraceRange: ParseTree.Range

    init(
        range: ParseTree.Range,
        pairs: [KeyValuePairNode],
        commaRanges: [ParseTree.Range],
        openBraceRange: ParseTree.Range,
        closeBraceRange: ParseTree.Range) {

        if pairs.isEmpty {
            assert(commaRanges.isEmpty, """
               `pairs.count = \(pairs.count)` not in sync with \
                `commaRanges.count = \(commaRanges.count)`
               """)
        } else {
            assert(pairs.count - 1 == commaRanges.count, """
                pairs.count = \(pairs.count)` not in sync with \
                `commaRanges.count = \(commaRanges.count)`
                """)
        }

        self.range = range
        self.pairs = pairs
        self.commaRanges = commaRanges
        self.openBraceRange = openBraceRange
        self.closeBraceRange = closeBraceRange
    }
}

public struct KeyValuePairNode {
    public var range: ParseTree.Range
    public var key: StringNode
    public var value: ParseTree
    public var colonRange: ParseTree.Range
}

// MARK: - Traversing

public struct SyntaxScope {

    public enum Kind {
        case braces
        case brackets
    }

    public var lineIndex: Int
    public var range: ParseTree.Range
    public var kind: Kind
}

public extension ParseTree {

    init(jsonString: String) throws {
        self = .literal(LiteralNode(
            range: jsonString.startIndex..<jsonString.endIndex,
            value: .null))
    }

    init(jsonData: Data) throws {
        guard let str = String(data: jsonData, encoding: .utf8) else {
            throw Error.lexer("invalid data")
        }

        try self.init(jsonString: str)
    }

    func getHighlightTokens() -> [HighlightToken] {

        var tokens: [HighlightToken] = []
        traversHighlightTokens(into: &tokens)

        return tokens
    }

    private func traversHighlightTokens(into array: inout [HighlightToken]) {

        switch self {
        case let .string(node): array.append(.stringValue, node.range)
        case let .number(node): array.append(.numberValue, node.range)
        case let .literal(node): array.append(.literalValue(node.value), node.range)

        case let .array(node):
            array.append(.syntax(.openBracket), node.openBracketRange)

            var commaIterator = node.commaRanges.makeIterator()

            for item in node.items {
                item.traversHighlightTokens(into: &array)

                if let commaRange = commaIterator.next() {
                    array.append(.syntax(.comma), commaRange)
                }
            }

            array.append(.syntax(.closeBracket), node.closeBracketRange)

        case let .object(node):
            array.append(.syntax(.openBrace), node.openBraceRange)
            var commaIterator = node.commaRanges.makeIterator()

            for pair in node.pairs {
                array.append(.key, pair.key.range)
                array.append(.syntax(.colon), pair.colonRange)
                pair.value.traversHighlightTokens(into: &array)

                if let commaRange = commaIterator.next() {
                    array.append(.syntax(.comma), commaRange)
                }
            }

            array.append(.syntax(.closeBrace), node.closeBraceRange)
        }
    }

    func getFoldableScopes() -> [SyntaxScope] {
        fatalError()
    }

    func getNearestScopeForPosition(_ position: String.Index) -> SyntaxScope? {
        fatalError()
    }
}

// MARK: - Convenience

extension ParseTree {

    static func numberNode(_ range: Range) -> ParseTree {
        return .number(NumberNode(range: range))
    }

    static func stringNode(_ range: Range) -> ParseTree {
        return .string(StringNode(range: range))
    }

    static func literalNode(_ range: Range, _ value: Literal) -> ParseTree {
        return .literal(LiteralNode(range: range, value: value))
    }

    var range: Range {
        switch self {
        case let .literal(value): return value.range
        case let .number(value): return value.range
        case let .string(value): return value.range
        case let .array(value): return value.range
        case let .object(value): return value.range
        }
    }
}

private extension Array where Element == HighlightToken {

    mutating func append(
        _ kind: HighlightToken.Kind,
        _ range: Range<String.Index>) {

        append(HighlightToken(kind: kind, range: range))
    }
}
