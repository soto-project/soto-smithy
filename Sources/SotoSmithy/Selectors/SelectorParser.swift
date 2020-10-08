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
    static func parse(from string: String) throws -> Selector {
        var selectors: [Selector] = []
        var stringPosition: String.Index = string.startIndex
        while let next = nextSelector(string, startIndex: stringPosition) {
            guard let selector = typeSelector(from: next) else { throw Smithy.UnrecognisedSelectorError(value: String(next)) }
            selectors.append(selector)
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

    static func typeSelector(from string: Substring) -> Selector? {
        //for shape in 
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
        case "blob": return TypeSelector<BlobShape>()
        case "boolean": return TypeSelector<BooleanShape>()
        case "document": return TypeSelector<DocumentShape>()
        case "string": return TypeSelector<StringShape>()
        case "byte": return TypeSelector<ByteShape>()
        case "short": return TypeSelector<ShortShape>()
        case "integer": return TypeSelector<IntegerShape>()
        case "long": return TypeSelector<LongShape>()
        case "float": return TypeSelector<FloatShape>()
        case "double": return TypeSelector<DoubleShape>()
        case "bigDecimal": return TypeSelector<BigDecimalShape>()
        case "bigInteger": return TypeSelector<BigIntegerShape>()
        case "timestamp": return TypeSelector<TimestampShape>()
        case "list": return TypeSelector<ListShape>()
        case "set": return TypeSelector<SetShape>()
        case "map": return TypeSelector<MapShape>()
        case "structure": return TypeSelector<StructureShape>()
        case "union": return TypeSelector<UnionShape>()
        case "service": return TypeSelector<ServiceShape>()
        case "operation": return TypeSelector<OperationShape>()
        case "resource": return TypeSelector<ResourceShape>()
        case "member": return TypeSelector<MemberShape>()
        default: return nil
        }
    }
}
