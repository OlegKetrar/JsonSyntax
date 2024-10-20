//
//  Lexer.swift
//  JsonSyntax
//
//  Created by Oleg Ketrar on 17/05/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

#warning("Add line index to Pos")

struct Lexer {

    func lex(_ string: String) throws -> [Token] {

        var buffer = CCharIterator(string)
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

            if char.isWhitespace {
                continue
            } else if let syntaxChar = SyntaxCharacter(rawValue: char) {
                tokens.append(Token(kind: .syntax(syntaxChar), pos: .one(index)))
            } else {
                // TODO: add line & index error payload
                throw JsonSyntaxError.lexer("unexpected character: \(char.character)")
            }
        }

        return tokens
    }
}

// MARK: - Private

private extension Lexer {
    typealias LexingResult = (type: Token.Kind, length: Int)

    func lexString(_ buffer: inout CCharIterator) throws -> Int? {
        let startIndex = buffer.index

        guard buffer.getCurrent() == .quote else { return nil }

        buffer.dropNext()

        while let char = buffer.consumeNext() {
            guard char > 0 else {
                throw JsonSyntaxError.lexer("Non-ASCII characters should be escaped")
            }

            if char == .quote {
                return buffer.index - startIndex
            }

            if char == .backslash {
                try lexEscapeSequence(&buffer)
            }
        }

        throw JsonSyntaxError.lexer("Expected end-of-string quote")
    }

    func lexEscapeSequence(_ buffer: inout CCharIterator) throws {
        switch buffer.consumeNext() {

        case .some(0x75):
            try lexUnicodeSequence(&buffer)

        case let .some(char) where char.isEscapedCharacter:
            break

        case let .some(char):
            throw JsonSyntaxError.lexer("Unexpected escaped character \(char.character)")

        case .none:
            throw JsonSyntaxError.lexer("Expected escaped character")
        }
    }

    func lexUnicodeSequence(_ buffer: inout CCharIterator) throws {
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

    func lexUnicodeCodeUnit(_ buffer: inout CCharIterator) throws -> UTF16.CodeUnit {

        let hexChars: [Character] = try (0..<4).map { _ in
            guard let char = buffer.consumeNext() else {
                throw JsonSyntaxError.lexer("Unexpected end of unicode literal")
            }

            guard char.isHexDigit else {
                throw JsonSyntaxError.lexer("Unexpected character \(char.character)")
            }

            return char.character
        }

        guard let codeUnit = UInt16(String(hexChars), radix: 16) else {
            throw JsonSyntaxError.lexer("Invalid unicode sequence")
        }

        return codeUnit
    }

    func lexLiteral(_ chars: inout CCharIterator) -> LexingResult? {

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

    func lexNumber(_ buffer: inout CCharIterator) -> LexingResult? {
        var jsonNumber = ""
        var length: Int = 0

        while let char = buffer.getCurrent() {
            guard char.isNumber else { break }

            buffer.dropNext()
            jsonNumber.append(char.character)
            length += 1
        }

        if length > 0 {
            return (.number(jsonNumber), length)
        } else {
            return nil
        }
    }
}
