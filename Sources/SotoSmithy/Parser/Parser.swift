//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2020 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation

enum ParserError : Error {
    case overflow
}

/// Reader object for parsing String buffers
struct Parser {
    /// internal storage used to store String
    private class Storage {
        init(_ buffer: String) {
            self.buffer = buffer
        }
        let buffer: String
    }

    private let _storage: Storage
    
    /// Create a Reader object
    /// - Parameter string: String to parse
    init(_ string: String) {
        self._storage = Storage(string)
        self.position = string.startIndex
    }
    
    var buffer: String { return _storage.buffer }
    private(set) var position: String.Index
}

extension Parser {
    
    /// Return current character
    /// - Throws: .overflow
    /// - Returns: Current character
    mutating func character() throws -> Character {
        guard !reachedEnd() else { throw ParserError.overflow }
        let c = unsafeCurrent()
        unsafeAdvance()
        return c
    }
    
    /// Read the current character and return if it is as intended. If character test returns true then move forward 1
    /// - Parameter char: character to compare against
    /// - Throws: .overflow
    /// - Returns: If current character was the one we expected
    mutating func read(_ char: Character) throws -> Bool {
        let c = try character()
        guard c == char else { unsafeRetreat(); return false }
        return true
    }
    
    /// Read the current character and check if it is in a set of characters If character test returns true then move forward 1
    /// - Parameter characterSet: Set of characters to compare against
    /// - Throws: .overflow
    /// - Returns: If current character is in character set
    mutating func read(_ characterSet: Set<Character>) throws -> Bool {
        let c = try character()
        guard characterSet.contains(c) else { unsafeRetreat(); return false }
        return true
    }
    
    /// Read next so many characters from buffer
    /// - Parameter count: Number of characters to read
    /// - Throws: .overflow
    /// - Returns: The string read from the buffer
    mutating func read(count: Int) throws -> Substring {
        guard buffer.distance(from: position, to: buffer.endIndex) >= count else { throw ParserError.overflow }
        let end = buffer.index(position, offsetBy: count)
        let subString = buffer[position..<end]
        unsafeAdvance(by: count)
        return subString
    }
    
    /// Read from buffer until we hit a character. Position after this is of the character we were checking for
    /// - Parameter until: Character to read until
    /// - Throws: .overflow if we hit the end of the buffer before reading character
    /// - Returns: String read from buffer
    @discardableResult mutating func read(until: Character, throwOnOverflow: Bool = true) throws -> Substring {
        let startIndex = position
        while !reachedEnd() {
            if unsafeCurrent() == until {
                return buffer[startIndex..<position]
            }
            unsafeAdvance()
        }
        if throwOnOverflow {
            unsafeSetPosition(startIndex)
            throw ParserError.overflow
        }
        return buffer[startIndex..<position]
    }
    
    /// Read from buffer until we hit a character in supplied set. Position after this is of the character we were checking for
    /// - Parameter characterSet: Character set to check against
    /// - Throws: .overflow
    /// - Returns: String read from buffer
    @discardableResult mutating func read(until characterSet: Set<Character>, throwOnOverflow: Bool = true) throws -> Substring {
        let startIndex = position
        while !reachedEnd() {
            if characterSet.contains(unsafeCurrent()) {
                return buffer[startIndex..<position]
            }
            unsafeAdvance()
        }
        if throwOnOverflow {
            unsafeSetPosition(startIndex)
            throw ParserError.overflow
        }
        return buffer[startIndex..<position]
    }
    
    /// Read from buffer from current position until the end of the buffer
    /// - Returns: String read from buffer
    @discardableResult mutating func readUntilTheEnd() -> Substring {
        let startIndex = position
        position = buffer.endIndex
        return buffer[startIndex..<position]
    }
    
    /// Read while character at current position is the one supplied
    /// - Parameter while: Character to check against
    /// - Returns: String read from buffer
    @discardableResult mutating func read(while: Character) -> Int {
        var count = 0
        while !reachedEnd(),
            unsafeCurrent() == `while` {
            unsafeAdvance()
            count += 1
        }
        return count
    }

    /// Read while keyPath on character at current position returns true is the one supplied
    /// - Parameter while: keyPath to check
    /// - Returns: String read from buffer
    @discardableResult mutating func read(while keyPath: KeyPath<Character, Bool>) -> Substring {
        let startIndex = position
        while !reachedEnd(),
            unsafeCurrent()[keyPath: keyPath] {
            unsafeAdvance()
        }
        return buffer[startIndex..<position]
    }
    
    /// Read while character at current position is in supplied set
    /// - Parameter while: character set to check
    /// - Returns: String read from buffer
    @discardableResult mutating func read(while characterSet: Set<Character>) -> Substring {
        let startIndex = position
        while !reachedEnd(),
            characterSet.contains(unsafeCurrent()) {
            unsafeAdvance()
        }
        return buffer[startIndex..<position]
    }
    
    /// Return whether we have reached the end of the buffer
    /// - Returns: Have we reached the end
    func reachedEnd() -> Bool {
        return position == buffer.endIndex
    }
    
    /// Return whether we are at the start of the buffer
    /// - Returns: Are we are the start
    func atStart() -> Bool {
        return position == buffer.startIndex
    }
}

extension Parser {
    struct Context {
        let line: String
        let lineNumber: Int
        let columnNumber: Int
    }

    /// Return context of current position (line, lineNumber, columnNumber)
    func getContext() -> Context {
        var parser = self
        var columnNumber = 0
        while !parser.atStart() {
            try? parser.retreat()
            if (try? parser.current()) == "\n" {
                break
            }
            columnNumber += 1
        }
        if (try? parser.current()) == "\n" {
            try? parser.advance()
        }
        // read line from parser
        let line = try! parser.read(until: Character("\n"), throwOnOverflow: false)
        // count new lines up to this current position
        let buffer = parser.buffer
        let textBefore = buffer[buffer.startIndex..<position]
        let lineNumber = textBefore.filter{ $0.isNewline }.count

        return Context(line: String(line), lineNumber: lineNumber + 1, columnNumber: columnNumber + 1)
    }
}

/// Public versions of internal functions which include tests for overflow
extension Parser {
    /// Return the character at the current position
    /// - Throws: .overflow
    /// - Returns: Character
    func current() throws -> Character {
        guard !reachedEnd() else { throw ParserError.overflow }
        return unsafeCurrent()
    }
    
    /// Move forward one character
    /// - Throws: .overflow
    mutating func advance() throws {
        guard !reachedEnd() else { throw ParserError.overflow }
        return unsafeAdvance()
    }
    
    /// Move back one character
    /// - Throws: .overflow
    mutating func retreat() throws {
        guard position != buffer.startIndex else { throw ParserError.overflow }
        return unsafeRetreat()
    }
    
    /// Move forward so many character
    /// - Parameter amount: number of characters to move forward
    /// - Throws: .overflow
    mutating func advance(by amount: Int) throws {
        guard buffer.distance(from: position, to: buffer.endIndex) >= amount else { throw ParserError.overflow }
        return unsafeAdvance(by: amount)
    }
    
    /// Move back so many characters
    /// - Parameter amount: number of characters to move back
    /// - Throws: .overflow
    mutating func retreat(by amount: Int) throws {
        guard buffer.distance(from: buffer.startIndex, to: position) >= amount else { throw ParserError.overflow }
        return unsafeRetreat(by: amount)
    }
    
    mutating func setPosition(_ position: String.Index) throws {
        guard position <= buffer.endIndex else { throw ParserError.overflow }
        unsafeSetPosition(position)
    }
}

// unsafe versions without checks
extension Parser {
    func unsafeCurrent() -> Character {
        return buffer[position]
    }
    
    mutating func unsafeAdvance() {
        position = buffer.index(after: position)
    }
    
    mutating func unsafeRetreat() {
        position = buffer.index(before: position)
    }
    
    mutating func unsafeAdvance(by amount: Int) {
        position = buffer.index(position, offsetBy: amount)
    }
    
    mutating func unsafeRetreat(by amount: Int) {
        position = buffer.index(position, offsetBy: -amount)
    }
    
    mutating func unsafeSetPosition(_ position: String.Index) {
        self.position = position
    }
}
