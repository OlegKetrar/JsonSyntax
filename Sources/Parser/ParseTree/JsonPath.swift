//
//  JsonPath.swift
//  JsonSyntax
//
//  Created by Oleg Ketrar on 19.10.2024.
//

import Foundation

public enum JsonPathComponent: Equatable {
    case object(String)
    case array(Int)

    public static func ==(lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.object, .object): return true
        case (.array, .array): return true
        default: return false
        }
    }
}

public struct JsonPath: Equatable {
    private var head: JsonPathComponent
    private var tail: [JsonPathComponent]

    public init(_ root: JsonPathComponent) {
        self.head = root
        self.tail = []
    }

    public init(head: JsonPathComponent, tail: [JsonPathComponent]) {
        self.head = head
        self.tail = tail
    }

    public var first: JsonPathComponent {
        head
    }

    public var last: JsonPathComponent {
        tail.last ?? head
    }

    public var array: [JsonPathComponent] {
        [head] + tail
    }

    public mutating func append(_ path: JsonPathComponent) {
        tail.append(path)
    }
}

enum NativeJson {
    case object([String : Any])
    case array([Any])

    init?(_ jsonData: Data) {
        guard let obj = try? JSONSerialization.jsonObject(with: jsonData) else {
            return nil
        }

        if let dict = obj as? [String : Any] {
            self = .object(dict)

        } else if let array = obj as? [Any] {
            self = .array(array)

        } else {
            return nil
        }
    }

    mutating func replace(at path: JsonPath, value: String) {

    }
}
