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

class ParserTests: XCTestCase {
    func testShapeLoad() throws {
        let smithy = """
        namespace soto.example
        
        string MyString
        """
        let model = try Smithy().parse(smithy)
        XCTAssertNoThrow(try model.validate())
        XCTAssert(model.shape(for: "soto.example#MyString") is StringShape)
    }
    
    func testMetadataLoad() throws {
        let smithy = """
        namespace soto.example
        metadata "test" = "test string"
        string MyString
        """
        let model = try Smithy().parse(smithy)
        XCTAssertNoThrow(try model.validate())
        XCTAssertEqual(model.metadata?["test"] as? String, "test string")
    }
    func testListLoad() throws {
        let smithy = """
        namespace soto.example
        list MyList {
            member: String
        }
        """
        let model = try Smithy().parse(smithy)
        XCTAssertNoThrow(try model.validate())
        let shape = model.shape(for: "soto.example#MyList")
        XCTAssert(shape is ListShape)
        let list = try XCTUnwrap(shape as? ListShape)
        XCTAssertEqual(list.member.target, "smithy.api#String")
    }

    func testStructureLoad() throws {
        let smithy = """
        namespace soto.example
        structure MyStructure {
            testString: String,
            testInteger: Integer,
        }
        """
        let model = try Smithy().parse(smithy)
        XCTAssertNoThrow(try model.validate())
        let shape = model.shape(for: "soto.example#MyStructure")
        XCTAssert(shape is StructureShape)
        let structure = try XCTUnwrap(shape as? StructureShape)
        XCTAssertEqual(structure.members?["testString"]?.target, "smithy.api#String")
        XCTAssertEqual(structure.members?["testInteger"]?.target, "smithy.api#Integer")
    }

    func testMapLoad() throws {
        let smithy = """
        namespace soto.example
        structure MyStructure {
            testString: String
        }
        map MyMap {
            key: String,
            value: MyStructure
        }
        """
        let model = try Smithy().parse(smithy)
        XCTAssertNoThrow(try model.validate())
        let shape = model.shape(for: "soto.example#MyMap")
        XCTAssert(shape is MapShape)
        let map = try XCTUnwrap(shape as? MapShape)
        XCTAssertEqual(map.key.target, "smithy.api#String")
        XCTAssertEqual(map.value.target, "soto.example#MyStructure")
    }
}
