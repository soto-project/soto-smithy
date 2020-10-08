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

enum SelectorParser {
    // parse Smithy selector IDL string
    static func parse(from string: String) throws -> Selector {
        var selectors: [Selector] = []
        var stringPosition: String.Index = string.startIndex
        while let next = nextSelector(string, startIndex: stringPosition) {
            let selector: Selector?
            if next.prefix(6) == "[trait" {
                selector = traitSelector(from: next)
            } else {
                selector = typeSelector(from: String(next))
            }
            guard let selector2 = selector else { throw Smithy.UnrecognisedSelectorError(value: String(next)) }
            selectors.append(selector2)
            stringPosition = next.endIndex
        }
        switch selectors.count {
        case 0:
            throw Smithy.UnrecognisedSelectorError(value: string)
        case 1:
            return selectors[0]
        default:
            return AndSelector(selectors)
        }
    }

    /// Get next selector in a string
    static func nextSelector(_ string: String, startIndex: String.Index) -> Substring? {
        guard startIndex != string.endIndex else { return nil }
        var startIndex = startIndex
        // skip whitespace
        while string[startIndex].isWhitespace || string[startIndex].isNewline {
            startIndex = string.index(after: startIndex)
            // if reached end then return nothing
            guard startIndex != string.endIndex else { return nil }
        }

        var endIndex = startIndex
        while endIndex != string.endIndex, !string[endIndex].isWhitespace, !string[endIndex].isNewline {
            endIndex = string.index(after: endIndex)
        }

        return string[startIndex..<endIndex]
    }

    /// get TypeSelector from string
    static func typeSelector(from string: String) -> Selector? {
        switch string {
        case "*": return AllSelector()
        case "number": return NumberSelector()
        case "simpleType":
            return OrSelector(
                TypeSelector<BlobShape>(),
                TypeSelector<BooleanShape>(),
                TypeSelector<StringShape>(),
                NumberSelector(),
                TypeSelector<TimestampShape>(),
                TypeSelector<DocumentShape>()
            )
        case "collection": return OrSelector(TypeSelector<ListShape>(), TypeSelector<SetShape>())
        default:
            let shape = Model.possibleShapes[string]
            return shape?.typeSelector
        }
    }

    /// get TraitSelector from string
    static func traitSelector(from string: Substring) -> Selector? {
        let traitStart = string.dropFirst(7) // drop [trait|
        guard let traitEnd = traitStart.firstIndex(where: { $0 == "|" || $0 == "]" }) else { return nil }
        var traitShapeId = ShapeId(rawValue: String(traitStart[traitStart.startIndex..<traitEnd]))
        if traitShapeId.namespace == nil {
            traitShapeId = ShapeId(namespace: "smithy.api", shapeName: traitShapeId.shapeName)
        }
        if let trait = TraitList.possibleTraits[traitShapeId.rawValue] {
            return trait.traitSelector
        } else {
            return TraitNameSelector(traitShapeId.rawValue)
        }
    }
}
