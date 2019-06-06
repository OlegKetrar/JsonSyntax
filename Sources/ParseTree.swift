//
//  ParseTree.swift
//  JsonSyntax
//
//  Created by Oleg Ketrar on 20/05/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

public enum ParseTree {
    case literal(LiteralNode)
    case number(NumberNode)
    case string(StringNode)
    case array(ArrayNode)
    case object(ObjectNode)
}

// MARK: -

public struct LiteralNode {
    public var range: Range<String.Index>
    public var value: Literal
}

public struct StringNode {
    public var range: Range<String.Index>
    public var value: String
    public var openQuoteIndex: String.Index
    public var closeQuoteIndex: String.Index
}

public struct NumberNode {
    public var range: Range<String.Index>
    public var value: Double
}

public struct ArrayNode {
    public var range: Range<String.Index>
    public var items: [ParseTree]
    public var commaIndexes: [String.Index]
    public var openBracketIndex: String.Index
    public var closeBracketIndex: String.Index
}

public struct ObjectNode {
    public var range: Range<String.Index>
    public var items: [KeyValuePairNode]
    public var commaIndexes: [String.Index]
    public var openBraceIndex: String.Index
    public var closeBraceIndex: String.Index
}

public struct KeyValuePairNode {
    public var range: Range<String.Index>
    public var key: StringNode
    public var value: ParseTree
    public var colonIndexes: [String.Index]
}

// MARK: - Traversing

public struct SyntaxScope {

    public enum Kind {
        case braces
        case brackets
    }

    public var lineIndex: Int
    public var range: Range<String.Index>
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
        fatalError()
    }

    func getFoldableScopes() -> [SyntaxScope] {
        fatalError()
    }

    func getNearestScopeForPosition(_ position: String.Index) -> SyntaxScope? {
        fatalError()
    }
}
