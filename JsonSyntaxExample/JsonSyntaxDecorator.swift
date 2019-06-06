//
//  JsonSyntaxDecorator.swift
//  JsonSyntaxExample
//
//  Created by Oleg Ketrar on 29/05/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

import UIKit
import JsonSyntax

struct JsonSyntaxDecorator: CodeSyntaxHighlighter {

    private struct Palette {
        static let keysColor: UIColor = #colorLiteral(red: 0.6499369144, green: 0.8942017555, blue: 0, alpha: 1)
        static let stringColor: UIColor = #colorLiteral(red: 0.9018524885, green: 0.8639326096, blue: 0.4221951067, alpha: 1)
        static let numbersColor: UIColor = #colorLiteral(red: 0.682919085, green: 0.4891806841, blue: 1, alpha: 1)
    }

    func decorate(
        code: NSMutableAttributedString,
        with theme: CodeTheme) -> NSAttributedString {

        let jsonStr = code.string
        let tokens: [HighlightToken]

        do {
            tokens = try JsonSyntax().parse(jsonStr)
        } catch {
            tokens = []
            print("invalid JSON")
        }

        code.append(
            to: jsonStr.startIndex..<jsonStr.endIndex,
            attributes: [ .font : theme.mainFont ])

        tokens.forEach { token in

            switch token.kind {

            case .syntax(.openBracket),
                 .syntax(.closeBracket),
                 .syntax(.openBrace),
                 .syntax(.closeBrace):

                code.append(to: token.range, attributes: [
                    .foregroundColor : UIColor.white
                ])

            case .syntax(.colon), .syntax(.comma):
                code.append(to: token.range, attributes: [
                    .foregroundColor : UIColor.white
                ])

            case .literalValue:
                code.append(to: token.range, attributes: [
                    .foregroundColor : Palette.numbersColor
                ])

            case .numberValue:
                code.append(to: token.range, attributes: [
                    .foregroundColor : Palette.numbersColor
                ])

            case .stringValue:
                code.append(to: token.range, attributes: [
                    .foregroundColor : Palette.stringColor
                ])

            case .key:
                code.append(to: token.range, attributes: [
                    .foregroundColor : Palette.keysColor
                ])
            }
        }

        return code
    }
}

private extension NSMutableAttributedString {

    func append(
        to range: Range<String.Index>,
        attributes: [NSAttributedString.Key : Any]) {

        let nsRange = NSRange(range, in: string)
        addAttributes(attributes, range: nsRange)
    }
}
