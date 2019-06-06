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

                let tokenEndIndex = string.index(after: index)

                tokens.append(Token(
                    kind:
                    .syntax(syntaxChar),
                    range: index..<tokenEndIndex))

                index = tokenEndIndex

            } else {
                throw Error.lexer("unexpected character: \(string[index])")
            }
        }

        return tokens
    }
}

// MARK: - Private

private extension Lexer {
    typealias LexingResult = (type: Token.Kind, length: Int)

    func lexString(_ str: String, location: String.Index) throws -> LexingResult? {
        guard str[location].isJsonQuote else { return nil }

        var length: Int = 2
        var jsonStr: String = ""
        var indexOrNil = str.safeIndex(after: location)

        while true {
            guard let index = indexOrNil,
                index < str.endIndex else { break }

            let char = str[index]

            if char.isJsonQuote {
                return (.string(jsonStr), length)
            } else if char == #"\"# {

                guard
                    let nextIndex = str.safeIndex(after: index),
                    nextIndex < str.endIndex
                else {
                    throw Error.lexer("Expected escaped character")
                }

                let nextChar = str[nextIndex]

                if let escaped = nextChar.getEscapedCharacter() {
                    jsonStr.append(escaped)
                    length += 2

                    indexOrNil = str.safeIndex(after: nextIndex)

                } else if nextChar == "u" {

                    guard
                        let unicodeLastIndex = str.safeIndex(after: nextIndex, offsetBy: 4),
                        unicodeLastIndex < str.endIndex
                    else {
                        throw Error.lexer("Unexpected end of unicode literal")
                    }

                    let unicodeCodeStr = str[str.index(after: nextIndex)...unicodeLastIndex]

                    guard
                        let hexCode = UInt32(unicodeCodeStr, radix: 16),
                        let scalar = Unicode.Scalar(hexCode)
                    else {
                        throw Error.lexer("Invalid unicode sequence")
                    }

                    jsonStr.append(Character(scalar))
                    length += 6 // \uXXXX

                    indexOrNil = str.safeIndex(after: unicodeLastIndex)

                } else {
                    throw Error.lexer("Unexpected escaped character \(nextChar)")
                }

            } else {
                jsonStr.append(char)
                length += 1

                indexOrNil = str.safeIndex(after: index)
            }
        }

        throw Error.lexer("Expected end-of-string quote")
    }

    func lexLiteral(_ str: String, location: String.Index) throws -> LexingResult? {
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

    func lexNumber(_ str: String, location: String.Index) throws -> LexingResult? {
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
        let whitespace: [Character] = [" ", "\t", "\n", "\r"]
        return whitespace.contains(self)
    }

    var isJsonQuote: Bool {
        return self == "\""
    }

    func getEscapedCharacter() -> Character? {

        switch self {
        case "\"": return "\""
        case "\\": return "\\"
        case "n": return "\n"
        case "r": return "\r"
        case "t": return "\t"
        case "/": return "/"

        case "b": return Character(Unicode.Scalar(0x0008 as UInt8))
        case "f": return Character(Unicode.Scalar(0x000C as UInt8))
        default:
            return nil
        }
    }
}

private extension String {

    func safeIndex(
        after index: String.Index,
        offsetBy offset: UInt = 1) -> String.Index? {

        var mutIndex = index

        for _ in 0..<offset {
            guard mutIndex < endIndex else { return nil }

            formIndex(after: &mutIndex)
        }

        return mutIndex
    }
}
