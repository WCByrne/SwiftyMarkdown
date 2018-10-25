//: Playground - noun: a place where people can play

import PlaygroundSupport
import SwiftyMarkdown_mac
import Foundation
import AppKit

let rawMarkdown = """
Prefix
## Welcome to _Markdown_

**Hey, this is _markdown_**.

- Item 1
- Item 2

1. Thing 1
2. Thing 2

How does it work - magic!

That's pretty neat 🤣👨‍👩‍👦‍👦

> Did you know?
> [Markdown](www.markdown.com) can be a pain in the ass to parse!
> Test

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
    func removingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
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

extension NSAttributedString {
    var range: NSRange {
        return NSRange(location: 0, length: self.length)
    }
}


//
//struct AttributedStringRenderer {
//
//    func render(node: Node) -> NSAttributedString {
//        let result = self.children.reduce(into: NSMutableAttributedString()) {
//            $0.append($1.attributedString())
//        }
//        switch self.type {
//        case .emphasis:
//            result.addAttributes([.font: UIFont.italicSystemFont(ofSize: 14)],
//                                 range: result.range)
//        case .strong:
//            result.addAttributes([.font: UIFont.boldSystemFont(ofSize: 14)],
//                                 range: result.range)
//        case let .text(str):
//            return NSAttributedString(string: str)
//        case .strike:
//            result.addAttributes([.strikethroughStyle: NSUnderlineStyle.single],
//                                 range: result.range)
//        case let .link(title, url):
//            let attrs: [NSAttributedString.Key: Any] = [
//                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
//                .link: url
//            ]
//            return NSAttributedString(string: title, attributes: attrs)
//        default:
//            break
//        }
//        return result
//
//    }
//
//}



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
    
    func attributedString() -> NSAttributedString {
        
        
        struct Font {
            let base: NSFont
            var size: CGFloat?
            var color: NSColor?
            var bold: Bool = false
            var italic: Bool = false
            
            init(base: NSFont = NSFont.systemFont(ofSize: 13)) {
                self.base = base
            }
            
            var traits: NSFontTraitMask {
                var t = NSFontTraitMask()
                if self.bold { t.insert(.boldFontMask) }
                if self.italic { t.insert(.italicFontMask) }
                return t
            }

            var font: NSFont {
                let manager = NSFontManager.shared
                var f = manager.convert(base, toHaveTrait: self.traits)
                if let s = self.size {
                    f = manager.convert(f, toSize: s)
                }
                return f
            }
            var attributes: [NSAttributedString.Key: Any] {
                return [
                    .font: self.font
                ]
            }
        }
        
        var font = Font()
        
        func render(node: Node) -> NSAttributedString {
            
            func processChildren() -> NSMutableAttributedString {
                print("Processing children: \(self)")
                return node.children.reduce(into: NSMutableAttributedString()) {
                    $0.append(render(node: $1))
                }
            }
            switch self.type {
            case .emphasis:
                font.italic = true
                defer { font.italic = false }
                return processChildren()
            case .strong:
                font.italic = true
                defer { font.italic = false }
                return processChildren()
                
            case let .text(str):
                return NSAttributedString(string: str, attributes: font.attributes)
            case .strike:
                let result = processChildren()
                result.addAttributes([.strikethroughStyle: NSUnderlineStyle.single],
                                     range: result.range)
                return result
            case let .link(title, url):
                var attrs = font.attributes
                attrs[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
                attrs[.link] = url
                return NSAttributedString(string: title, attributes: attrs)
            default:
                return processChildren()
            }
        }
        
        return render(node: self)
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
    
    struct Option: OptionSet {
        let rawValue: Int
        
        static let blockQuote = Option(rawValue: 1 << 0)
        static let inlineCode = Option(rawValue: 1 << 1)
        static let codeBlock = Option(rawValue: 1 << 2)
        static let headings = Option(rawValue: 1 << 3)
        static let orderedList = Option(rawValue: 1 << 4)
        static let unorderedList = Option(rawValue: 1 << 5)
    }
    
    var options: Option = [.orderedList, .unorderedList, .blockQuote, .inlineCode]
    
    func parse() -> Node {
        
        let lines = self.markdown.components(separatedBy: .newlines)
        let markCharacters = CharacterSet(charactersIn: "*_-#>`[\\")
        var document = Node(type: .document)
        
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
            default:
                return .text(string)
            }
        }
        
        var quote: Node?
        var code: Node?
        var list: Node?
        
        for _line in lines {
            isNewline = true
            let line = _line.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let scanner = Scanner(string: line)
            scanner.charactersToBeSkipped = CharacterSet()
            var stack = [NodeType]()
            
            while true {
                if isNewline {
                    if options.contains(.blockQuote), let text = scanner.scanCharacters(in: "> ") {
                        let level = text.filter { return $0 == ">" }.count
                        // Check if we are already in a block
                        if quote == nil {
                            quote = Node(type: .blockQuote(level))
                        }
                    } else if let q = quote {
                        document.children.append(q)
                        quote = nil
                    }
                    
                    if options.contains(.headings), let text = scanner.scanCharacters(in: "#") {
                        stack.append(.heading(text.count))
                    } else if options.contains(.unorderedList), scanner.scanUnorderedList() != nil {
                        stack.append(.listItem)
                    } else if options.contains(.orderedList), scanner.scanOrderedList() != nil {
                        stack.append(.listItem)
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
                        case "[":
                            let loc = scanner.scanLocation
                            if let title = scanner.scanUpToString("]("),
                                let link = scanner.scanUpToString(")")?.removingPrefix("](") {
                                scanner.scanString(")", into: nil)
                                stack.append(.link(title, link))
                            } else {
                                scanner.scanLocation = loc
                                commitLast()
                                last.append(char)
                            }
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
            
            stack.append(NodeType.text("\n"))
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
                    case .blockQuote:
                        print("Got block quote when parsing children ??")
//                        res.append(Node(type: current,
//                                        children: nodes(upTo: end)))
                    case .link:
                        res.append(Node(type: current))
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
            
            
            let newNodes = nodes(upTo: stack.count)
            (quote ?? document).children.append(contentsOf: newNodes)
        }
        return document
    }
}


let doc = Parser(markdown: rawMarkdown).parse()
print(doc)

print(doc.attributedString())

