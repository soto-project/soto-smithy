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

@testable import SotoSmithy
import XCTest

class SelectorTests: XCTestCase {
    func testShapeType() throws {
        let json = """
        {
            "smithy": "1.0",
            "shapes": {
                "smithy.example#Name": { "type": "string" },
                "smithy.example#Age": { "type": "integer" },
                "smithy.example#Street": { "type": "string" },
                "smithy.example#Town": { "type": "string" },
                "smithy.example#Country": { "type": "string" },
                "smithy.example#Union": {
                    "type": "union",
                    "members" : {
                        "name": { "target": "smithy.example#Name" },
                        "age": { "target": "smithy.example#Age" }
                    }
                }
            }
        }
        """
        let model = try Smithy().decodeAST(from: Data(json.utf8))
        try model.validate()
        XCTAssertEqual(try model.select(from: "string").count, 5) // this includes the prelude string type
        XCTAssertEqual(try model.select(from: "union").count, 1)
        XCTAssertEqual(try model.select(from: "integer").count, 3) // this includes the prelude integer types
    }

    func testTraitType() throws {
        let json = """
        {
            "smithy": "1.0",
            "shapes": {
                "smithy.example#Name": {
                    "type": "string",
                    "traits": { "smithy.api#deprecated": {} }
                },
                "smithy.example#Age": { "type": "integer" },
            }
        }
        """
        let model = try Smithy().decodeAST(from: Data(json.utf8))
        try model.validate()
        XCTAssertEqual(try model.select(from: "[trait|deprecated]").count, 1)
    }

    func testCustomTraitType() throws {
        let json = """
        {
            "smithy": "1.0",
            "shapes": {
                "smithy.example#Name": {
                    "type": "string",
                    "traits": { "smithy.example#StringDimensions": {} }
                },
                "smithy.example#StringDimensions": {
                    "type": "structure",
                    "traits": { "smithy.api#trait": { "selector": "string" } }
                }
            }
        }
        """
        let model = try Smithy().decodeAST(from: Data(json.utf8))
        try model.validate()
        XCTAssertEqual(try model.select(from: "[trait|smithy.example#StringDimensions]").count, 1)
    }

    func testShapeSelectorParsing() throws {
        _ = Smithy()
        let selector = try SelectorParser.parse(from: "operation")
        XCTAssertTrue(selector is TypeSelector<OperationShape>)
        let selector2 = try SelectorParser.parse(from: "number")
        XCTAssertTrue(selector2 is NumberSelector)
    }

    func testTraitSelectorParsing() throws {
        _ = Smithy()
        let selector = try SelectorParser.parse(from: "[trait|deprecated]")
        XCTAssertTrue(selector is TraitSelector<DeprecatedTrait>)
    }

    func testAndSelectorParsing() throws {
        _ = Smithy()
        let selector = try SelectorParser.parse(from: "service [trait|xmlNamespace]")
        let andSelector = try XCTUnwrap(selector as? AndSelector)
        XCTAssertTrue(andSelector.selectors[0] is TypeSelector<ServiceShape>)
        XCTAssertTrue(andSelector.selectors[1] is TraitSelector<XmlNamespaceTrait>)
    }

    func testNotSelectorParsing() throws {
        _ = Smithy()
        let selector = try SelectorParser.parse(from: ":not(structure)")
        let notSelector = try XCTUnwrap(selector as? NotSelector)
        XCTAssertTrue(notSelector.selector is TypeSelector<StructureShape>)
    }

    func testNotAndSelectorParsing() throws {
        _ = Smithy()
        let selector = try SelectorParser.parse(from: ":not(service [trait|xmlNamespace])")
        let notSelector = try XCTUnwrap(selector as? NotSelector)
        let andSelector = try XCTUnwrap(notSelector.selector as? AndSelector)
        XCTAssertTrue(andSelector.selectors[0] is TypeSelector<ServiceShape>)
        XCTAssertTrue(andSelector.selectors[1] is TraitSelector<XmlNamespaceTrait>)
    }
}
