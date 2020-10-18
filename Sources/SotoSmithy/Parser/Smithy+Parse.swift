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

enum SmithyParserError: Error {
    case shapesDefinedBeforeNamespace
    case namespaceAlreadyDefined
    case missingNamespace
    case badlyDefinedMetadata
    case unexpectedMetadataValue
    case missingShapeName
    case unexpectedToken(Tokenizer.Token)
    case overflow
}

extension Smithy {
    
    func parse(_ string: String) throws -> Model {
        var model: [Substring: Any] = [:]
        var modelShapes: [Substring: Any] = [:]
        var metaData: [String: Any] = [:]
        let tokens = try Tokenizer().tokenize(string)
        var tokenParser = TokenParser(tokens)
        var namespace: Substring? = nil

        model["smithy"] = "1.0"
        
        while !tokenParser.reachedEnd() {
            tokenParser.skip(while: .newline)
            let token = try tokenParser.nextToken()
            if case .token(let string) = token {
                if string == "namespace" {
                    let token = try tokenParser.nextToken()
                    guard case .token(let name) = token else { throw SmithyParserError.missingNamespace }
                    guard modelShapes["shapes"] == nil else { throw SmithyParserError.shapesDefinedBeforeNamespace }
                    guard namespace == nil else { throw SmithyParserError.namespaceAlreadyDefined }
                    namespace = name
                } else if string == "metadata" {
                    let token = try tokenParser.nextToken()
                    guard case .string(let string) = token else { throw SmithyParserError.badlyDefinedMetadata }
                    try tokenParser.expect(.grammar("="))
                    let value = try parseValue(&tokenParser)
                    metaData[string] = value
                } else if string.first == "@" {
                    //let traitName = string.dropFirst()
                } else {
                    let token = try tokenParser.nextToken()
                    guard case .token(let name) = token else { throw SmithyParserError.missingShapeName }
                    let shapeName = namespace != nil ? "\(namespace!)#\(name)" : name
                    modelShapes[shapeName] = try parseShape(&tokenParser, type: string, namespace: namespace)
                }
            }
        }
        model["metadata"] = metaData
        model["shapes"] = modelShapes
        let data = try JSONSerialization.data(withJSONObject: model, options: [])
        print(String(data: data, encoding: .utf8)!)
        return try Smithy().decodeAST(from: data)
    }
    
    /// Parse shape from tokenized smithy
    func parseShape(_ tokenParser: inout TokenParser, type: Substring, namespace: Substring?) throws -> [Substring: Any] {
        var shape: [Substring: Any] = ["type": type]
        guard !tokenParser.reachedEnd() else { return shape }
        let next = try tokenParser.nextToken()
        guard next != .newline else { return shape }
        guard next == .grammar("{") else { throw SmithyParserError.unexpectedToken(next) }
        
        var members: [Substring: Any] = [:]
        
        while !tokenParser.reachedEnd() {
            tokenParser.skip(while: .newline)
            let token = try tokenParser.nextToken()
            if case .token(let string) = token {
                try tokenParser.expect(.grammar(":"))
                let token = try tokenParser.nextToken()
                guard case .token(var name) = token else { throw SmithyParserError.unexpectedToken(token) }
                // if name has no namespace check if it is a prelude object
                let shapeId = ShapeId(rawValue: String(name))
                if shapeId.namespace == nil {
                    if Self.preludeShapes[ShapeId(rawValue: "smithy.api#\(name)")] != nil {
                        name = "smithy.api#\(name)"
                    } else if let namespace = namespace {
                        name = "\(namespace)#\(name)"
                    }
                }
                members[string] = ["target": name]
                // get next token if it is a closed curly brackets we are done, if it is a comma carry on, if it
                // is a newline read all newlines and expect a closed curly bracket otherwise throw error
                let endToken = try tokenParser.nextToken()
                if endToken == .grammar("}") {
                    break
                } else if endToken == .grammar(",") {
                    continue
                } else if endToken == .newline {
                    tokenParser.skip(while: .newline)
                    try tokenParser.expect(.grammar("}"))
                    break
                } else {
                    throw SmithyParserError.unexpectedToken(endToken)
                }
            } else if token == .grammar("}"){
                // closed curly bracket so we are done
                break
            } else {
                throw SmithyParserError.unexpectedToken(token)
            }
        }
        
        if type == "union" || type == "structure" {
            shape["members"] = members
        } else {
            for entry in members {
                shape[entry.key] = entry.value
            }
        }
        return shape
    }
    
    func parseValue(_ tokenParser: inout TokenParser) throws -> Any {
        let token = try tokenParser.nextToken()
        switch token {
        case .string(let string):
            return string
        case .number(let number):
            return number
        case .grammar("{"):
            return try parseDictionary(&tokenParser)
        case .grammar("["):
            return try parseArray(&tokenParser)
        default:
            throw SmithyParserError.unexpectedMetadataValue

        }
    }
    
    func parseDictionary(_ tokenParser: inout TokenParser) throws -> [Substring: Any] {
        return [:]
    }

    func parseArray(_ tokenParser: inout TokenParser) throws -> [Any] {
        return []
    }

    /// Token parser used internal by Smithy.parse
    struct TokenParser {
        let tokens: [Tokenizer.Token]
        var position: Int
        
        init(_ tokens: [Tokenizer.Token]) {
            self.tokens = tokens
            position = tokens.startIndex
        }
        
        mutating func nextToken() throws -> Tokenizer.Token {
            guard position != tokens.endIndex else { throw SmithyParserError.overflow }
            let token = tokens[position]
            position += 1
            return token
        }
        
        mutating func advance() throws {
            guard position != tokens.endIndex else { throw SmithyParserError.overflow }
            position += 1
        }
        
        mutating func expect(_ token: Tokenizer.Token) throws {
            guard position != tokens.endIndex else { throw SmithyParserError.overflow }
            guard token == tokens[position] else { throw SmithyParserError.unexpectedToken(token) }
            position += 1
        }

        mutating func skip(while token: Tokenizer.Token) {
            while !reachedEnd() {
                let nextToken = tokens[position]
                position += 1
                if nextToken != token {
                    position -= 1
                    return
                }
            }
        }

        /*@discardableResult mutating func read(until: Tokenizer.Token, throwOnOverflow: Bool = true) throws -> T.SubSequence {
            let startIndex = position
            while !reachedEnd() {
                let token = try nextToken()
                if token == until {
                    return tokens[startIndex..<position]
                }
            }
            if throwOnOverflow {
                position = startIndex
                throw SmithyParserError.overflow
            }
            return tokens[startIndex..<position]
        }*/

        func reachedEnd() -> Bool {
            return position == tokens.endIndex
        }
    }
    
}
