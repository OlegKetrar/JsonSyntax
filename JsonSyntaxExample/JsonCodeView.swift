//
//  JsonCodeView.swift
//  JsonSyntaxExample
//
//  Created by Oleg Ketrar on 20/05/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

import Foundation
import UIKit

protocol CodeSyntaxHighlighter {
    func decorate(
        code: NSMutableAttributedString,
        with theme: CodeTheme) -> NSAttributedString
}

// MARK: -

struct CodeTheme {
    let textBgColor: UIColor
    let mainFont: UIFont
    let mainTextColor: UIColor
}

extension CodeTheme {

    static var `default`: CodeTheme {
        return .init(
            textBgColor: #colorLiteral(red: 0.1568444967, green: 0.1568739712, blue: 0.156840831, alpha: 1),
            mainFont: UIFont(name: "Menlo-Regular", size: 14)!,
            mainTextColor: #colorLiteral(red: 0.6499369144, green: 0.8942017555, blue: 0, alpha: 1))
    }
}

// MARK: -

final class CodeView: UIView {
    private var theme: CodeTheme = .default
    private var syntax: CodeSyntaxHighlighter = PlainTextDecorator()

    private let scrollView = UIScrollView(frame: .zero).with {
        $0.backgroundColor = .clear
        $0.indicatorStyle = .white
        $0.alwaysBounceHorizontal = true
        $0.alwaysBounceVertical = false
        $0.translatesAutoresizingMaskIntoConstraints = false
    }

    private let textView = UITextView(frame: .zero).with {
        $0.backgroundColor = .clear
        $0.isScrollEnabled = false
        $0.isEditable = false
        $0.isSelectable = true
        $0.translatesAutoresizingMaskIntoConstraints = false
    }

    // MARK: - Interface

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    func setTheme(_ theme: CodeTheme) {
        self.theme = theme
    }

    func setSyntax(_ syntax: CodeSyntaxHighlighter) {
        self.syntax = syntax
    }

    func setCode(_ code: String) {
        let codeStr = NSMutableAttributedString(string: code)
        let decorated = syntax.decorate(code: codeStr, with: theme)

        textView.attributedText = decorated
        backgroundColor = theme.textBgColor
    }
}

// MARK: - Private

private extension CodeView {

    func setup() {

        scrollView.addSubview(textView)
        addSubview(scrollView)
        backgroundColor = #colorLiteral(red: 0.1568444967, green: 0.1568739712, blue: 0.156840831, alpha: 1)

        NSLayoutConstraint.activate([
            scrollView.leftAnchor.constraint(equalTo: leftAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.rightAnchor.constraint(equalTo: rightAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            textView.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: 10),
            textView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            textView.rightAnchor.constraint(equalTo: scrollView.rightAnchor, constant: -10),
            textView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            textView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }
}

// MARK: - Convenience

private struct PlainTextDecorator: CodeSyntaxHighlighter {

    func decorate(
        code: NSMutableAttributedString,
        with theme: CodeTheme) -> NSAttributedString {

        let allStrRange = NSRange(
            location: 0,
            length: (code.string as NSString).length)

        let themeAttributes: [NSAttributedString.Key : Any] = [
            .foregroundColor: theme.mainTextColor,
            .font: theme.mainFont
        ]

        code.addAttributes(themeAttributes, range: allStrRange)
        return code
    }
}
