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
    case applyingToShapeThatDoesntExist(String)
    case badlyDefinedMetadata
    case unexpectedMetadataValue
    case unattachedTraits
    case unexpectedToken(Tokenizer.Token)
    case overflow
}

extension Smithy {
    
    /// Parse IDL to create Smithy Model
    /// - Parameter string: IDL
    /// - Throws: `SmithyParserError`
    /// - Returns: Smithy Model
    func parse(_ string: String) throws -> Model {
        let tokens = try Tokenizer().tokenize(string)
        var tokenParser = TokenParser(tokens)

        // IDL is split into three distinct sections: control, metadata and shapes
        var model = try parseControlSection(&tokenParser)
        model["metadata"] = try parseMetadataSection(&tokenParser)
        model["shapes"] = try parserShapesSection(&tokenParser)

        let data = try JSONSerialization.data(withJSONObject: model, options: [])
        print(String(data: data, encoding: .utf8)!)
        return try Smithy().decodeAST(from: data)
    }
    
    /// parse control section of IDL
    func parseControlSection(_ tokenParser: inout TokenParser) throws -> [String: Any] {
        let model: [String: Any] = ["smithy": "1.0"]
        while !tokenParser.reachedEnd() {
            tokenParser.skip(while: .newline)
            let token = try tokenParser.token()
            if case .token(let string) = token {
                if string == "$version" {
                    try tokenParser.advance()
                    // currently we support version "1.0"
                    try tokenParser.expect(.string("1.0"))
                } else {
                    break
                }
            } else {
                throw SmithyParserError.unexpectedToken(token)
            }
        }
        return model
    }
    
    /// Parse metadata section of IDL
    /// - Returns: Metadata dictionary
    func parseMetadataSection(_ tokenParser: inout TokenParser) throws -> [String: Any] {
        var metaData: [String: Any] = [:]
        while !tokenParser.reachedEnd() {
            tokenParser.skip(while: .newline)
            let token = try tokenParser.token()
            if case .token(let string) = token {
                if string == "metadata" {
                    try tokenParser.advance()
                    let token = try tokenParser.nextToken()
                    guard case .string(let string) = token else { throw SmithyParserError.badlyDefinedMetadata }
                    try tokenParser.expect(.grammar("="))
                    let value = try parseValue(&tokenParser, namespace: nil)
                    metaData[string] = value
                } else {
                    // must have reached end of metadata section
                    break
                }
            } else {
                throw SmithyParserError.unexpectedToken(token)
            }
        }
        return metaData
    }
    
    /// parse shapes section of IDL
    /// - Returns: Shapes as a dictionary
    func parserShapesSection(_ tokenParser: inout TokenParser) throws -> [Substring: Any] {
        var namespace: Substring? = nil
        var modelShapes: [Substring: Any] = [:]
        var traits: [Substring: Any] = [:]

        while !tokenParser.reachedEnd() {
            let token = try tokenParser.nextToken()
            if case .token(let string) = token {
                if string == "namespace" {
                    // namespace
                    if traits.count > 0 {
                        throw SmithyParserError.unattachedTraits
                    }
                    let token = try tokenParser.nextToken()
                    guard case .token(let name) = token else { throw SmithyParserError.missingNamespace }
                    guard modelShapes["shapes"] == nil else { throw SmithyParserError.shapesDefinedBeforeNamespace }
                    guard namespace == nil else { throw SmithyParserError.namespaceAlreadyDefined }
                    namespace = name
                } else if string == "metadata" {
                    // unexpected metadata. Should have already been read
                    throw SmithyParserError.unexpectedToken(token)
                } else if string.first == "@" {
                    // if trait
                    let traitName = string.dropFirst()
                    let trait = try parseTrait(&tokenParser, namespace: namespace)
                    traits[fullTraitName(traitName, namespace: namespace)] = trait
                } else if string == "apply" {
                    try parseApply(&tokenParser, shapes: &modelShapes, namespace: namespace)
                } else {
                    // must be a shape
                    let token = try tokenParser.nextToken()
                    guard case .token(let name) = token else { throw SmithyParserError.unexpectedToken(token) }
                    let shapeName = namespace != nil ? "\(namespace!)#\(name)" : name
                    var shape = try parseShape(&tokenParser, type: string, namespace: namespace)
                    if traits.count > 0 {
                        shape["traits"] = traits
                    }
                    traits = [:]
                    modelShapes[shapeName] = shape
                }
            } else if case .documentationComment(let comment) = token {
                traits["smithy.api#documentation"] = comment
            } else if token == .newline{
                if traits.count > 0 {
                    throw SmithyParserError.unattachedTraits
                }
            } else {
                throw SmithyParserError.unexpectedToken(token)
            }
        }
        return modelShapes
    }
    
    /// Parse shape from tokenized smithy
    func parseShape(_ tokenParser: inout TokenParser, type: Substring, namespace: Substring?) throws -> [Substring: Any] {
        var shape: [Substring: Any] = ["type": type]
        var traits: [Substring: Any] = [:]
        guard !tokenParser.reachedEnd() else { return shape }
        let next = try tokenParser.nextToken()
        guard next != .newline else { return shape }
        guard next == .grammar("{") else { throw SmithyParserError.unexpectedToken(next) }
        
        var members: [Substring: Any] = [:]
        
        while !tokenParser.reachedEnd() {
            let token = try tokenParser.nextToken()
            if case .token(let string) = token {
                if string.first == "@" {
                    // if trait
                    let traitName = string.dropFirst()
                    let trait = try parseTrait(&tokenParser, namespace: namespace)
                    traits[fullTraitName(traitName, namespace: namespace)] = trait
                } else {
                    // assume token is a shape name
                    try tokenParser.expect(.grammar(":"))
                    let value = try parseValue(&tokenParser, namespace: namespace)
                    if traits.count > 0,
                       var dictionary = value as? [String: Any],
                       dictionary["target"] != nil {
                        dictionary["traits"] = traits
                        members[string] = dictionary
                    } else {
                        members[string] = value
                    }
                    traits = [:]
                    if try endCollection(&tokenParser, endToken: .grammar("}")) {
                        break
                    }
                }
            } else if case .documentationComment(let comment) = token {
                traits["smithy.api#documentation"] = comment
            } else if token == .newline {
                if traits.count > 0 {
                    throw SmithyParserError.unattachedTraits
                }
            } else if token == .grammar("}"){
                if traits.count > 0 {
                    throw SmithyParserError.unattachedTraits
                }
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
    
    /// Return full shape name given name. If name has no namespace search for shape in available namespaces
    /// otherwise prefix with current namespace
    func fullShapeName(_ name: Substring, namespace: Substring?) -> Substring {
        // if name has no namespace check if it is a prelude object
        let shapeId = ShapeId(rawValue: String(name))
        if shapeId.namespace == nil {
            if Self.preludeShapes[ShapeId(rawValue: "smithy.api#\(name)")] != nil {
                return "smithy.api#\(name)"
            } else if let namespace = namespace {
                return "\(namespace)#\(name)"
            }
        }
        return name
    }
    
    /// Return full trait name. If name has no namespace search for shape in available namespaces
    /// otherwise prefix with current namespace
    func fullTraitName(_ name: Substring, namespace: Substring?) -> Substring {
        // if name has no namespace check if it is a prelude object
        let traitId = ShapeId(rawValue: String(name))
        if traitId.namespace == nil {
            if TraitList.possibleTraits["smithy.api#\(name)"] != nil {
                return "smithy.api#\(name)"
            } else if let namespace = namespace {
                return "\(namespace)#\(name)"
            }
        }
        return name
    }
    
    /// parse a value. This could be a string, number, array, dictionary or shape id
    func parseValue(_ tokenParser: inout TokenParser, namespace: Substring?) throws -> Any {
        let token = try tokenParser.nextToken()
        switch token {
        case .string(let string):
            return string
        case .number(let number):
            return number
        case .grammar("{"):
            return try parseDictionary(&tokenParser, namespace: namespace)
        case .grammar("["):
            return try parseArray(&tokenParser, namespace: namespace)
        case .token(let token):
            return ["target": fullShapeName(token, namespace: namespace)]
        default:
            throw SmithyParserError.unexpectedMetadataValue

        }
    }
    
    func parseMappedValues(_ tokenParser: inout TokenParser, endToken: Tokenizer.Token, namespace: Substring?) throws -> [Substring: Any] {
        var dictionary: [Substring: Any] = [:]
        while !tokenParser.reachedEnd() {
            tokenParser.skip(while: .newline)
            let token = try tokenParser.nextToken()
            if token == endToken {
                break
            } else if case .token(let key) = token {
                try tokenParser.expect(.grammar(":"))
                let value = try parseValue(&tokenParser, namespace: namespace)
                dictionary[key] = value
                if try endCollection(&tokenParser, endToken: endToken) {
                    break
                }
            } else {
                throw SmithyParserError.unexpectedToken(token)
            }
        }
        return dictionary
    }
    
    func parseParameters(_ tokenParser: inout TokenParser, namespace: Substring?) throws -> Any {
        if case .token = try tokenParser.token() {
            return try parseMappedValues(&tokenParser, endToken: .grammar(")"), namespace: namespace)
        } else {
            let value = try parseValue(&tokenParser, namespace: namespace)
            try tokenParser.expect(.grammar(")"))
            return value
        }
    }
    
    func parseDictionary(_ tokenParser: inout TokenParser, namespace: Substring?) throws -> [Substring: Any] {
        return try parseMappedValues(&tokenParser, endToken: .grammar("}"), namespace: namespace)
    }

    func parseArray(_ tokenParser: inout TokenParser, namespace: Substring?) throws -> [Any] {
        var array: [Any] = []
        while !tokenParser.reachedEnd() {
            tokenParser.skip(while: .newline)
            let token = try tokenParser.token()
            if token == .grammar("]") {
                try tokenParser.advance()
                break
            } else {
                let value = try parseValue(&tokenParser, namespace: namespace)
                array.append(value)
                if try endCollection(&tokenParser, endToken: .grammar("]")) {
                    break
                }
            }
        }
        return array
    }

    func parseTrait(_ tokenParser: inout TokenParser, namespace: Substring?) throws -> Any {
        let token = try tokenParser.token()
        let value: Any
        if token == .newline {
            value = [:]
        } else if token == .grammar("(") {
            try tokenParser.advance()
            value = try parseParameters(&tokenParser, namespace: namespace)
        } else if case .token = token {
            value = [:]
        } else {
            throw SmithyParserError.unexpectedToken(token)
        }
        if tokenParser.reachedEnd() {
            return value
        }
        switch try tokenParser.token() {
        case .newline:
            try tokenParser.advance()
        case .token:
            break
        default:
            throw SmithyParserError.unexpectedToken(token)
        }
        return value
    }
    
    func parseApply(_ tokenParser: inout TokenParser, shapes: inout [Substring: Any], namespace: Substring?) throws {
        let shapeToken = try tokenParser.nextToken()
        guard case .token(let _) = shapeToken else {throw SmithyParserError.unexpectedToken(shapeToken) }
        let traitToken = try tokenParser.nextToken()
        guard case .token(let trait) = traitToken else {throw SmithyParserError.unexpectedToken(traitToken) }
        guard trait.first == "@" else {throw SmithyParserError.unexpectedToken(traitToken) }
        _ = try parseTrait(&tokenParser, namespace: namespace)
    }
    
    func endCollection(_ tokenParser: inout TokenParser, endToken: Tokenizer.Token) throws -> Bool {
        let nextToken = try tokenParser.nextToken()
        if nextToken == endToken {
            return true
        } else if nextToken == .grammar(",") {
            return false
        } else if nextToken == .newline {
            tokenParser.skip(while: .newline)
            try tokenParser.expect(endToken)
            return true
        } else {
            throw SmithyParserError.unexpectedToken(nextToken)
        }
    }
    
    /// Token parser used internal by Smithy.parse
    struct TokenParser {
        let tokens: [Tokenizer.Token]
        var position: Int
        
        init(_ tokens: [Tokenizer.Token]) {
            self.tokens = tokens
            position = tokens.startIndex
        }
        
        func token() throws -> Tokenizer.Token {
            guard position != tokens.endIndex else { throw SmithyParserError.overflow }
            return tokens[position]
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

        func reachedEnd() -> Bool {
            return position == tokens.endIndex
        }
    }
    
}
