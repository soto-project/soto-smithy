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
        tokenChars: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@.#$_-:*",
        tokenStartChars: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ:*",
        grammarChars: "()|[]>"
    )
    /// parse Smithy selector IDL string
    /// - Parameter string: Selector IDL to parse
    /// - Throws: Smithy.UnrecognisedSelectorError
    /// - Returns: Selector generated from IDL
    static func parse(from string: String) throws -> Selector {
        let tokens = try tokenizer.tokenize(string)
        var parser = TokenParser(tokens)

        if let selector = try? parse(parser: &parser) {
            return selector
        }
        throw Smithy.UnrecognisedSelectorError(value: string)
    }

    static func parse(until: Tokenizer.Token.TokenType? = nil, parser: inout TokenParser) throws -> Selector? {
        var selectors: [Selector] = []

        while !parser.reachedEnd() {
            parser.skip(while: .newline)
            let token = try parser.nextToken()
            guard token.type != until else { break }

            var selector: Selector? = nil
            switch token.type {
            case .token(let text):
                switch text {
                case ":not":
                    try parser.expect(.grammar("("))
                    guard let notSelector = try parse(until: .grammar(")"), parser: &parser) else { return nil }
                    selector = NotSelector(notSelector)
                default:
                    selector = typeSelector(from: text)
                }
            case .grammar(let char):
                guard char == "[" else { break }
                selector = try parseAttribute(&parser)
            default:
                break
            }
            guard let selector2 = selector else { return nil }
            selectors.append(selector2)
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

    static func parseAttribute(_ parser: inout TokenParser) throws -> Selector? {
        let token = try parser.nextToken()
        switch token.type {
        case .token("trait"):
            return try parseTraitAttribute(&parser)
        default:
            return nil
        }
    }

    static func parseTraitAttribute(_ parser: inout TokenParser) throws -> Selector? {
        try parser.expect(.grammar("|"))
        let traitToken = try parser.nextToken()
        guard case .token(let name) = traitToken.type else { return nil }
        let selector: Selector? = traitSelector(from: name)

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
