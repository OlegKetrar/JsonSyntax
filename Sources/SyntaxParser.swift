//
//  SyntaxParser.swift
//  JsonSyntax
//
//  Created by Oleg Ketrar on 17/05/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

struct SyntaxParser {

    func parse(_ tokens: [Token]) throws -> [SyntaxToken] {

        guard !tokens.isEmpty else {
            throw Error.parser("no tokens available")
        }

        let (parsed, parsedTokensCount) = try parseJsonValue(tokens[...])

        guard !parsed.isEmpty, parsedTokensCount == tokens.count else {
            throw Error.parser(.errorInvalidSyntax)
        }

        return parsed
    }
}

// MARK: - Private

private extension SyntaxParser {

    /// [SyntaxToken] can't be empty array.
    typealias PartialToken = ([SyntaxToken], Int)

    func parseJsonValue(_ tokens: ArraySlice<Token>) throws -> PartialToken {

        guard let token = tokens.first else {
            throw Error.parser(.errorInvalidSyntax)
        }

        switch token.kind {
        case let .number(valStr):
            return (
                [SyntaxToken(kind: try parseNumber(valStr), range: token.range)],
                1)

        case .string:
            return (
                [SyntaxToken(kind: .stringValue, range: token.range)],
                1)

        case let .literal(val):
            return (
                [SyntaxToken(kind: .literalValue(val), range: token.range)],
                1)

        case .syntax(.openBrace):
            return try parseObject(tokens)

        case .syntax(.openBracket):
            return try parseArray(tokens)

        default:
            throw Error.parser(.errorInvalidSyntax)
        }
    }

    /// First token MUST be `.syntax(.openBrace)`.
    func parseObject(_ tokens: ArraySlice<Token>) throws -> PartialToken {

        // tokens can't be empty, we already check on the caller side
        let first = tokens.first!

        guard let second = tokens.item(atAdjustedIndex: 1) else {
            throw Error.parser(.errorInvalidSyntax)
        }

        guard second.kind != .syntax(.closeBrace) else { // `{}`
            let objTokens = [
                SyntaxToken(kind: .syntax(.openBrace), range: first.range),
                SyntaxToken(kind: .syntax(.closeBrace), range: second.range)
            ]

            return (objTokens, 2)
        }

        var mutTokens = tokens.dropFirst()
        var syntaxTokens = [
            SyntaxToken(kind: .syntax(.openBrace), range: first.range)
        ]

        while true {
            guard let keyToken = mutTokens.first else {
                throw Error.parser(.errorInvalidSyntax)
            }

            // parse string key
            if case let .string(keyName) = keyToken.kind {
                guard !keyName.isEmpty else {
                    throw Error.parser("object key can't be empty string")
                }

                syntaxTokens.append(SyntaxToken(kind: .key, range: keyToken.range))
                mutTokens = mutTokens.dropFirst()

            } else {
                throw Error.parser("expecting string key in object")
            }

            // parse colon
            guard
                let colonToken = mutTokens.first,
                case .syntax(.colon) = colonToken.kind
            else {
                throw Error.parser("expecting `:` after object key")
            }

            syntaxTokens.append(SyntaxToken(
                kind: .syntax(.colon),
                range: colonToken.range))

            mutTokens = mutTokens.dropFirst()

            // parse value
            let (parsedValue, parsedCount) = try parseJsonValue(mutTokens)
            syntaxTokens.append(contentsOf: parsedValue)
            mutTokens = mutTokens.dropFirst(parsedCount)

            // parse closing brace or comma
            guard let nextToken = mutTokens.first else {
                throw Error.parser("unexpected end of an object")
            }

            switch nextToken.kind {

            case .syntax(.closeBrace):
                syntaxTokens.append(SyntaxToken(
                    kind: .syntax(.closeBrace),
                    range: nextToken.range))

                mutTokens = mutTokens.dropFirst()

                return (syntaxTokens, syntaxTokens.count)

            case .syntax(.comma):
                syntaxTokens.append(SyntaxToken(
                    kind: .syntax(.comma),
                    range: nextToken.range))

                mutTokens = mutTokens.dropFirst()

            default:
                throw Error.parser("expecting `,` or `}` after key-value pair")
            }
        }
    }

    /// First token MUST be `.syntax(.openBracket)`.
    func parseArray(_ tokens: ArraySlice<Token>) throws -> PartialToken {

        // tokens can't be empty, we have check on the caller side
        let first = tokens.first!

        guard let second = tokens.item(atAdjustedIndex: 1) else {
            throw Error.parser(.errorInvalidSyntax)
        }

        guard second.kind != .syntax(.closeBracket) else { // `[]`
            let arrayTokens = [
                SyntaxToken(kind: .syntax(.openBracket), range: first.range),
                SyntaxToken(kind: .syntax(.closeBracket), range: second.range)
            ]

            return (arrayTokens, 2)
        }

        var mutTokens = tokens.dropFirst()
        var syntaxTokens: [SyntaxToken] = [
            SyntaxToken(kind: .syntax(.openBracket), range: first.range)
        ]

        while true {

            let (parsedValue, parsedCount) = try parseJsonValue(mutTokens)
            syntaxTokens.append(contentsOf: parsedValue)
            mutTokens = mutTokens.dropFirst(parsedCount)

            // parse closing bracket or comma
            guard let nextToken = mutTokens.first else {
                throw Error.parser("unexpected end of an array")
            }

            switch nextToken.kind {

            case .syntax(.closeBracket):
                syntaxTokens.append(SyntaxToken(
                    kind: .syntax(.closeBracket),
                    range: nextToken.range))

                mutTokens = mutTokens.dropFirst()

                return (syntaxTokens, syntaxTokens.count)

            case .syntax(.comma):
                syntaxTokens.append(SyntaxToken(
                    kind: .syntax(.comma),
                    range: nextToken.range))

                mutTokens = mutTokens.dropFirst()

            default:
                throw Error.parser("expecting `,` or `]` after value in array")
            }
        }
    }

    func parseNumber(_ str: String) throws -> SyntaxToken.Kind {
        try str.validateNumber()
        return .numberValue
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
