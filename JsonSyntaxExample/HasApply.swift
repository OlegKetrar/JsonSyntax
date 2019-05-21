//
//  HasApply.swift
//  JsonSyntaxExample
//
//  Created by Oleg Ketrar on 20/05/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

import Foundation
import class UIKit.UIView

protocol HasApply {}

extension HasApply {

    /// Used for Value types.
    func with(_ closure: (inout Self) throws -> Void) rethrows -> Self {
        var copy = self
        try closure(&copy)
        return copy
    }

    func `do`(_ closure: (Self) throws -> Void) rethrows {
        try closure(self)
    }
}

extension HasApply where Self: AnyObject {

    /// Used for Reference types.
    func apply(_ closure: (Self) throws -> Void) rethrows -> Self {
        try closure(self)
        return self
    }
}

extension UIView: HasApply {}
