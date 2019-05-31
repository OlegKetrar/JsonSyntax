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

        let (parsed, rest) = try parseJsonValue(tokens)

        guard rest.isEmpty, !parsed.isEmpty else {
            throw Error.parser(.errorInvalidSyntax)
        }

        return parsed
    }
}

// MARK: - Private

private extension SyntaxParser {

    func parseJsonValue(_ tokens: [Token]) throws -> ([SyntaxToken], [Token]) {

        guard let token = tokens.first else {
            throw Error.parser(.errorInvalidSyntax)
        }

        switch token.kind {
        case let .number(valStr):
            return (
                [SyntaxToken(kind: try parseNumber(valStr), range: token.range)],
                Array(tokens.dropFirst()))

        case .string:
            return (
                [SyntaxToken(kind: .stringValue, range: token.range)],
                Array(tokens.dropFirst()))

        case let .literal(val):
            return (
                [SyntaxToken(kind: .literalValue(val), range: token.range)],
                Array(tokens.dropFirst()))

        default:
            break
        }

        if case let (.some(parsed), rest) = try parseArray(tokens) {
            return (parsed, rest)
        }

        if case let (.some(parsed), rest) = try parseObject(tokens) {
            return (parsed, rest)
        }

        throw Error.parser(.errorInvalidSyntax)
    }

    func parseObject(_ tokens: [Token]) throws -> ([SyntaxToken]?, [Token]) {

        // tokens can't be empty, we already check on the caller side
        guard let first = tokens.first,
            first.kind == .syntax(.openBrace) else { return (nil, tokens) }

        guard tokens.indices.contains(1) else {
            throw Error.parser(.errorInvalidSyntax)
        }

        let second = tokens[1]

        guard second.kind != .syntax(.closeBrace) else { // `{}`
            let objTokens = [
                SyntaxToken(kind: .syntax(.openBrace), range: first.range),
                SyntaxToken(kind: .syntax(.closeBrace), range: second.range)
            ]

            return (objTokens, Array(tokens.dropFirst(2)))
        }

        var mutTokens = Array(tokens.dropFirst())
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
                _ = mutTokens.removeFirst()

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

            _ = mutTokens.removeFirst()

            // parse value
            let (parsedValue, rest) = try parseJsonValue(mutTokens)
            syntaxTokens.append(contentsOf: parsedValue)
            mutTokens = rest

            // parse closing brace or comma
            guard let nextToken = mutTokens.first else {
                throw Error.parser("unexpected end of an object")
            }

            switch nextToken.kind {

            case .syntax(.closeBrace):
                syntaxTokens.append(SyntaxToken(
                    kind: .syntax(.closeBrace),
                    range: nextToken.range))

                _ = mutTokens.removeFirst()

                return (syntaxTokens, mutTokens)

            case .syntax(.comma):
                syntaxTokens.append(SyntaxToken(
                    kind: .syntax(.comma),
                    range: nextToken.range))

                _ = mutTokens.removeFirst()

            default:
                throw Error.parser("expecting `,` or `}` after key-value pair")
            }
        }
    }

    func parseArray(_ tokens: [Token]) throws -> ([SyntaxToken]?, [Token]) {

        // tokens can't be empty, we have check on the caller side
        guard let first = tokens.first,
            first.kind == .syntax(.openBracket) else { return (nil, tokens) }

        guard tokens.indices.contains(1) else {
            throw Error.parser(.errorInvalidSyntax)
        }

        let second = tokens[1]

        guard second.kind != .syntax(.closeBracket) else { // `[]`
            let arrayTokens = [
                SyntaxToken(kind: .syntax(.openBracket), range: first.range),
                SyntaxToken(kind: .syntax(.closeBracket), range: second.range)
            ]

            return (arrayTokens, Array(tokens.dropFirst(2)))
        }

        var mutTokens = Array(tokens.dropFirst())
        var syntaxTokens: [SyntaxToken] = [
            SyntaxToken(kind: .syntax(.openBracket), range: first.range)
        ]

        while true {

            let (parsedValue, rest) = try parseJsonValue(mutTokens)
            syntaxTokens.append(contentsOf: parsedValue)
            mutTokens = rest

            // parse closing bracket or comma
            guard let nextToken = mutTokens.first else {
                throw Error.parser("unexpected end of an array")
            }

            switch nextToken.kind {

            case .syntax(.closeBracket):
                syntaxTokens.append(SyntaxToken(
                    kind: .syntax(.closeBracket),
                    range: nextToken.range))

                _ = mutTokens.removeFirst()

                return (syntaxTokens, mutTokens)

            case .syntax(.comma):
                syntaxTokens.append(SyntaxToken(
                    kind: .syntax(.comma),
                    range: nextToken.range))

                _ = mutTokens.removeFirst()

            default:
                throw Error.parser("expecting `,` or `]` after value in array")
            }
        }
    }

    func parseNumber(_ str: String) throws -> SyntaxToken.Kind {

        guard str.isValidJsonNumber else {
            throw Error.parser(.errorInvalidSyntax)
        }

        return .numberValue
    }
}

// MARK: - Convenience

private extension String {

    static var errorInvalidSyntax: String {
        return "invalid syntax"
    }

    var isValidJsonNumber: Bool {
        guard let firstChar = first,
            firstChar == "-" || firstChar.isJsonNumber else { return false }

        guard count > 1 else {
            // only digits are valid chars for 1-length number token
            return firstChar.isJsonNumber
        }

        let secondChar = self[index(after: startIndex)]

        // eliminate leading zero
        if firstChar == "-" {
            if secondChar == "0" {
                let thirdIndex = index(startIndex, offsetBy: 2)

                if indices.contains(thirdIndex) {
                    guard self[thirdIndex].isDotOrExp else { return false }
                } else {
                    return true // `-0` is valid number
                }
            }

        } else {
            if firstChar == "0" {
                guard secondChar.isDotOrExp else { return false }
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
                return false
            }

            previousChar = char
        }

        guard last!.isJsonNumber else { return false }
        return true
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
