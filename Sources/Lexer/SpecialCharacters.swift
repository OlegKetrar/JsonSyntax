//
//  SpecialCharacters.swift
//  JsonSyntax
//
//  Created by Oleg Ketrar on 07.10.2022.
//

extension CChar {
    static let quote: CChar = 0x22
    static let space: CChar = 0x20
    static let backslash: CChar = 0x5C

    var isWhitespace: Bool {
        return self == 0x20 // space
            || self == 0x9 // tab
            || self == 0xA // newline
            || self == 0xD // carriage return
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
            || self == 0x6E // \n
            || self == 0x72 // \r
            || self == 0x74 // \t
            || self == 0x2F // //
            || self == 0x62 // \b
            || self == 0x66 // \f
    }

    var character: Character {
        Character(Unicode.Scalar(UInt8(bitPattern: self)))
    }
}

extension SyntaxCharacter {

    init?(utf16Value: UInt16) {
        if let ascii = utf16Value.int8 {
            self.init(rawValue: ascii)
        } else {
            return nil
        }
    }

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

extension UInt16 {

    var int8: Int8? {
        if self <= Int8.max {
            return Int8(self)
        } else {
            return nil
        }
    }

    var character: Character? {
        if let scalar = Unicode.Scalar(self) {
            return Character(scalar)
        } else {
            return nil
        }
    }
}
