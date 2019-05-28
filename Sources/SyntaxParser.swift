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

        guard
            case let (.some(parsed), rest) = try parseJsonValue(tokens),
            rest.isEmpty,
            !parsed.isEmpty
        else {
            throw Error.parser(.errorInvalidSyntax)
        }

        return parsed
    }
}

// MARK: - Private

private extension SyntaxParser {

    func parseJsonValue(_ tokens: [Token]) throws -> ([SyntaxToken]?, [Token]) {

        guard let token = tokens.first else {
            throw Error.parser(.errorInvalidSyntax)
        }

        switch token {
        case let .number(valStr):
            return ([ try parseNumber(valStr) ], Array(tokens.dropFirst()))

        case let .string(val):
            return ([.stringValue(val)], Array(tokens.dropFirst()))

        case .literal(.true), .literal(.false):
            return ([.boolValue], Array(tokens.dropFirst()))

        case .literal(.null):
            return ([.null], Array(tokens.dropFirst()))

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

        // tokens can't be empty, we have check on the caller side
        guard tokens[0] == .syntax(.leftBrace) else {
            return (nil, tokens)
        }

        guard let second = tokens.first else {
            throw Error.parser(.errorInvalidSyntax)
        }

        guard second != .syntax(.rightBrace) else { // `{}`
            return ([.braces, .braces], Array(tokens.dropFirst(2)))
        }

        var mutTokens = Array(tokens.dropFirst())
        var syntaxTokens: [SyntaxToken] = [.braces]

        while true {
            guard let keyToken = mutTokens.first else {
                throw Error.parser(.errorInvalidSyntax)
            }

            // parse string key
            if case let .string(keyName) = keyToken {
                syntaxTokens.append(.key(keyName))
                _ = mutTokens.removeFirst()

            } else {
                throw Error.parser("expecting string key in object")
            }

            // parse colon
            guard case .some(.syntax(.colon)) = mutTokens.first else {
                throw Error.parser("expecting `:` after object key")
            }

            syntaxTokens.append(.colon)
            _ = mutTokens.removeFirst()

            // parse value
            if case let (.some(parsedValue), rest) = try parseJsonValue(mutTokens) {
                syntaxTokens.append(contentsOf: parsedValue)
                mutTokens = rest
            } else {
                throw Error.parser("expecting value after `:`")
            }

            // parse closing brace or comma
            switch mutTokens.first {

            case .some(.syntax(.rightBrace)):
                syntaxTokens.append(.braces)
                _ = mutTokens.removeFirst()

                return (syntaxTokens, mutTokens)

            case .some(.syntax(.comma)):
                syntaxTokens.append(.comma)
                _ = mutTokens.removeFirst()

            default:
                throw Error.parser("expecting `,` or `}` after key-value pair")
            }
        }
    }

    func parseArray(_ tokens: [Token]) throws -> ([SyntaxToken]?, [Token]) {

        // tokens can't be empty, we have check on the caller side
        guard tokens[0] == .syntax(.leftBracket) else {
            return (nil, tokens)
        }

        guard let second = tokens.first else {
            throw Error.parser(.errorInvalidSyntax)
        }

        guard second != .syntax(.rightBracket) else { // `[]`
            return ([.brackets, .brackets], Array(tokens.dropFirst(2)))
        }

        var mutTokens = Array(tokens.dropFirst())
        var syntaxTokens: [SyntaxToken] = [.brackets]

        while true {

            if case let (.some(parsedValue), rest) = try parseJsonValue(mutTokens) {
                syntaxTokens.append(contentsOf: parsedValue)
                mutTokens = rest
            } else {
                // array can't be empty here
                throw Error.parser("expecting value in array")
            }

            // parse closing bracket or comma
            switch mutTokens.first {

            case .some(.syntax(.rightBracket)):
                syntaxTokens.append(.brackets)
                _ = mutTokens.removeFirst()

                return (syntaxTokens, mutTokens)

            case .some(.syntax(.comma)):
                syntaxTokens.append(.comma)
                _ = mutTokens.removeFirst()

            default:
                throw Error.parser("expecting `,` or `]` after value in array")
            }
        }
    }

    func parseNumber(_ str: String) throws -> SyntaxToken {

        guard str.isValidJsonNumber else {
            throw Error.parser(.errorInvalidSyntax)
        }

        if let val = Int(str) {
            return .integerValue(val)

        } else if let val = Double(str) {
            if let int = Int(exactly: val), val == Double(int) {
                return .integerValue(int)
            } else {
                return .doubleValue(val)
            }

        } else {
            throw Error.parser("parsed number too big")
        }
    }
}

// MARK: - Convenience

private extension String {

    static var errorInvalidSyntax: String {
        return "invalid syntax"
    }

    var isValidExponent: Bool {
        return false
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
                    return false
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
        return self == "." || self.isExp
    }

    var isExp: Bool {
        return self == "e" || self == "E"
    }

    var isSign: Bool {
        return self == "-" || self == "+"
    }
}
