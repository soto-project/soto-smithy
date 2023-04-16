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

extension Smithy {
    /// Parse IDL to create Smithy Model
    /// - Parameter string: IDL
    /// - Throws: `ParserError`
    /// - Returns: Smithy Model
    public func parse(_ string: String) throws -> Model {
        let state = try ParserState(string)

        var model: [String: Any]
        do {
            // IDL is split into three distinct sections: control, metadata and shapes
            model = try self.parseControlSection(state)
            model["metadata"] = try self.parseMetadataSection(state)
            model["shapes"] = try self.parserShapesSection(state)
        } catch let error as ParserError {
            // if returned error without context attempt to fill in context from current parser state
            if error.context == nil {
                try? state.parser.retreat()
                guard let token = try? state.parser.token() else { throw error }
                throw ParserError(error.reason, context: SmithyErrorContext(state.text, position: token.position))
            } else {
                throw error
            }
        }

        let data = try JSONSerialization.data(withJSONObject: model, options: [])
        return try Smithy().decodeAST(from: data)
    }

    /// parse control section of IDL
    func parseControlSection(_ state: ParserState) throws -> [String: Any] {
        var model: [String: Any] = ["smithy": "1.0"]
        while !state.parser.reachedEnd() {
            state.parser.skip(while: .newline)
            let token = try state.parser.token()
            if case .token(let string) = token.type {
                if string == "$version" {
                    try state.parser.advance()
                    try state.parser.expect(.grammar(":"))
                    let version = try self.expectString(state)
                    model["smithy"] = version
                } else {
                    break
                }
            } else {
                throw ParserError.unexpectedToken(token)
            }
        }
        return model
    }

    /// Parse metadata section of IDL
    /// - Returns: Metadata dictionary
    func parseMetadataSection(_ state: ParserState) throws -> [String: Any] {
        state.parsingMetadata = true
        defer { state.parsingMetadata = false }

        var metaData: [String: Any] = [:]
        while !state.parser.reachedEnd() {
            state.parser.skip(while: .newline)
            let token = try state.parser.token()
            if case .token(let string) = token.type {
                if string == "metadata" {
                    try state.parser.advance()
                    let token = try state.parser.nextToken()
                    let string: String
                    switch token.type {
                    case .string(let text):
                        string = text
                    case .token(let token):
                        string = String(token)
                    default:
                        throw ParserError("Invalid metadata value")
                    }
                    try state.parser.expect(.grammar("="))
                    let value = try parseValue(state)
                    metaData[string] = value
                } else {
                    // must have reached end of metadata section
                    break
                }
            } else {
                throw ParserError.unexpectedToken(token)
            }
        }
        return metaData
    }

    /// parse shapes section of IDL
    /// - Returns: Shapes as a dictionary
    func parserShapesSection(_ state: ParserState) throws -> [String: Any] {
        var modelShapes: [String: Any] = [:]
        var traits: [String: Any] = [:]
        var traitPosition: Int?

        while !state.parser.reachedEnd() {
            let token = try state.parser.nextToken()
            if case .token(let string) = token.type {
                if string == "namespace" {
                    // namespace
                    if traits.count > 0 {
                        if let position = traitPosition { state.parser.position = position }
                        throw ParserError.unattachedTraits()
                    }
                    let token = try state.parser.nextToken()
                    guard case .token(let name) = token.type else { throw ParserError("Expected namespace name", state: state) }
                    guard state.namespace == nil else { throw ParserError("File contains two namespace definitions", state: state) }
                    guard modelShapes.count == 0 else { throw ParserError("Shapes defined before namespace has been set", state: state) }
                    state.namespace = name
                    // use shapeId
                } else if string == "use" {
                    if traits.count > 0 {
                        if let position = traitPosition { state.parser.position = position }
                        throw ParserError.unattachedTraits()
                    }
                    let token = try state.parser.nextToken()
                    guard case .token(let name) = token.type else { throw ParserError("Expected shape id after \"use\" statement", state: state) }
                    guard modelShapes.count == 0 else { throw ParserError("Shapes defined before \"use\" statement", state: state) }
                    let shapeId = ShapeId(rawValue: String(name))
                    state.use[shapeId.shapeName] = shapeId
                    // unexpected metadata. Should have already been read
                } else if string == "metadata" {
                    throw ParserError.unexpectedToken(token)
                    // if trait
                } else if string.first == "@" {
                    // record position of first trait
                    if traitPosition == nil {
                        traitPosition = state.parser.position
                    }
                    let traitName = string.dropFirst()
                    let trait = try parseTrait(state)
                    traits[fullTraitName(traitName, state: state).rawValue] = trait
                } else if string == "apply" {
                    let apply = try parseApply(state, shapes: modelShapes)
                    let shapeId = fullShapeName(apply.shape, state: state)
                    guard modelShapes[shapeId.rawValue] != nil else { throw ParserError("Apply referencing non-existent Shape ID", state: state) }
                    let mergeDictionary: [String: Any] = [shapeId.rawValue: ["traits": [apply.trait.rawValue: apply.value]]]
                    modelShapes = mergeDictionaries(modelShapes, mergeDictionary)
                    // otherwise must be a shape
                } else {
                    let token = try state.parser.nextToken()
                    guard case .token(let name) = token.type else { throw ParserError.unexpectedToken(token) }
                    let shapeId = ShapeId(namespace: state.namespace, shapeName: name)
                    var shape = try parseShape(state, type: string)
                    // attached already parsed traits and clear trait map for next shape
                    if traits.count > 0 {
                        shape["traits"] = traits
                    }
                    traits = [:]
                    traitPosition = nil
                    modelShapes[shapeId.rawValue] = shape
                }
            } else if case .documentationComment(let comment) = token.type {
                traits["smithy.api#documentation"] = comment
            } else if token == .newline {
                if traits.count > 0 {
                    if let position = traitPosition { state.parser.position = position }
                    throw ParserError.unattachedTraits()
                }
            } else {
                throw ParserError.unexpectedToken(token)
            }
        }
        return modelShapes
    }

    /// Parse shape from tokenized smithy
    func parseShape(_ state: ParserState, type: Substring) throws -> [String: Any] {
        var shape: [String: Any] = ["type": type]
        var traits: [String: Any] = [:]
        guard !state.parser.reachedEnd() else { return shape }
        let next = try state.parser.nextToken()
        guard next != .newline else { return shape }
        guard next == .grammar("{") else { throw ParserError.unexpectedToken(next) }

        var members: [Substring: Any] = [:]
        var traitPosition: Int?

        if type == "enum" || type == "intEnum" {
            return try self.parseEnumMembers(state, shape: shape)
        }

        while !state.parser.reachedEnd() {
            let token = try state.parser.nextToken()
            if case .token(let string) = token.type {
                // if trait
                if string.first == "@" {
                    // record position of first trait
                    if traitPosition == nil {
                        traitPosition = state.parser.position
                    }
                    let traitName = string.dropFirst()
                    let trait = try parseTrait(state)
                    traits[fullTraitName(traitName, state: state).rawValue] = trait
                    // otherwise assume token is a shape name
                } else {
                    try state.parser.expect(.grammar(":"))
                    let value = try parseValue(state)
                    if traits.count > 0,
                       var dictionary = value as? [String: Any],
                       dictionary["target"] != nil
                    {
                        dictionary["traits"] = traits
                        members[string] = dictionary
                    } else {
                        members[string] = value
                    }
                    traits = [:]
                    traitPosition = nil
                    if try endCollection(state, endToken: .grammar("}")) {
                        break
                    }
                }
            } else if case .documentationComment(let comment) = token.type {
                traits["smithy.api#documentation"] = comment
            } else if token == .newline {
                if traits.count > 0 {
                    if let position = traitPosition { state.parser.position = position }
                    throw ParserError.unattachedTraits()
                }
            } else if token == .grammar("}") {
                if traits.count > 0 {
                    if let position = traitPosition { state.parser.position = position }
                    throw ParserError.unattachedTraits()
                }
                // closed curly bracket so we are done
                break
            } else {
                throw ParserError.unexpectedToken(token)
            }
        }

        if type == "union" || type == "structure" {
            shape["members"] = members
        } else {
            for entry in members {
                shape[String(entry.key)] = entry.value
            }
        }
        return shape
    }

    /// Parse enum shape from tokenized smithy
    func parseEnumMembers(_ state: ParserState, shape: [String: Any]) throws -> [String: Any] {
        var shape: [String: Any] = shape
        var traits: [String: Any] = [:]
        var members: [Substring: Any] = [:]
        var traitPosition: Int?

        while !state.parser.reachedEnd() {
            let token = try state.parser.nextToken()
            if case .token(let string) = token.type {
                // if trait
                if string.first == "@" {
                    // record position of first trait
                    if traitPosition == nil {
                        traitPosition = state.parser.position
                    }
                    let traitName = string.dropFirst()
                    let trait = try parseTrait(state)
                    traits[fullTraitName(traitName, state: state).rawValue] = trait
                    // otherwise assume token is a shape name
                } else {
                    let nextToken = try state.parser.nextToken()
                    if nextToken == .grammar("=") {
                        let value = try self.parseValue(state)
                        traits["smithy.api#enumValue"] = value
                    } else {
                        try state.parser.retreat()
                    }

                    var dictionary: [String: Any] = ["target": "smithy.api#Unit"]
                    if traits.count > 0 {
                        dictionary["traits"] = traits
                        members[string] = dictionary
                    } else {
                        members[string] = dictionary
                    }
                    traits = [:]
                    traitPosition = nil
                    if try endCollection(state, endToken: .grammar("}")) {
                        break
                    }
                }
            } else if case .documentationComment(let comment) = token.type {
                traits["smithy.api#documentation"] = comment
            } else if token == .newline {
                if traits.count > 0 {
                    if let position = traitPosition { state.parser.position = position }
                    throw ParserError.unattachedTraits()
                }
            } else if token == .grammar("}") {
                if traits.count > 0 {
                    if let position = traitPosition { state.parser.position = position }
                    throw ParserError.unattachedTraits()
                }
                // closed curly bracket so we are done
                break
            } else {
                throw ParserError.unexpectedToken(token)
            }
        }

        shape["members"] = members
        return shape
    }

    /// parse a value. This could be a string, number, array, dictionary or shape id
    func parseValue(_ state: ParserState) throws -> Any {
        let token = try state.parser.nextToken()
        switch token.type {
        case .string(let string):
            return string
        case .number(let number):
            return number
        case .grammar("{"):
            return try self.parseDictionary(state)
        case .grammar("["):
            return try self.parseArray(state)
        case .token(let string):
            // is it a boolean
            if let boolean = Bool(String(string)) { return boolean }
            // Tokens ie strings without speech marks are treated differently based on what we are parsing
            // A token inside metadata can only be a true/false boolean. If we are parsing a trait then convert
            // it to a the full shape name for the string. Otherwise we are in a shape and we should convert this
            // to a dictionary with a single value "target" which is the full shape name
            if state.parsingMetadata {
                throw ParserError.unexpectedToken(token)
            } else if state.parsingTrait {
                return self.fullShapeName(string, state: state).rawValue
            } else {
                return ["target": self.fullShapeName(string, state: state).rawValue]
            }
        default:
            throw ParserError.unexpectedToken(token)
        }
    }

    /// expect to parse a string
    func expectString(_ state: ParserState) throws -> String {
        let token = try state.parser.nextToken()
        if case .string(let string) = token.type {
            return string
        }
        throw ParserError.unexpectedToken(token)
    }

    /// expect to parse a number
    func expectNumber(_ state: ParserState) throws -> Double {
        let token = try state.parser.nextToken()
        if case .number(let number) = token.type {
            return number
        }
        throw ParserError.unexpectedToken(token)
    }

    func parseMappedValues(_ state: ParserState, endToken: Tokenizer.Token.TokenType) throws -> [Substring: Any] {
        var dictionary: [Substring: Any] = [:]
        while !state.parser.reachedEnd() {
            state.parser.skip(while: .newline)
            let token = try state.parser.nextToken()
            if token.type == endToken {
                break
            } else if case .token(let key) = token.type {
                try state.parser.expect(.grammar(":"))
                let value = try parseValue(state)
                dictionary[key] = value
                if try endCollection(state, endToken: endToken) {
                    break
                }
                // dictionaries can have strings for keys when loading metadata
            } else if case .string(let key) = token.type /* , state.loadingMetadata */ {
                try state.parser.expect(.grammar(":"))
                let value = try parseValue(state)
                dictionary[Substring(key)] = value
                if try endCollection(state, endToken: endToken) {
                    break
                }
            } else {
                throw ParserError.unexpectedToken(token)
            }
        }
        return dictionary
    }

    func parseParameters(_ state: ParserState) throws -> Any {
        state.parser.skip(while: .newline)
        if case .token = try state.parser.token().type {
            return try parseMappedValues(state, endToken: .grammar(")"))
        } else {
            let value = try parseValue(state)
            try state.parser.expect(.grammar(")"))
            return value
        }
    }

    func parseDictionary(_ state: ParserState) throws -> [Substring: Any] {
        return try self.parseMappedValues(state, endToken: .grammar("}"))
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
                if try self.endCollection(state, endToken: .grammar("]")) {
                    break
                }
            }
        }
        return array
    }

    func parseTrait(_ state: ParserState) throws -> Any {
        state.parsingTrait = true
        defer { state.parsingTrait = false }

        let token = try state.parser.token()
        let value: Any
        if token == .newline {
            value = [String: Any]()
        } else if token == .grammar("(") {
            try state.parser.advance()
            value = try self.parseParameters(state)
        } else if case .token = token.type {
            value = [String: Any]()
        } else {
            throw ParserError.unexpectedToken(token)
        }
        if state.parser.reachedEnd() {
            return value
        }
        let token2 = try state.parser.token()
        switch token2.type {
        case .newline:
            try state.parser.advance()
        case .token:
            break
        default:
            throw ParserError.unexpectedToken(token2)
        }
        return value
    }

    func parseApply(_ state: ParserState, shapes: [String: Any]) throws -> (shape: Substring, trait: ShapeId, value: Any) {
        let shapeToken = try state.parser.nextToken()
        guard case .token(let shape) = shapeToken.type else { throw ParserError.unexpectedToken(shapeToken) }
        let traitToken = try state.parser.nextToken()
        guard case .token(let traitName) = traitToken.type else { throw ParserError.unexpectedToken(traitToken) }
        guard traitName.first == "@" else { throw ParserError.unexpectedToken(traitToken) }
        let fullTraitName = self.fullTraitName(traitName.dropFirst(), state: state)
        let trait = try parseTrait(state)

        return (shape, fullTraitName, trait)
    }

    func endCollection(_ state: ParserState, endToken: Tokenizer.Token.TokenType) throws -> Bool {
        let nextToken = try state.parser.nextToken()
        if nextToken.type == endToken {
            return true
        } else if nextToken == .grammar(",") || nextToken == .newline {
            return false
        } /* else if nextToken == .newline {
             state.parser.skip(while: .newline)
             try state.parser.expect(endToken)
             return true
         } */ else {
            throw ParserError.unexpectedToken(nextToken)
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
            } else if let shapeId = state.use[String(name)] {
                return shapeId
            } else if let namespace = state.namespace {
                return ShapeId(namespace: namespace, shapeName: name)
            }
        }
        return shapeId
    }

    /// Return full trait name. If name has no namespace search for shape in available namespaces
    /// otherwise prefix with current namespace
    func fullTraitName(_ name: Substring, state: ParserState) -> ShapeId {
        // if name has no namespace check if it is a prelude object
        let traitId = ShapeId(rawValue: name)
        if traitId.namespace == nil {
            let smithyShapeId = ShapeId(namespace: "smithy.api", shapeName: name)
            if TraitList.possibleTraits[smithyShapeId] != nil {
                return smithyShapeId
            } else if let shapeId = state.use[String(name)] {
                return shapeId
            } else if let namespace = state.namespace {
                return ShapeId(namespace: namespace, shapeName: name)
            }
        }
        return traitId
    }

    /// Used by Apply when applying traits to already defined shapes
    func mergeDictionaries<S: StringProtocol>(_ lhs: [S: Any], _ rhs: [S: Any]) -> [S: Any] {
        return lhs.merging(rhs) { lhs, rhs in
            if let lhsDict = lhs as? [String: Any], let rhsDict = rhs as? [String: Any] {
                return mergeDictionaries(lhsDict, rhsDict)
            } else if let lhsDict = lhs as? [Substring: Any], let rhsDict = rhs as? [Substring: Any] {
                return mergeDictionaries(lhsDict, rhsDict)
            }
            return lhs
        }
    }

    /// Parser state passed around during parsing of Smithy.
    /// Needs to be a class so state is passed up to calling functions
    class ParserState {
        var text: String
        var parser: TokenParser
        var namespace: Substring?
        var use: [String: ShapeId]
        var parsingMetadata: Bool
        var parsingTrait: Bool

        init(_ string: String) throws {
            self.text = string
            let tokens = try Tokenizer().tokenize(string)
            self.parser = TokenParser(tokens)
            self.namespace = nil
            self.use = [:]
            self.parsingMetadata = false
            self.parsingTrait = false
        }
    }

    /// Parser error
    public struct ParserError: SmithyError {
        public let reason: String
        public let context: SmithyErrorContext?

        init(_ reason: String, context: SmithyErrorContext? = nil) {
            self.reason = reason
            self.context = context
        }

        init(_ reason: String, state: ParserState) {
            self.reason = reason
            do {
                var parser = state.parser
                if parser.reachedEnd() {
                    try parser.retreat()
                }
                self.context = SmithyErrorContext(state.text, position: try parser.token().position)
            } catch {
                self.context = nil
            }
        }

        static func unexpectedToken(_ token: Tokenizer.Token) -> Self { return .init("Unexpected token \(token)") }
        static var overflow: Self { return .init("File ended unexpectedly") }
        static func unattachedTraits() -> Self { return .init("Traits not attached to a shape") }
    }
}
