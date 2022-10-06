//
//  Utils.swift
//  JsonSyntax
//
//  Created by Oleg Ketrar on 06.10.2022.
//

import Foundation

extension Collection where Index == Int {

    func item(at index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
