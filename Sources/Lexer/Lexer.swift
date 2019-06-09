//
//  Lexer.swift
//  JsonSyntax
//
//  Created by Oleg Ketrar on 17/05/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

#warning("Add line index to Pos")
#warning("implement char generator")
#warning("fix parsing of unicode scalars")

struct Lexer {

    func lex(_ string: String) throws -> [Token] {
        guard !string.isEmpty else { return [] }

        let chars = string.utf8CString
        var index: Int = 0
        var tokens: [Token] = []

        while index < chars.endIndex - 1 { // last item is 0x00
            let slice = chars[index...]

            if let length = try lexString(slice) {
                tokens.append(Token(kind: .string, pos: .from(index, length)))
                index += length
                continue
            }

            if let (tokenKind, length) = try lexLiteral(slice) {
                tokens.append(Token(kind: tokenKind, pos: .from(index, length)))
                index += length
                continue
            }

            if let (tokenKind, length) = try lexNumber(slice) {
                tokens.append(Token(kind: tokenKind, pos: .from(index, length)))
                index += length
                continue
            }

            if chars[index].isWhitespace {
                index += 1

            } else if let syntaxChar = SyntaxCharacter(rawValue: chars[index]) {
                tokens.append(Token(kind: .syntax(syntaxChar), pos: .one(index)))
                index += 1

            } else {
                throw Error.lexer("unexpected character: \(chars[index].character)")
            }
        }

        return tokens
    }
}

// MARK: - Private

private extension Lexer {
    typealias LexingResult = (type: Token.Kind, length: Int)

    func lexString(_ chars: ArraySlice<CChar>) throws -> Int? {
        guard chars.first == .some(.quote) else { return nil }

        var chars = chars.dropFirst()
        var length: Int = 2

        while let char = chars.first {
            guard char > 0 else {
                throw Error.lexer("Non-ASCII characters should be escaped")
            }

            switch char {
            case .quote:
                return length

            case .backslash:
                chars.ignoreFirst()

                guard let nextChar = chars.first else {
                    throw Error.lexer("Expected escaped character")
                }

                if nextChar.isEscapedCharacter {
                    length += 2
                    chars.ignoreFirst()

                // parse unicode literal
                } else if nextChar == 0x75 {
                    chars.ignoreFirst()
                    try validateUnicodeSequence(chars.prefix(4))

                    length += 6
                    chars.ignoreFirst(4)

                } else {
                    throw Error.lexer("Unexpected escaped character \(nextChar.character)")
                }

            default:
                length += 1
                chars.ignoreFirst()
            }
        }

        throw Error.lexer("Expected end-of-string quote")
    }

    func validateUnicodeSequence(_ hexChars: ArraySlice<CChar>) throws {
        guard hexChars.count == 4 else {
            throw Error.lexer("Unexpected end of unicode literal")
        }

        guard
            hexChars.allSatisfy({ $0.isHexDigit }),
            let codeUnit = UInt16(String(hexChars.map { $0.character }), radix: 16)
        else {
            throw Error.lexer("Invalid unicode sequence")
        }

        _ = codeUnit

        let isLeadSurrogate = UTF16.isLeadSurrogate(codeUnit)
        let isTrailSurrogate = UTF16.isTrailSurrogate(codeUnit)

        guard isLeadSurrogate || isTrailSurrogate else {
            // The code units that are neither lead surrogates nor trail surrogates
            // form valid unicode scalars.
            return
        }

        throw Error.lexer("Unicode surrogates not supported yet")

/*
        // Surrogates must always come in pairs.

        guard isLeadSurrogate else {
            // trail surrogate must come after lead surrogate
            throw Error.lexer("Invalid unicode literal sequence")
        }

        // parse \u and 4 hex
        // if next.isTrailSurrogate -> OK
        // else -> error
*/
//        guard let (trailCodeUnit, finalIndex) = try consumeASCIISequence("\\u", input: index).flatMap(parseCodeUnit),
//            UTF16.isTrailSurrogate(trailCodeUnit)
//        else {
//            throw Error.lexer("Invalid unicode literal sequence")
//        }

        // if next sequence is "\\u" &&

//        func consumeASCIISequence(_ sequence: String, input: Index) throws -> Index? {
//            var index = input
//            for scalar in sequence.unicodeScalars {
//                guard let nextIndex = try consumeASCII(UInt8(scalar.value))(index) else {
//                    return nil
//                }
//                index = nextIndex
//            }
//            return index
//        }

//        return (String(UTF16.decode(UTF16.EncodedScalar([codeUnit, trailCodeUnit]))), finalIndex)
    }

//    func consumeASCII(_ ascii: UInt8) -> (Index) throws -> Index? {
//        return { (input: Index) throws -> Index? in
//
//            switch self.source.takeASCII(input) {
//            case nil:
//                throw Error.lexer("Unexpected end of file during JSON parse")
//
//            case let (taken, index)? where taken == ascii:
//                return index
//
//            default:
//                return nil
//            }
//        }
//    }

    func lexLiteral(_ chars: ArraySlice<CChar>) throws -> LexingResult? {

        switch true {
        case chars.hasPrefix(Literal.trueChars):
            return (.literal(.true), 4) // "true".count
        case chars.hasPrefix(Literal.falseChars):
            return (.literal(.false), 5) // "false".count
        case chars.hasPrefix(Literal.nullChars):
            return (.literal(.null), 4) // "null".count
        default:
            return nil
        }
    }

    func lexNumber(_ chars: ArraySlice<CChar>) throws -> LexingResult? {
        var jsonNumber = ""
        var length: Int = 0

        for char in chars {
            guard char.isNumber else { break }

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

private extension Literal {

    static var trueChars: [CChar] {
        return [0x74, 0x72, 0x75, 0x65]
    }

    static var falseChars: [CChar] {
        return [0x66, 0x61, 0x6C, 0x73, 0x65]
    }

    static var nullChars: [CChar] {
        return [0x6E, 0x75, 0x6C, 0x6C]
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

private extension ArraySlice where Element == CChar {

    func hasPrefix(_ prefix: [CChar]) -> Bool {
        for (index, char) in prefix.enumerated() {
            guard item(atAdjustedIndex: index) == char else { return false }
        }

        return true
    }

    mutating func ignoreFirst(_ k: Int = 1) {
        self = dropFirst(k)
    }
}
