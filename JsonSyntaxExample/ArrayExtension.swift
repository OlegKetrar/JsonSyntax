//
//  ArrayExtension.swift
//  JsonSyntaxTests
//
//  Created by Oleg Ketrar on 20/05/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

extension Array where Element: CustomStringConvertible {

    var newlinePrintedDescription: String {
        guard !isEmpty else { return "[]" }

        let str = self.map { "\t\($0.description)" }.joined(separator: "\n")
        return "[\n\(str)\n]"
    }
}
