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
                throw Error.lexer("unexpected character: \(char.character)")
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

        guard let firstChar = buffer.getCurrent(),
            firstChar == .quote else { return nil }

        buffer.dropNext()

        while let char = buffer.consumeNext() {
            guard char > 0 else {
                throw Error.lexer("Non-ASCII characters should be escaped")
            }

            if char == .quote {
                return buffer.index - startIndex
            }

            if char == .backslash {
                try lexEscapeSequence(&buffer)
            }
        }

        throw Error.lexer("Expected end-of-string quote")
    }

    func lexEscapeSequence(_ buffer: inout CCharIterator) throws {
        switch buffer.consumeNext() {

        case .some(0x75):
            try lexUnicodeSequence(&buffer)

        case let .some(char) where char.isEscapedCharacter:
            break

        case let .some(char):
            throw Error.lexer("Unexpected escaped character \(char.character)")

        case .none:
            throw Error.lexer("Expected escaped character")
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
                throw Error.lexer("Invalid unicode literal sequence")
            }

            let trailCodeUnit = try lexUnicodeCodeUnit(&buffer)

            guard UTF16.isTrailSurrogate(trailCodeUnit) else {
                throw Error.lexer("Invalid unicode literal sequence")
            }

        case (false, true), (true, true):
            // Surrogates must always come in pairs.
            // trail surrogate must come after lead surrogate
            throw Error.lexer("Invalid unicode literal sequence")
        }
    }

    func lexUnicodeCodeUnit(_ buffer: inout CCharIterator) throws -> UTF16.CodeUnit {

        let hexChars: [Character] = try (0..<4).map { _ in
            guard let char = buffer.consumeNext() else {
                throw Error.lexer("Unexpected end of unicode literal")
            }

            guard char.isHexDigit else {
                throw Error.lexer("Unexpected character \(char.character)")
            }

            return char.character
        }

        guard let codeUnit = UInt16(String(hexChars), radix: 16) else {
            throw Error.lexer("Invalid unicode sequence")
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

// MARK: - Convenience

private extension CChar {
    static let quote: CChar = 0x22
    static let space: CChar = 0x20
    static let backslash: CChar = 0x5C

    var isWhitespace: Bool {
        return self == 0x20 // space
            || self == 0x9  // tab
            || self == 0xA  // newline
            || self == 0xD  // carriage return
    }

    var isDecDigit: Bool {
        return self >= 0x30 && self <= 0x39
    }

    var isHexDigit: Bool {
        return isDecDigit
            || (self >= 0x41 && self <= 0x46) // A-F
            || (self >= 0x61 && self <= 0x66) // a-f
    }

    var isNumber: Bool {
        return isDecDigit
            || self == 0x2E // .
            || self == 0x45 // E
            || self == 0x65 // e
            || self == 0x2D // -
            || self == 0x2B // +
    }

    var isEscapedCharacter: Bool {
        return self == .quote
            || self == .backslash
            || self == 0x6E //  \n
            || self == 0x72 //  \r
            || self == 0x74 //  \t
            || self == 0x2F //  //
            || self == 0x62 //  \b
            || self == 0x66 //  \f
    }

    var character: Character {
        return Character(Unicode.Scalar(UInt8(bitPattern: self)))
    }
}

private extension SyntaxCharacter {

    init?(rawValue value: Int8) {
        switch value {
        case 0x7B: self = .openBrace
        case 0x7D: self = .closeBrace
        case 0x5B: self = .openBracket
        case 0x5D: self = .closeBracket
        case 0x2C: self = .comma
        case 0x3A: self = .colon
        default:
            return nil
        }
    }
}
