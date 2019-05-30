//
//  Lexer.swift
//  JsonSyntax
//
//  Created by Oleg Ketrar on 17/05/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

struct Lexer {

    func lex(_ string: String) throws -> [Token] {
        guard !string.isEmpty else { return [] }

        var index: String.Index = string.startIndex
        var tokens: [Token] = []

        while index < string.endIndex {

            if let (tokenKind, length) = try lexString(string, location: index) {
                let endIndex = string.index(index, offsetBy: length)
                tokens.append(Token(kind: tokenKind, range: index..<endIndex))

                index = endIndex
                continue
            }

            if let (tokenKind, length) = try lexLiteral(string, location: index) {
                let endIndex = string.index(index, offsetBy: length)
                tokens.append(Token(kind: tokenKind, range: index..<endIndex))

                index = endIndex
                continue
            }

            if let (tokenKind, length) = try lexNumber(string, location: index) {
                let endIndex = string.index(index, offsetBy: length)
                tokens.append(Token(kind: tokenKind, range: index..<endIndex))

                index = endIndex
                continue
            }

            if string[index].isJsonWhitespace {
                index = string.index(after: index)

            } else if let syntaxChar = SyntaxCharacter(rawValue: string[index]) {

                tokens.append(Token(
                    kind:
                    .syntax(syntaxChar),
                    range: index..<string.index(after: index)))

                index = string.index(after: index)

            } else {
                throw Error.lexer("unexpected character: \(string[index])")
            }
        }

        return tokens
    }
}

// MARK: - Private

private extension Lexer {
    typealias PartialToken = (type: Token.Kind, length: Int)

    func lexString(_ str: String, location: String.Index) throws -> PartialToken? {
        guard str[location].isJsonQuote else { return nil }

        var length: Int = 2
        var jsonStr: String = ""
        var index: String.Index = str.index(after: location)

        while true {
            guard index <= str.endIndex else { break }

            let char = str[index]

            if char.isJsonQuote {
                return (.string(jsonStr), length)
            } else {
                jsonStr.append(char)
                length += 1

                index = str.index(after: index)
            }
        }

        throw Error.lexer("Expected end-of-string quote")
    }

    func lexLiteral(_ str: String, location: String.Index) throws -> PartialToken? {
        let subStr = str[location...]

        switch true {

        case subStr.hasPrefix(Literal.true.rawValue):
            return (.literal(.true), 4) // "true".count
        case subStr.hasPrefix(Literal.false.rawValue):
            return (.literal(.false), 5) // "false".count
        case subStr.hasPrefix(Literal.null.rawValue):
            return (.literal(.null), 4) // "null".count
        default:
            return nil
        }
    }

    func lexNumber(_ str: String, location: String.Index) throws -> PartialToken? {
        let digitChars = (0...9).map { Character("\($0)") }
        let allowedChars = digitChars + [".", "e", "E", "-", "+"]

        var jsonNumber = ""
        var length: Int = 0

        for char in str[location...] {
            guard allowedChars.contains(char) else { break }

            jsonNumber.append(char)
            length += 1
        }

        if jsonNumber.isEmpty {
            return nil
        } else {
            return (.number(jsonNumber), length)
        }
    }
}

// MARK: - Convenience

private extension Character {

    var isJsonWhitespace: Bool {
        let whitespace: [Character] = [ " ", "\t", "\n", "\r" ]
        return whitespace.contains(self)
    }

    var isJsonQuote: Bool {
        return self == "\""
    }
}
