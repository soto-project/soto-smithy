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

/// Parse Selector IDL https://awslabs.github.io/smithy/1.0/spec/core/selectors.html
/// Currently supports a very limited selection of Selectors: shape type and has trait
enum SelectorParser {
    static let tokenizer = Tokenizer(
        tokenChars: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@.#$_-*",
        tokenStartChars: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ*",
        grammarChars: "()|[]>:,"
    )
    /// parse Smithy selector IDL string
    /// - Parameter string: Selector IDL to parse
    /// - Throws: Smithy.UnrecognisedSelectorError
    /// - Returns: Selector generated from IDL
    static func parse(from string: String) throws -> Selector {
        do {
            let tokens = try tokenizer.tokenize(string)
            var parser = TokenParser(tokens)

            if let selector = try parseSelectors(parser: &parser) {
                return selector
            }
        } catch {}
        throw Smithy.UnrecognisedSelectorError(value: string)
    }

    static func parseSelectors(until: Tokenizer.Token.TokenType? = nil, parser: inout TokenParser) throws -> Selector? {
        var selectors: [Selector] = []

        while !parser.reachedEnd() {
            parser.skip(while: .newline)
            let token = try parser.token()
            guard token.type != until else {
                try parser.advance()
                break
            }

            guard let selector = try parseSelector(&parser) else { return nil }
            selectors.append(selector)
        }

        switch selectors.count {
        case 0:
            return nil
        case 1:
            return selectors[0]
        default:
            return AndSelector(selectors)
        }
    }

    static func parseIsSelectors(_ parser: inout TokenParser) throws -> Selector? {
        var selectors: [Selector] = []

        while !parser.reachedEnd() {
            parser.skip(while: .newline)

            guard let selector = try parseSelector(&parser) else { return nil }
            selectors.append(selector)

            let token = try parser.token()
            guard token.type != .grammar(")") else {
                try parser.advance()
                break
            }
            try parser.expect(.grammar(","))
        }

        switch selectors.count {
        case 0:
            return nil
        case 1:
            return selectors[0]
        default:
            return OrSelector(selectors)
        }
    }

    static func parseSelector(_ parser: inout TokenParser) throws -> Selector? {
        let token = try parser.nextToken()
        switch token.type {
        case .token(let text):
            return self.typeSelector(from: text)

        case .grammar("["):
            return try self.parseAttribute(&parser)

        case .grammar(":"):
            let functionTrait = try parser.nextToken()
            switch functionTrait.type {
            case .token("not"):
                try parser.expect(.grammar("("))
                guard let notSelector = try parseSelectors(until: .grammar(")"), parser: &parser) else { return nil }
                return NotSelector(notSelector)
            case .token("is"):
                try parser.expect(.grammar("("))
                return try self.parseIsSelectors(&parser)
            default:
                return nil
            }

        default:
            return nil
        }
    }

    static func parseAttribute(_ parser: inout TokenParser) throws -> Selector? {
        let token = try parser.nextToken()
        switch token.type {
        case .token("trait"):
            return try self.parseTraitAttribute(&parser)
        default:
            return nil
        }
    }

    static func parseTraitAttribute(_ parser: inout TokenParser) throws -> Selector? {
        try parser.expect(.grammar("|"))
        let traitToken = try parser.nextToken()
        guard case .token(let name) = traitToken.type else { return nil }
        let selector: Selector? = self.traitSelector(from: name)

        // parse until attribute end
        while try parser.nextToken() != .grammar("]") {}
        return selector
    }

    /// get TypeSelector from string
    static func typeSelector(from string: Substring) -> Selector? {
        switch string {
        case "*": return AllSelector()
        case "number": return NumberSelector()
        case "simpleType": return SimpleTypeSelector()
        case "collection": return CollectionSelector()
        default:
            let shape = Model.possibleShapes[String(string)]
            return shape?.typeSelector
        }
    }

    /// get TraitSelector from string
    static func traitSelector(from string: Substring) -> Selector? {
        var traitShapeId = ShapeId(rawValue: string)
        if traitShapeId.namespace == nil {
            traitShapeId = ShapeId(namespace: "smithy.api", shapeName: traitShapeId.shapeName)
        }
        if let trait = TraitList.possibleTraits[traitShapeId] {
            return trait.traitSelector
        } else {
            return TraitNameSelector(traitShapeId)
        }
    }
}
