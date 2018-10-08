//
//  Extensions.swift
//  SwiftyMarkdown
//
//  Created by Wes Byrne on 10/7/18.
//  Copyright © 2018 Voyage Travel Apps. All rights reserved.
//

import Foundation


public extension Scanner {
    
    public func scanCharacters(from set: CharacterSet) -> String? {
        var temp: NSString?
        self.scanCharacters(from: set, into: &temp)
        return temp as String?
    }
    
    public func scanUpToCharacters(from set: CharacterSet) -> String? {
        var temp: NSString?
        self.scanUpToCharacters(from: set, into: &temp)
        return temp as String?
    }
    
    
    public func next() -> Character? {
        guard !self.isAtEnd else { return nil }
        self.scanLocation += 1
        //        let char = (self.string as NSString?)?.character(at: self.scanLocation)
        guard self.index < self.string.endIndex else { return nil }
        return self.string[self.index]
    }
    
    public func current() -> Character? {
        guard !self.isAtEnd else { return nil }
        return self.string[self.index]
    }
    
    var index: String.Index {
        return self.string.index(string.startIndex, offsetBy: self.scanLocation)
    }
    
    func blockPrefix() -> (Character, Int)? {
        
        
        
        if self.string.hasPrefix("#"), let str = self.scanUpToCharacters(from: CharacterSet.newlines(and: "#")) {
            print("Heading: \(str)")
        }
        else if self.string.hasPrefix(">"), let str = self.scanUpToCharacters(from: CharacterSet.newlines(and: ">")) {
            print("Block Quote: \(str)")
        }
        return nil
        //        var spaceCount = 0
        //        var matches = 0
        //        let idx = self.firstIndex {
        //            if $0 == character {
        //                spaceCount = 0
        //                matches += 1
        //                return false
        //            } else if $0 == " ".first! && spaceCount < 4 {
        //                spaceCount += 1
        //                return false
        //            }
        //            return true
        //            } ?? self.endIndex
        //
        //        let range = self.startIndex..<idx
        //        return (matches, range)
    }
    
    /// Returns a Double if scanned, or `nil` if not found.
    func scanDouble() -> Double? {
        var value = 0.0
        scanDouble(&value)
        return value
    }
    
    /// Returns a Float if scanned, or `nil` if not found.
    func scanFloat() -> Float? {
        var value: Float = 0.0
        scanFloat(&value)
        return value
    }
    
    /// Returns an Int if scanned, or `nil` if not found.
    func scanInteger() -> Int? {
        var value = 0
        scanInt(&value)
        return value
    }
}

extension CharacterSet {
    
    static func newlines(and string: String) -> CharacterSet {
        var set = CharacterSet.newlines
        set.insert(charactersIn: string)
        return set
    }
    
}
