//: Playground - noun: a place where people can play

import PlaygroundSupport
import SwiftyMarkdown
import Foundation


let rawMarkdown = """
Prefix
# Welcome

**Hey**, this is _markdown_.

- Item 1
- Item 2

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
let markCharacters = CharacterSet(charactersIn: "*_-\n#>`[\\")


struct State {
    var quoteLevel: Int = 0
    var codeBlock: Bool = false

}

enum NodeType {
    case text
    case heading(Int)
    case list(Bool)
    case listItem
    case inlineCode
    case codeBlock
    case emphasis
    case strong
    case strike
    case link(String, String)
    case image(String, String)
}

class Node {
    let type: NodeType
    var children = [Node]()
    
    init(type: NodeType) {
        self.type = type
    }
}

let lines = rawMarkdown.components(separatedBy: .newlines)
var state = State()

for line in lines {
    
    let scanner = Scanner(string: line)
    var marks = [Node]()
    
    while !scanner.isAtEnd {
        if let text = scanner.scanUpToCharacters(from: markCharacters) {
            marks
            print("Text: \(text)")
        }
        else if let markText = scanner.scanCharacters(from: markCharacters) {
            
            var escaped: Bool = false
            var last: String = ""

            for char in markText {
                switch char {
                case "\\":
                    escaped = true
                default:
                    if escaped == true {
                        escaped = false
                        marks.append("\\\(char)")
                    } else if last.isEmpty || last.last == char {
                        last.append(char)
                    } else {
                        marks.append(last)
                        last = ""
                    }
                }
            }
            if !last.isEmpty {
                marks.append(last)
            }
            
            
            for m in marks {
                if open[m] != nil {
                    open[m]
                }
                else {
                    open[m] = Node(type: <#T##NodeType#>)
                }
            }
            print("Mark: \(marks)")
        }
    }
    var open = [String:Node]()
    
}
