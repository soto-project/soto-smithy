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
    case shapesDefinedTooSoon
    case namespaceAlreadyDefined
    case missingNamespace
    case missingShapeId
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
        let state = ParserState(parser: TokenParser(tokens))

        // IDL is split into three distinct sections: control, metadata and shapes
        var model = try parseControlSection(state)
        model["metadata"] = try parseMetadataSection(state)
        model["shapes"] = try parserShapesSection(state)

        let data = try JSONSerialization.data(withJSONObject: model, options: [])
        print(String(data: data, encoding: .utf8)!)
        return try Smithy().decodeAST(from: data)
    }
    
    /// parse control section of IDL
    func parseControlSection(_ state: ParserState) throws -> [String: Any] {
        let model: [String: Any] = ["smithy": "1.0"]
        while !state.parser.reachedEnd() {
            state.parser.skip(while: .newline)
            let token = try state.parser.token()
            if case .token(let string) = token {
                if string == "$version" {
                    try state.parser.advance()
                    // currently we support version "1.0"
                    try state.parser.expect(.string("1.0"))
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
    func parseMetadataSection(_ state: ParserState) throws -> [String: Any] {
        var metaData: [String: Any] = [:]
        while !state.parser.reachedEnd() {
            state.parser.skip(while: .newline)
            let token = try state.parser.token()
            if case .token(let string) = token {
                if string == "metadata" {
                    try state.parser.advance()
                    let token = try state.parser.nextToken()
                    let string: String
                    switch token {
                    case .string(let text):
                        string = text
                    case .token(let token):
                        string = String(token)
                    default:
                        throw SmithyParserError.badlyDefinedMetadata
                    }
                    try state.parser.expect(.grammar("="))
                    let value = try parseValue(state)
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
    func parserShapesSection(_ state: ParserState) throws -> [Substring: Any] {
        var modelShapes: [Substring: Any] = [:]
        var traits: [Substring: Any] = [:]

        while !state.parser.reachedEnd() {
            let token = try state.parser.nextToken()
            if case .token(let string) = token {
                if string == "namespace" {
                    // namespace
                    if traits.count > 0 {
                        throw SmithyParserError.unattachedTraits
                    }
                    let token = try state.parser.nextToken()
                    guard case .token(let name) = token else { throw SmithyParserError.missingNamespace }
                    guard modelShapes["shapes"] == nil else { throw SmithyParserError.shapesDefinedTooSoon }
                    guard state.namespace == nil else { throw SmithyParserError.namespaceAlreadyDefined }
                    state.namespace = name
                } else if string == "use" {
                    if traits.count > 0 {
                        throw SmithyParserError.unattachedTraits
                    }
                    guard case .token(let name) = token else { throw SmithyParserError.missingShapeId }
                    guard modelShapes["shapes"] == nil else { throw SmithyParserError.shapesDefinedTooSoon }
                    let shapeId = ShapeId(rawValue: String(name))
                    state.use[shapeId.shapeName] = shapeId
                } else if string == "metadata" {
                    // unexpected metadata. Should have already been read
                    throw SmithyParserError.unexpectedToken(token)
                } else if string.first == "@" {
                    // if trait
                    let traitName = string.dropFirst()
                    let trait = try parseTrait(state)
                    traits[fullTraitName(traitName, state: state)] = trait
                } else if string == "apply" {
                    _ = try parseApply(state, shapes: &modelShapes)
                } else {
                    // must be a shape
                    let token = try state.parser.nextToken()
                    guard case .token(let name) = token else { throw SmithyParserError.unexpectedToken(token) }
                    let shapeName = (state.namespace != nil ? "\(state.namespace!)#\(name)" : name)
                    var shape = try parseShape(state, type: string)
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
    func parseShape(_ state: ParserState, type: Substring) throws -> [Substring: Any] {
        var shape: [Substring: Any] = ["type": type]
        var traits: [Substring: Any] = [:]
        guard !state.parser.reachedEnd() else { return shape }
        let next = try state.parser.nextToken()
        guard next != .newline else { return shape }
        guard next == .grammar("{") else { throw SmithyParserError.unexpectedToken(next) }
        
        var members: [Substring: Any] = [:]
        
        while !state.parser.reachedEnd() {
            let token = try state.parser.nextToken()
            if case .token(let string) = token {
                if string.first == "@" {
                    // if trait
                    let traitName = string.dropFirst()
                    let trait = try parseTrait(state)
                    traits[fullTraitName(traitName, state: state)] = trait
                } else {
                    // assume token is a shape name
                    try state.parser.expect(.grammar(":"))
                    let value = try parseValue(state)
                    if traits.count > 0,
                       var dictionary = value as? [String: Any],
                       dictionary["target"] != nil {
                        dictionary["traits"] = traits
                        members[string] = dictionary
                    } else {
                        members[string] = value
                    }
                    traits = [:]
                    if try endCollection(&state.parser, endToken: .grammar("}")) {
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
    
    /// parse a value. This could be a string, number, array, dictionary or shape id
    func parseValue(_ state: ParserState) throws -> Any {
        let token = try state.parser.nextToken()
        switch token {
        case .string(let string):
            return string
        case .number(let number):
            return number
        case .grammar("{"):
            return try parseDictionary(state)
        case .grammar("["):
            return try parseArray(state)
        case .token(let token):
            return ["target": fullShapeName(token, state: state).rawValue]
        default:
            throw SmithyParserError.unexpectedToken(token)

        }
    }
    
    func parseMappedValues(_ state: ParserState, endToken: Tokenizer.Token) throws -> [Substring: Any] {
        var dictionary: [Substring: Any] = [:]
        while !state.parser.reachedEnd() {
            state.parser.skip(while: .newline)
            let token = try state.parser.nextToken()
            if token == endToken {
                break
            } else if case .token(let key) = token {
                try state.parser.expect(.grammar(":"))
                let value = try parseValue(state)
                dictionary[key] = value
                if try endCollection(&state.parser, endToken: endToken) {
                    break
                }
            } else {
                throw SmithyParserError.unexpectedToken(token)
            }
        }
        return dictionary
    }
    
    func parseParameters(_ state: ParserState) throws -> Any {
        state.parser.skip(while: .newline)
        if case .token = try state.parser.token() {
            return try parseMappedValues(state, endToken: .grammar(")"))
        } else {
            let value = try parseValue(state)
            try state.parser.expect(.grammar(")"))
            return value
        }
    }
    
    func parseDictionary(_ state: ParserState) throws -> [Substring: Any] {
        return try parseMappedValues(state, endToken: .grammar("}"))
    }

    func parseArray(_ state: ParserState) throws -> [Any] {
        var array: [Any] = []
        while !state.parser.reachedEnd() {
            state.parser.skip(while: .newline)
            let token = try state.parser.token()
            if token == .grammar("]") {
                try state.parser.advance()
                break
            } else {
                let value = try parseValue(state)
                array.append(value)
                if try endCollection(&state.parser, endToken: .grammar("]")) {
                    break
                }
            }
        }
        return array
    }

    func parseTrait(_ state: ParserState) throws -> Any {
        let token = try state.parser.token()
        let value: Any
        if token == .newline {
            value = [:]
        } else if token == .grammar("(") {
            try state.parser.advance()
            value = try parseParameters(state)
        } else if case .token = token {
            value = [:]
        } else {
            throw SmithyParserError.unexpectedToken(token)
        }
        if state.parser.reachedEnd() {
            return value
        }
        let token2 = try state.parser.token()
        switch token2 {
        case .newline:
            try state.parser.advance()
        case .token:
            break
        default:
            throw SmithyParserError.unexpectedToken(token2)
        }
        return value
    }
    
    func parseApply(_ state: ParserState, shapes: inout [Substring: Any]) throws -> (Substring, Substring, Any) {
        let shapeToken = try state.parser.nextToken()
        guard case .token(let shape) = shapeToken else {throw SmithyParserError.unexpectedToken(shapeToken) }
        let traitToken = try state.parser.nextToken()
        guard case .token(let traitName) = traitToken else {throw SmithyParserError.unexpectedToken(traitToken) }
        guard traitName.first == "@" else {throw SmithyParserError.unexpectedToken(traitToken) }
        let fullTraitName = self.fullTraitName(traitName.dropFirst(), state: state)
        let trait = try parseTrait(state)
    
        return (shape, fullTraitName, trait)
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
    
    /// Return full shape name given name. If name has no namespace search for shape in available namespaces
    /// otherwise prefix with current namespace
    func fullShapeName(_ name: Substring, state: ParserState) -> ShapeId {
        // if name has no namespace check if it is a prelude object
        let shapeId = ShapeId(rawValue: name)
        if shapeId.namespace == nil {
            let smithyShapeId = ShapeId(namespace: "smithy.api", shapeName: name)
            if Self.preludeShapes[smithyShapeId] != nil {
                return smithyShapeId
            } else if let namespace = state.namespace {
                return ShapeId(namespace: namespace, shapeName: name)
            }
        }
        return shapeId
    }
    
    /// Return full trait name. If name has no namespace search for shape in available namespaces
    /// otherwise prefix with current namespace
    func fullTraitName(_ name: Substring, state: ParserState) -> Substring {
        // if name has no namespace check if it is a prelude object
        let traitId = ShapeId(rawValue: name)
        if traitId.namespace == nil {
            if TraitList.possibleTraits["smithy.api#\(name)"] != nil {
                return "smithy.api#\(name)"
            } else if let namespace = state.namespace {
                return "\(namespace)#\(name)"
            }
        }
        return name
    }
    
    /// Parser state passed around during parsing of Smithy.
    /// Needs to be a class so state is passed up to calling functions
    class ParserState {
        var parser: TokenParser
        var namespace: Substring?
        var use: [String: ShapeId]
        
        init(parser: TokenParser) {
            self.parser = parser
            self.namespace = nil
            self.use = [:]
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
