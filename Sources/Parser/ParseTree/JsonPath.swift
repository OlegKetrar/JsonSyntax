//
//  JsonPath.swift
//  JsonSyntax
//
//  Created by Oleg Ketrar on 19.10.2024.
//

public struct JsonPath: Equatable, CustomStringConvertible {
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

    public var description: String {
        array
            .enumerated()
            .map { index, item in
                var str = ""

                if case .object = item, index != 0 {
                    str.append(".")
                }

                str.append(item.description)

                return str
            }
            .joined()
    }
}

public enum JsonPathComponent: Equatable, CustomStringConvertible {
    case object(String)
    case array(Int)

    public var description: String {
        switch self {
        case let .object(key): return key
        case let .array(index): return "[\(index)]"
        }
   }
}
