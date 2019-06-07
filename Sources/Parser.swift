//
//  Parser.swift
//  JsonSyntax
//
//  Created by Oleg Ketrar on 17/05/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

struct Parser {

    func parse(_ tokens: [Token]) throws -> ParseTree {

        guard !tokens.isEmpty else {
            throw Error.parser("no tokens available")
        }

        let (parsed, parsedTokensCount) = try parseJsonValue(tokens[...])

        guard parsedTokensCount == tokens.count else {
            throw Error.parser(.errorInvalidSyntax)
        }

        return parsed
    }
}

// MARK: - Private

private extension Parser {

    func parseJsonValue(_ tokens: ArraySlice<Token>) throws -> (ParseTree, Int) {

        guard let token = tokens.first else {
            throw Error.parser(.errorInvalidSyntax)
        }

        switch token.kind {
        case let .number(valStr):
            try parseNumber(valStr)
            return (.numberNode(token.range), 1)

        case .string:
            return (.stringNode(token.range), 1)

        case let .literal(val):
            return (.literalNode(token.range, val), 1)

        case .syntax(.openBrace):
            let (objectNode, count) = try parseObject(tokens)
            return (.object(objectNode), count)

        case .syntax(.openBracket):
            let (arrayNode, count) = try parseArray(tokens)
            return (.array(arrayNode), count)

        default:
            throw Error.parser(.errorInvalidSyntax)
        }
    }

    /// First token MUST be `.syntax(.openBrace)`.
    func parseObject(_ tokens: ArraySlice<Token>) throws -> (ObjectNode, Int) {

        // tokens can't be empty, we already check on the caller side
        let first = tokens.first!

        guard let second = tokens.item(atAdjustedIndex: 1) else {
            throw Error.parser(.errorInvalidSyntax)
        }

        guard second.kind != .syntax(.closeBrace) else { // `{}`
            let range = first.range.lowerBound..<second.range.upperBound
            return (
                ObjectNode(
                    range: range,
                    pairs: [],
                    commaRanges: [],
                    openBraceRange: first.range,
                    closeBraceRange: second.range),
                2)
        }

        var mutTokens = tokens.dropFirst()
        var childPairs: [KeyValuePairNode] = []
        var commaRanges: [ParseTree.Range] = []
        var tokenCount: Int = 1

        while true {

            let (pairNode, parsedCount) = try parseKeyValuePair(mutTokens)
            childPairs.append(pairNode)
            mutTokens = mutTokens.dropFirst(parsedCount)
            tokenCount += parsedCount

            guard let nextToken = mutTokens.first else {
                throw Error.parser("unexpected end of an object")
            }

            switch nextToken.kind {

            case .syntax(.closeBrace):
                let arrayNode = ObjectNode(
                    range: first.range.lowerBound..<nextToken.range.upperBound,
                    pairs: childPairs,
                    commaRanges: commaRanges,
                    openBraceRange: first.range,
                    closeBraceRange: nextToken.range)

                return (arrayNode, tokenCount + 1)

            case .syntax(.comma):
                commaRanges.append(nextToken.range)
                mutTokens = mutTokens.dropFirst()
                tokenCount += 1

            default:
                throw Error.parser("expecting `,` or `}` after key-value pair")
            }
        }
    }

    func parseKeyValuePair(
        _ tokens: ArraySlice<Token>) throws -> (KeyValuePairNode, Int) {

        guard let keyToken = tokens.first else {
            throw Error.parser("unexpected end of an object")
        }

        // parse string key
        guard case let .string(keyName) = keyToken.kind else {
            throw Error.parser("expecting string key in object")
        }

        guard !keyName.isEmpty else {
            throw Error.parser("object key can't be empty string")
        }

        var mutTokens = tokens.dropFirst()

        // parse colon
        guard
            let colonToken = mutTokens.first,
            case .syntax(.colon) = colonToken.kind
        else {
            throw Error.parser("expecting `:` after object key")
        }

        mutTokens = mutTokens.dropFirst()

        // parse value
        let (parsedValue, parsedCount) = try parseJsonValue(mutTokens)

        let pairNode = KeyValuePairNode(
            range: keyToken.range.lowerBound..<parsedValue.range.upperBound,
            key: StringNode(range: keyToken.range),
            value: parsedValue,
            colonRange: colonToken.range)

        return (pairNode, parsedCount + 2)
    }

    /// First token MUST be `.syntax(.openBracket)`.
    func parseArray(_ tokens: ArraySlice<Token>) throws -> (ArrayNode, Int) {

        // tokens can't be empty, we have check on the caller side
        let first = tokens.first!

        guard let second = tokens.item(atAdjustedIndex: 1) else {
            throw Error.parser(.errorInvalidSyntax)
        }

        guard second.kind != .syntax(.closeBracket) else { // `[]`
            let range = first.range.lowerBound..<second.range.upperBound
            return (
                ArrayNode(
                    range: range,
                    items: [],
                    commaRanges: [],
                    openBracketRange: first.range,
                    closeBracketRange: second.range),
                2)
        }

        var mutTokens = tokens.dropFirst()
        var childItems: [ParseTree] = []
        var commaRanges: [ParseTree.Range] = []
        var tokenCount: Int = 1

        while true {

            let (parsed, parsedCount) = try parseJsonValue(mutTokens)
            childItems.append(parsed)
            mutTokens = mutTokens.dropFirst(parsedCount)
            tokenCount += parsedCount

            // parse closing bracket or comma
            guard let nextToken = mutTokens.first else {
                throw Error.parser("unexpected end of an array")
            }

            switch nextToken.kind {

            case .syntax(.closeBracket):
                let arrayNode = ArrayNode(
                    range: first.range.lowerBound..<nextToken.range.upperBound,
                    items: childItems,
                    commaRanges: commaRanges,
                    openBracketRange: first.range,
                    closeBracketRange: nextToken.range)

                return (arrayNode, tokenCount + 1)

            case .syntax(.comma):
                commaRanges.append(nextToken.range)
                mutTokens = mutTokens.dropFirst()
                tokenCount += 1

            default:
                throw Error.parser("expecting `,` or `]` after value in array")
            }
        }
    }

    func parseNumber(_ str: String) throws {
        try str.validateNumber()
    }
}

// MARK: - Convenience

private extension String {

    static var errorInvalidSyntax: String {
        return "invalid syntax"
    }

    func validateNumber() throws {
        guard let firstChar = first else {
            throw Error.parser("Number token can't be empty string")
        }

        guard firstChar == "-" || firstChar.isJsonNumber else {
            throw Error.parser("Number token should start with `-` or digit")
        }

        guard count > 1 else {
            guard firstChar.isJsonNumber else {
                throw Error.parser("Only digits are valid chars for 1-length number")
            }

            return
        }

        let secondChar = self[index(after: startIndex)]

        // eliminate leading zero
        if firstChar == "-" {
            if secondChar == "0" {
                let thirdIndex = index(startIndex, offsetBy: 2)

                if indices.contains(thirdIndex) {
                    guard self[thirdIndex].isDotOrExp else {
                        throw Error.parser("Leading zeros are not allowed")
                    }

                } else {
                    return // `-0` is valid number
                }
            }

        } else {
            if firstChar == "0" {
                guard secondChar.isDotOrExp else {
                    throw Error.parser("Leading zeros are not allowed")
                }
            }
        }

        var hasExp: Bool = false
        var hasDot: Bool = false
        var previousChar: Character = firstChar

        // start from second
        for char in self[index(after: startIndex)...] {

            switch char {
            case let n where n.isJsonNumber: break

            // leading `-` already allowed
            case "-" where previousChar.isExp: break
            case "+" where previousChar.isExp: break
            case "e" where !hasExp && previousChar.isJsonNumber,
                 "E" where !hasExp && previousChar.isJsonNumber:
                hasExp = true

            // dot can't be after `e`
            case "." where !hasDot && !hasExp && previousChar.isJsonNumber:
                hasDot = true

            default:
                throw Error.parser("invalid number")
            }

            previousChar = char
        }

        guard last?.isJsonNumber == true else {
            throw Error.parser("Unexpected end of number token")
        }
    }
}

private extension Character {

    var isJsonNumber: Bool {
        let digits: ClosedRange<Int> = 0...9
        return digits.map { Character("\($0)") }.contains(self)
    }

    var isDotOrExp: Bool {
        return self == "." || isExp
    }

    var isExp: Bool {
        return self == "e" || self == "E"
    }
}

private extension ArraySlice {

    func item(atAdjustedIndex index: Int) -> Element? {
        let lowerBound = indices.lowerBound

        if indices.contains(lowerBound + index) {
            return self[lowerBound + index]
        } else {
            return nil
        }
    }
}
