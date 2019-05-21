//
//  Lexer.swift
//  JsonSyntax
//
//  Created by Oleg Ketrar on 17/05/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

struct Lexer {

    func lex(_ string: String) throws -> [Token] {
        var mutStr = string
        var tokens: [Token] = []

        while mutStr.count > 0 {

            let (jsonString, rest1) = try lexString(mutStr)
            mutStr = rest1
            if let strToken = jsonString {
                tokens.append(strToken)
                continue
            }

            let (jsonNumber, rest2) = try lexNumber(mutStr)
            mutStr = rest2
            if let numberToken = jsonNumber {
                tokens.append(numberToken)
                continue
            }

            let (jsonBool, rest3) = try lexBool(mutStr)
            mutStr = rest3
            if let boolToken = jsonBool {
                tokens.append(boolToken)
                continue
            }

            let (jsonNull, rest4) = try lexNull(mutStr)
            mutStr = rest4
            if let nullToken = jsonNull {
                tokens.append(nullToken)
                continue
            }

            guard let char = mutStr.first else { break }

            if char.isJsonWhitespace {
                // ignore whitespace
                _ = mutStr.removeFirst()

            } else if let syntaxChar = char.jsonSyntax {
                tokens.append(.syntax(syntaxChar))
                _ = mutStr.removeFirst()

            } else {
                throw Error.lexer("unexpected character: \(char)")
            }
        }

        return tokens
    }
}

// MARK: - Private

private extension Lexer {

     func lexString(_ str: String) throws -> (Token?, String) {
        var mutStr = str
        var jsonStr = ""

        guard let firstChar = mutStr.first,
            firstChar.isJsonQuote else { return (nil, str) }

        _ = mutStr.removeFirst()

        for char in mutStr {

            if char.isJsonQuote {
                // we need shift index by +1 because
                // `jsonStr` don't have `"` at the begining, but `str` have
                let nextAfterClosingQuote = str.index(jsonStr.endIndex, offsetBy: 2)
                return (.string(jsonStr), String( str[nextAfterClosingQuote...] ))
            } else {
                jsonStr.append(char)
            }
        }

        throw Error.lexer("Excpected end-of-string quote")
    }

    func lexNumber(_ str: String) throws -> (Token?, String) {
        var jsonNumber = ""
        let numberChars: [String] = (0...9).map(String.init) + ["-", "e", "."]

        for char in str {
            let c = String(char)

            if numberChars.contains(c) {
                jsonNumber += c
            } else {
                break
            }
        }

        let rest = String( str[jsonNumber.endIndex...] )

        if jsonNumber.isEmpty {
            return (nil, str)

        } else if jsonNumber.contains(".") {
            guard let doubleNumber = Double( jsonNumber ) else { return (nil, str) }
            return (.double(doubleNumber), rest)

        } else {
            guard let intNumber = Int( jsonNumber ) else { return (nil, str) }
            return (.integer(intNumber), rest)
        }
    }

    func lexBool(_ str: String) throws -> (Token?, String) {
        if str.hasPrefix(Token.Literal.true.rawValue) {
            return (
                .literal(.true),
                String(str[Token.Literal.true.rawValue.endIndex...]))

        } else if str.hasPrefix(Token.Literal.false.rawValue) {
            return (
                .literal(.false),
                String(str[Token.Literal.false.rawValue.endIndex...]))

        } else {
            return (nil, str)
        }
    }

    func lexNull(_ str: String) throws -> (Token?, String) {

        guard str.hasPrefix(Token.Literal.null.rawValue) else {
            return (nil, str)
        }

        return (
            .literal(.null),
            String(str[Token.Literal.null.rawValue.endIndex...]))
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

    var jsonSyntax: Token.Syntax? {
        return Token.Syntax(rawValue: self)
    }
}
