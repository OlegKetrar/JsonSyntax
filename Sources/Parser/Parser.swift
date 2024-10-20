//
//  Parser.swift
//  JsonSyntax
//
//  Created by Oleg Ketrar on 17/05/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

#warning("fix numbers parsing")

struct Parser {

    func parse(_ tokens: [Token]) throws -> ParseTree {

        guard !tokens.isEmpty else {
            throw JsonSyntaxError.parser("no tokens available")
        }

        let (parsed, parsedTokensCount) = try parseJsonValue(tokens[...])

        guard parsedTokensCount == tokens.count else {
            throw JsonSyntaxError.parser(.errorInvalidSyntax)
        }

        return parsed
    }
}

// MARK: - Private

private extension Parser {

    func parseJsonValue(_ tokens: ArraySlice<Token>) throws -> (ParseTree, Int) {

        guard let token = tokens.first else {
            throw JsonSyntaxError.parser(.errorInvalidSyntax)
        }

        switch token.kind {
        case let .number(valStr):
            try parseNumber(valStr)
            return (.number(token.pos), 1)

        case .string:
            return (.string(token.pos), 1)

        case let .literal(val):
            return (.literal(token.pos, val), 1)

        case .syntax(.openBrace):
            let (node, count) = try parseObject(tokens)
            return (.object(node), count)

        case .syntax(.openBracket):
            let (node, count) = try parseArray(tokens)
            return (.array(node), count)

        default:
            throw JsonSyntaxError.parser(.errorInvalidSyntax)
        }
    }

    /// First token MUST be `.syntax(.openBrace)`.
    func parseObject(_ tokens: ArraySlice<Token>) throws -> (ParseTree.Obj, Int) {

        // tokens can't be empty, we already check on the caller side
        let first = tokens.first!

        guard let second = tokens.item(atAdjustedIndex: 1) else {
            throw JsonSyntaxError.parser(.errorInvalidSyntax)
        }

        guard second.kind != .syntax(.closeBrace) else { // `{}`
            return (
                ParseTree.Obj(
                    pos: .from(first.pos.start, to: second.pos.end),
                    pairs: [],
                    commas: []),
                2
            )
        }

        var mutTokens = tokens.dropFirst()
        var childPairs: [ParseTree.KeyValue] = []
        var commaPos: [Pos] = []
        var tokenCount: Int = 1

        while true {

            let (pairNode, parsedCount) = try parseKeyValuePair(mutTokens)
            childPairs.append(pairNode)
            mutTokens = mutTokens.dropFirst(parsedCount)
            tokenCount += parsedCount

            guard let nextToken = mutTokens.first else {
                throw JsonSyntaxError.parser("unexpected end of an object")
            }

            switch nextToken.kind {

            case .syntax(.closeBrace):
                let objNode = ParseTree.Obj(
                    pos: .from(first.pos.start, to: nextToken.pos.end),
                    pairs: childPairs,
                    commas: commaPos)

                return (objNode, tokenCount + 1)

            case .syntax(.comma):
                commaPos.append(nextToken.pos)
                mutTokens = mutTokens.dropFirst()
                tokenCount += 1

            default:
                throw JsonSyntaxError.parser("expecting `,` or `}` after key-value pair")
            }
        }
    }

    func parseKeyValuePair(
        _ tokens: ArraySlice<Token>
    ) throws -> (ParseTree.KeyValue, Int) {

        guard let keyToken = tokens.first else {
            throw JsonSyntaxError.parser("unexpected end of an object")
        }

        // parse string key
        guard case .string = keyToken.kind else {
            throw JsonSyntaxError.parser("expecting string key in object")
        }

        var mutTokens = tokens.dropFirst()

        // parse colon
        guard
            let colonToken = mutTokens.first,
            case .syntax(.colon) = colonToken.kind
        else {
            throw JsonSyntaxError.parser("expecting `:` after object key")
        }

        mutTokens = mutTokens.dropFirst()

        // parse value
        let (parsedValue, parsedCount) = try parseJsonValue(mutTokens)

        let pair = ParseTree.KeyValue(
            keyPos: keyToken.pos,
            value: parsedValue,
            colonPos: colonToken.pos)

        return (pair, parsedCount + 2)
    }

    /// First token MUST be `.syntax(.openBracket)`.
    func parseArray(_ tokens: ArraySlice<Token>) throws -> (ParseTree.Arr, Int) {

        // tokens can't be empty, we have check on the caller side
        let first = tokens.first!

        guard let second = tokens.item(atAdjustedIndex: 1) else {
            throw JsonSyntaxError.parser(.errorInvalidSyntax)
        }

        guard second.kind != .syntax(.closeBracket) else { // `[]`
            return (
                ParseTree.Arr(
                    pos: .from(first.pos.start, to: second.pos.end),
                    items: [],
                    commas: []),
                2)
        }

        var mutTokens = tokens.dropFirst()
        var childItems: [ParseTree] = []
        var commaPos: [Pos] = []
        var tokenCount: Int = 1

        while true {

            let (parsed, parsedCount) = try parseJsonValue(mutTokens)
            childItems.append(parsed)
            mutTokens = mutTokens.dropFirst(parsedCount)
            tokenCount += parsedCount

            // parse closing bracket or comma
            guard let nextToken = mutTokens.first else {
                throw JsonSyntaxError.parser("unexpected end of an array")
            }

            switch nextToken.kind {

            case .syntax(.closeBracket):
                let arrayNode = ParseTree.Arr(
                    pos: .from(first.pos.start, to: nextToken.pos.end),
                    items: childItems,
                    commas: commaPos)

                return (arrayNode, tokenCount + 1)

            case .syntax(.comma):
                commaPos.append(nextToken.pos)
                mutTokens = mutTokens.dropFirst()
                tokenCount += 1

            default:
                throw JsonSyntaxError.parser("expecting `,` or `]` after value in array")
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
            throw JsonSyntaxError.parser("Number token can't be empty string")
        }

        guard firstChar == "-" || firstChar.isJsonNumber else {
            throw JsonSyntaxError.parser("Number token should start with `-` or digit")
        }

        guard count > 1 else {
            guard firstChar.isJsonNumber else {
                throw JsonSyntaxError.parser("Only digits are valid chars for 1-length number")
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
                        throw JsonSyntaxError.parser("Leading zeros are not allowed")
                    }

                } else {
                    return // `-0` is valid number
                }
            }

        } else {
            if firstChar == "0" {
                guard secondChar.isDotOrExp else {
                    throw JsonSyntaxError.parser("Leading zeros are not allowed")
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
                throw JsonSyntaxError.parser("invalid number")
            }

            previousChar = char
        }

        guard last?.isJsonNumber == true else {
            throw JsonSyntaxError.parser("Unexpected end of number token")
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
