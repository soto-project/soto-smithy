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
        metadata "test" = "test string"
        namespace soto.example
        string MyString
        """
        let model = try Smithy().parse(smithy)
        XCTAssertNoThrow(try model.validate())
        XCTAssertEqual(model.metadata?["test"] as? String, "test string")
    }
    
    func testMetadataArrayLoad() throws {
        let smithy = """
        metadata "testArray" = [1,2,3]
        namespace soto.example
        """
        let model = try Smithy().parse(smithy)
        XCTAssertNoThrow(try model.validate())
        XCTAssertEqual(model.metadata?["testArray"] as? [Int], [1,2,3])
    }
    
    func testMetadataDictionaryLoad() throws {
        let smithy = """
        metadata "testMap" = {
            string: "string",
            integer: "integer"
        }
        namespace soto.example
        """
        let model = try Smithy().parse(smithy)
        XCTAssertNoThrow(try model.validate())
        XCTAssertEqual(model.metadata?["testMap"] as? [String:String], ["string":"string", "integer":"integer"])
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
    
    func testServiceLoad() throws {
        let smithy = """
        namespace soto.example
        service MyService {
            version: "2017-02-11",
            operations: [GetServerTime],
        }
        @readonly
        operation GetServerTime {
        }
        """
        let model = try Smithy().parse(smithy)
        XCTAssertNoThrow(try model.validate())
    }
    
    func testSimpleTrait() throws {
        let smithy = """
        namespace soto.example
        @sensitive
        string MyString
        """
        let model = try Smithy().parse(smithy)
        XCTAssertNoThrow(try model.validate())
        let shape = try XCTUnwrap(model.shape(for: "soto.example#MyString"))
        XCTAssertNotNil(shape.trait(type: SensitiveTrait.self))
    }
    
    func testSingleValueTrait() throws {
        let smithy = """
        namespace soto.example
        @documentation("string value")
        string MyString
        """
        let model = try Smithy().parse(smithy)
        XCTAssertNoThrow(try model.validate())
        let shape = try XCTUnwrap(model.shape(for: "soto.example#MyString"))
        let trait = try XCTUnwrap(shape.trait(type: DocumentationTrait.self))
        XCTAssertEqual(trait.value, "string value")
    }

    func testMultipleValueTrait() throws {
        let smithy = """
        namespace soto.example
        @length(min: 0, max: 10)
        list MyList {
            member: String
        }
        """
        let model = try Smithy().parse(smithy)
        XCTAssertNoThrow(try model.validate())
        let shape = try XCTUnwrap(model.shape(for: "soto.example#MyList"))
        let trait = try XCTUnwrap(shape.trait(type: LengthTrait.self))
        XCTAssertEqual(trait.min, 0)
        XCTAssertEqual(trait.max, 10)
    }
    
    func testMemberTrait() throws {
        let smithy = """
        namespace soto.example
        structure MyString {
            @required
            value: String
        }
        """
        let model = try Smithy().parse(smithy)
        XCTAssertNoThrow(try model.validate())
        let shape = try XCTUnwrap(model.shape(for: "soto.example#MyString$value"))
        XCTAssertNotNil(shape.trait(type: RequiredTrait.self))
    }
    
    func testTraitTrait() throws {
        let smithy = """
        namespace smithy.example

        @readonly
        @endpoint(hostPrefix: "{foo}.data.")
        operation GetStatus {
            input: GetStatusInput,
        }

        structure GetStatusInput {
            @required
            @hostLabel
            foo: String
        }
        """
        let model = try Smithy().parse(smithy)
        XCTAssertNoThrow(try model.validate())
    }
}
