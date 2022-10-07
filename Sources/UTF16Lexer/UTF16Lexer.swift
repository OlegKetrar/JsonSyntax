//
//  UTF16Lexer.swift
//  JsonSyntax
//
//  Created by Oleg Ketrar on 07.10.2022.
//  Copyright © 2022 Oleg Ketrar. All rights reserved.
//

struct UTF16Lexer {

    func lex(_ string: String) throws -> [Token] {

        var buffer = UTF16Iterator(string)
        var tokens: [Token] = []

        while buffer.hasMore {
            let index: Int = buffer.index

            if let length = try lexString(&buffer) {
                tokens.append(Token(kind: .string, pos: .from(index, length)))
                continue
            }

            if let (tokenKind, length) = lexLiteral(&buffer) {
                tokens.append(Token(kind: tokenKind, pos: .from(index, length)))
                continue
            }

            if let (tokenKind, length) = lexNumber(&buffer) {
                tokens.append(Token(kind: tokenKind, pos: .from(index, length)))
                continue
            }

            guard let char = buffer.consumeNext() else {
                fatalError()
            }

            if char.int8?.isWhitespace == true {
                continue
            } else if let syntaxChar = SyntaxCharacter(utf16Value: char) {
                tokens.append(Token(kind: .syntax(syntaxChar), pos: .one(index)))
            } else {
                // TODO: add line & index error payload
                throw JsonSyntaxError.lexer("unexpected character: \(char)")
            }
        }

        return tokens
    }
}

private extension UTF16Lexer {
    typealias LexingResult = (type: Token.Kind, length: Int)

    func lexString(_ buffer: inout UTF16Iterator) throws -> Int? {
        let startIndex = buffer.index

        guard
            let firstChar = buffer.getCurrent(),
            firstChar.int8 == .quote
        else { return nil }

        buffer.dropNext()

        while let char = buffer.consumeNext() {
            guard char > 0 else {
                throw JsonSyntaxError.lexer("Non-ASCII characters should be escaped")
            }

            if char.int8 == .quote {
                return buffer.index - startIndex
            }

            if char.int8 == .backslash {
                try lexEscapeSequence(&buffer)
            }
        }

        throw JsonSyntaxError.lexer("Expected end-of-string quote")
    }

    func lexEscapeSequence(_ buffer: inout UTF16Iterator) throws {
        switch buffer.consumeNext() {

        case .some(0x75): // u
            try lexUnicodeSequence(&buffer)

        case let .some(char) where char.int8?.isEscapedCharacter == true:
            break

        case let .some(char):
            throw JsonSyntaxError.lexer("Unexpected escaped character \(char)")

        case .none:
            throw JsonSyntaxError.lexer("Expected escaped character")
        }
    }

    func lexUnicodeSequence(_ buffer: inout UTF16Iterator) throws {
        let codeUnit = try lexUnicodeCodeUnit(&buffer)

        let isLeadSurrogate = UTF16.isLeadSurrogate(codeUnit)
        let isTrailSurrogate = UTF16.isTrailSurrogate(codeUnit)

        switch (isLeadSurrogate, isTrailSurrogate) {
        case (false, false):
            // The code units that are neither lead surrogates nor trail surrogates
            // form valid unicode scalars.
            return

        case (true, false):
            guard buffer.consumePrefix(#"\u"#) else {
                throw JsonSyntaxError.lexer("Invalid unicode literal sequence")
            }

            let trailCodeUnit = try lexUnicodeCodeUnit(&buffer)

            guard UTF16.isTrailSurrogate(trailCodeUnit) else {
                throw JsonSyntaxError.lexer("Invalid unicode literal sequence")
            }

        case (false, true), (true, true):
            // Surrogates must always come in pairs.
            // trail surrogate must come after lead surrogate
            throw JsonSyntaxError.lexer("Invalid unicode literal sequence")
        }
    }

    func lexUnicodeCodeUnit(_ buffer: inout UTF16Iterator) throws -> UTF16.CodeUnit {

        let hexChars: [Character] = try (0..<4).map { _ in
            guard let char = buffer.consumeNext() else {
                throw JsonSyntaxError.lexer("Unexpected end of unicode literal")
            }

            guard char.int8?.isHexDigit == true else {
                throw JsonSyntaxError.lexer("Unexpected character \(char)")
            }

            if let character = char.character {
                return character
            } else {
                throw JsonSyntaxError.lexer("Unexpected character \(char)")
            }
        }

        guard let codeUnit = UInt16(String(hexChars), radix: 16) else {
            throw JsonSyntaxError.lexer("Invalid unicode sequence")
        }

        return codeUnit
    }

    func lexLiteral(_ chars: inout UTF16Iterator) -> LexingResult? {

        switch true {
        case chars.consumePrefix(Literal.true.rawValue):
            return (.literal(.true), 4)

        case chars.consumePrefix(Literal.false.rawValue):
            return (.literal(.false), 5)

        case chars.consumePrefix(Literal.null.rawValue):
            return (.literal(.null), 4)

        default:
            return nil
        }
    }

    func lexNumber(_ buffer: inout UTF16Iterator) -> LexingResult? {
        var jsonNumber = ""
        var length: Int = 0

        while let char = buffer.getCurrent() {
            guard
                char.int8?.isNumber == true,
                let character = char.character
            else { break }

            buffer.dropNext()
            jsonNumber.append(character)
            length += 1
        }

        if length > 0 {
            return (.number(jsonNumber), length)
        } else {
            return nil
        }
    }
}
