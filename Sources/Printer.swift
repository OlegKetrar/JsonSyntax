//
//  Printer.swift
//  JsonSyntax iOS
//
//  Created by Oleg Ketrar on 06/06/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

struct Printer {
   private var parseTree: ParseTree

   init(source: ParseTree) {
      self.parseTree = source
   }

   mutating func foldScope(at line: Int) {
      // fold scope
   }

   mutating func unfoldScope(at line: Int) {
      // unfold scope
   }

   mutating func unfoldAllScopes() {
      // unfold all folded scopes
   }

   func print() -> String {
      // return formatted string
      fatalError()
   }

   func highlight() -> [HighlightToken] {
      fatalError()
   }

   func replaceCharacters(
      in range: Range<String.Index>,
      with str: String,
      completion: @escaping ([HighlightToken]) -> Void) {

      // do something

      completion([])
   }
}

struct Editor {
   private var currentString: String

   init(initialString: String) {
      self.currentString = initialString
   }

   func onChange(newString: String) {
      let changeRange = newString.startIndex..<newString.endIndex
      let changedStr = newString

      guard let tree = try? ParseTree(jsonString: currentString) else { return }

      let printer = Printer(source: tree)
      printer.replaceCharacters(
         in: changeRange,
         with: changedStr,
         completion: { tokens in /* color editor with tokens */ })
   }
}
