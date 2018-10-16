//: Playground - noun: a place where people can play

import PlaygroundSupport
import SwiftyMarkdown
import Foundation

let rawMarkdown = """
Prefix
## Welcome to _Markdown_

***Hey, this is _markdown_**.

- Item 1
- Item 2

How does it work - magic!

That's pretty neat 🤣👨‍👩‍👦‍👦

> Did you know?
> [Markdown](www.markdown.com) can be a pain in the ass to parse!
> > Test

This is `Code`

```
let name = "Bob"
print("Hey \\(name)")
```

Bold is done with \\*\\*Bold**
"""

//let mark = Markdown(string: "# Welcome\n**Hey**, this is markdown\n>")

//scanner.charactersToBeSkipped = nil



extension String {
    var isRepeatedCharacter: Bool {
        guard let first = self.first else { return false }
        return !self.contains { return $0 != first }
    }
}

struct State {
    var quoteLevel: Int = 0
    var codeBlock: Bool = false

}

enum NodeType: Equatable {
    case document
    case text(String)
    case heading(Int)
    case blockQuote(Int)
    case list(Bool)
    case listItem
    case inlineCode
    case codeBlock
    case emphasis(String)
    case strong(String)
    case strike(String)
    case link(String, String)
    case image(String, String)

    func toText() -> NodeType? {
        switch self {
        case .document: return nil
        case .text: return self
        case let .heading(level): return .text(String(repeating: "#", count: level))
        case .list: return nil
        case .listItem: return nil
        case .inlineCode: return nil
        case .codeBlock: return nil
        case .blockQuote: return nil
        case let .emphasis(str): return .text(str)
        case let .strong(str): return .text(str)
        case let .strike(str): return .text(str)
        case .link: return nil
        case .image: return nil
        }
    }
}

class Node {
    let type: NodeType
    var children = [Node]()

    init(type: NodeType, children: [Node] = []) {
        self.type = type
        self.children = children
    }
}

extension Node : CustomDebugStringConvertible {
    var debugDescription: String {
        return formattedDescription(level: 0)
    }

    func formattedDescription(level: Int) -> String {
        var comps = [String(repeating: "\t", count: level) + "↳ \(self.type)"]
        let _children = children.map { return $0.formattedDescription(level: level + 1) }
        comps.append(contentsOf: _children)
        return comps.joined(separator: "\n")
    }
}

extension Sequence where Element == NodeType {

    func reducingText() -> [NodeType] {
        var join: String?
        var reduced = self.reduce(into: [NodeType]()) { (res, node) in
            switch node {
            case let .text(str):
                join = (join ?? "") + str
            default:
                if let str = join {
                    res.append(.text(str))
                    join = nil
                }
                res.append(node)
            }
        }
        if let str = join {
            reduced.append(.text(str))
        }
        return reduced
    }
}





class Parser {
    
    var markdown: String
    init(markdown: String) {
        self.markdown = markdown
    }
    
    func parse() -> Node {
        
        let lines = self.markdown.components(separatedBy: .newlines)
        let markCharacters = CharacterSet(charactersIn: "*_-\n#>`[\\")
        var document = Node(type: .document)
        var blocks: [Node] = []
        
        var isNewline = true

        func nodeType(for string: String) -> NodeType {
            guard let char = string.first else {
                return .text(string)
            }
            switch char {
            case "\\" where string.count > 1:
                return .text(String(string.dropFirst()))
//            case "-" where isNewline && string.count == 1,
//                 "*" where isNewline && string.count == 1,
//                 "+" where isNewline && string.count == 1:
//                return .listItem
            case "*" where string.count == 1,
                 "_" where string.count == 1:
                return .emphasis(string)
            case "*" where string.isRepeatedCharacter,
                 "_" where string.isRepeatedCharacter:
                return .strong(string)
            case "~" where string.count > 1 && string.isRepeatedCharacter:
                return .strike(string)
            case "`" where string.count == 1:
                return .inlineCode
            case "#" where string.isRepeatedCharacter:
                return .heading(string.count)
            default:
                return .text(string)
            }
        }
        
        for _line in lines {
            isNewline = true
            let line = _line.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let scanner = Scanner(string: line)
            scanner.charactersToBeSkipped = CharacterSet()
            var stack = [NodeType]()
            
            while true {
                if isNewline {
                    if let text = scanner.scanCharacters(in: "#") {
                        stack.append(.heading(text.count))
                    } else if let text = scanner.scanCharacters(in: "> ") {
                        let level = text.filter { return $0 == ">" }.count
                        
                        if blocks.
                        
                        // Check if we are already in a block
                        stack.append(.blockQuote(level))
                    }
                    else if scanner.scanCharacters(in: "-") != nil || scanner.scanCharacters(in: "+") != nil {
                        stack.append(.listItem)
                    } else if let text = scanner.scanCharacters(in: "*") {
                        if text.count == 1 {
                            stack.append(.listItem)
                        }
                        else {
                            stack.append(nodeType(for: text))
                        }
                    } else if let text = scanner.scanCharacters(in: "123456789") {
                        if scanner.scanCharacters(in: ".") != nil {
                            stack.append(.listItem)
                        } else {
                            stack.append(.text(text))
                        }
                    }
                }
                if let text = scanner.scanUpToCharacters(from: markCharacters) {
                    stack.append(.text(text))
                }
                else if let markText = scanner.scanCharacters(from: markCharacters) {
                    var marks = [String]()
                    var last: String = ""
                    
                    func commitLast() {
                        if !last.isEmpty {
                            marks.append(last)
                        }
                        last = ""
                    }
                    for char in markText {
                        switch char {
                        case _ where last == "\\":
                            last = "\\\(char)"
                            commitLast()
                        case "\\":
                            commitLast()
                            last = "\\"
                        case _ where last.isEmpty || last.last == char:
                            last.append(char)
                        default:
                            commitLast()
                            last.append(char)
                        }
                    }
                    commitLast()
                    stack.append(contentsOf: marks.map { return nodeType(for: $0) })
                }
                if scanner.isAtEnd { break }
                isNewline = false
            }
            
            stack = stack.reducingText()
            var cursor = 0
            func nodes(upTo end: Int) -> [Node] {
                var res = [Node]()
                
                func next(indexOf node: NodeType) -> Int? {
                    var c = cursor
                    while c < end {
                        if stack[c] == node { return c }
                        c += 1
                    }
                    return nil
                }
                
                while cursor < end {
                    let current = stack[cursor]
                    cursor += 1
                    
                    switch current {
                    case .text:
                        res.append(Node(type: current))
                    case .heading:
                        res.append(Node(type: current,
                                        children: nodes(upTo: end)))
                    case .listItem:
                        res.append(Node(type: current,
                                        children: nodes(upTo: end)))
                    case let .blockQuote(level):
                        res.append(Node(type: current,
                                        children: nodes(upTo: end)))
                    default:
                        if let close = next(indexOf: current) {
                            res.append(Node(type: current,
                                            children: nodes(upTo: close)))
                            cursor += 1
                        }
                        else if let txt = current.toText() {
                            res.append(Node(type: txt))
                        }
                    }
                }
                return res
            }
            
            document.children.append(contentsOf: nodes(upTo: stack.count))
        }
        return document
    }
}


let doc = Parser(markdown: rawMarkdown).parse()
print(doc)
