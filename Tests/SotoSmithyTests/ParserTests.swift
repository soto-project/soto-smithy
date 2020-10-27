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
@testable import SotoSmithyAWS
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
        metadata "test" = "test string" // with speech marks
        metadata greeting = "hello" // without speech marks
        """
        let model = try Smithy().parse(smithy)
        XCTAssertNoThrow(try model.validate())
        XCTAssertEqual(model.metadata["test"].string, "test string")
        XCTAssertEqual(model.metadata["greeting"].string, "hello")
    }
    
    func testMetadataArrayLoad() throws {
        let smithy = """
        metadata "testArray" = [1,2,3]
        """
        let model = try Smithy().parse(smithy)
        XCTAssertNoThrow(try model.validate())
        XCTAssertEqual(model.metadata["testArray"][0].int, 1)
        XCTAssertEqual(model.metadata["testArray"][1].int, 2)
        XCTAssertEqual(model.metadata["testArray"][2].int, 3)
    }
    
    func testMetadataDictionaryLoad() throws {
        let smithy = """
        metadata "testMap" = {
            string: "string",
            "integer": "integer"
        }
        namespace soto.example
        """
        let model = try Smithy().parse(smithy)
        XCTAssertNoThrow(try model.validate())
        XCTAssertEqual(model.metadata["testMap"]["string"].string, "string")
        XCTAssertEqual(model.metadata["testMap"]["integer"].string, "integer")
    }
    
    func testComplexMetadata() throws {
        let smithy = """
        metadata foo = {
            hello: 123,
            "foo": "456",
            testing: \"""
                Hello!
                \""",
            an_array: [10.5],
            nested-object: {
                hello-there$: true
            }, // <-- Trailing comma
        }
        """
        let model = try Smithy().parse(smithy)
        XCTAssertNoThrow(try model.validate())
        XCTAssertEqual(model.metadata["foo"]["hello"].int, 123)
        XCTAssertEqual(model.metadata["foo"]["foo"].string, "456")
        XCTAssertEqual(model.metadata["foo"]["testing"].string, "Hello!")
        XCTAssertEqual(model.metadata["foo"]["an_array"][0].double, 10.5)
        XCTAssertEqual(model.metadata["foo"]["nested-object"]["hello-there$"].bool, true)
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
            @required @sensitive
            value: String
        }
        """
        let model = try Smithy().parse(smithy)
        XCTAssertNoThrow(try model.validate())
        let shape = try XCTUnwrap(model.shape(for: "soto.example#MyString$value"))
        XCTAssertNotNil(shape.trait(type: RequiredTrait.self))
    }
    
    func testDocumentationComment() throws {
        let smithy = """
        namespace soto.example
        /// my string
        structure MyString {
            /// string value
            @required
            value: String
        }
        """
        let model = try Smithy().parse(smithy)
        XCTAssertNoThrow(try model.validate())
        let myString = try XCTUnwrap(model.shape(for: "soto.example#MyString"))
        let myStringDoc = try XCTUnwrap(myString.trait(type: DocumentationTrait.self))
        XCTAssertEqual(myStringDoc.value, "my string")
        let myStringValue = try XCTUnwrap(model.shape(for: "soto.example#MyString$value"))
        let myStringValueDoc = try XCTUnwrap(myStringValue.trait(type: DocumentationTrait.self))
        XCTAssertEqual(myStringValueDoc.value, "string value")
    }
    
    func testApply() throws {
        let smithy = """
        namespace soto.example
        
        string MyString
        apply MyString @documentation("test")
        """
        let model = try Smithy().parse(smithy)
        XCTAssertNoThrow(try model.validate())
        let myStringValue = try XCTUnwrap(model.shape(for: "soto.example#MyString"))
        XCTAssertTrue(myStringValue.hasTrait(type: DocumentationTrait.self))
    }

    func testUse() throws {
        let smithy = """
        namespace soto.example
        use aws.api#service
        @service(sdkId: "my-service", arnNamespace: "*")
        service MyService {
            version: "2020-10-10",
            operations: []
        }
        """
        Smithy.registerAWSTraits()
        let model = try Smithy().parse(smithy)
        XCTAssertNoThrow(try model.validate())
    }

    func testTraitTrait() throws {
        let smithy = """
        namespace smithy.example

        /// A trait that has members.
        @trait(selector: "string")
        structure structuredTrait {
            @required
            lorem: String,

            @required
            ipsum: String,

            dolor: MyMap,
        }
        @trait
        string stringTrait

        list MyList {
            member: Integer
        }

        map MyMap {
            key: String,
            value: MyList
        }

        // Apply the structuredTrait to the string.
        @structuredTrait(
            lorem: "This is a custom trait!",
            ipsum: "lorem and ipsum are both required values.",
            dolor: {"first": [1,2], "second": [3,4]}
        )
        @stringTrait("test")
        string MyStringShape
        """
        let model = try Smithy().parse(smithy)
        XCTAssertNoThrow(try model.validate())
    }
    
    func testHttpResponseTestsTrait() throws {
        let smithy = """
        namespace smithy.example

        use smithy.test#httpResponseTests

        @protocolDefinition
        @trait(selector: "service")
        structure exampleProtocol {}

        @http(method: "POST", uri: "/")
        @httpResponseTests([
            {
                id: "say_goodbye",
                protocol: exampleProtocol,
                params: {farewell: "Bye"},
                code: 200,
                headers: {
                    "X-Farewell": "Bye",
                    "Content-Length": "0"
                }
            }
        ])
        operation SayGoodbye {
            output: SayGoodbyeOutput
        }

        structure SayGoodbyeOutput {
            @httpHeader("X-Farewell")
            farewell: String,
        }
        """
        let model = try Smithy().parse(smithy)
        XCTAssertNoThrow(try model.validate())
    }

    func testApplyExamplesTrait() throws {
        let smithy = """
        @readonly
        operation MyOperation {
            input: MyOperationInput,
            output: MyOperationOutput
        }

        apply MyOperation @examples([
            {
                title: "Invoke MyOperation",
                input: {
                    tags: ["foo", "baz", "bar"],
                },
                output: {
                    status: "PENDING",
                }
            },
            {
                title: "Another example for MyOperation",
                input: {
                    foo: "baz",
                },
                output: {
                    status: "PENDING",
                }
            },
        ])
        """
        let model = try Smithy().parse(smithy)
        XCTAssertNoThrow(try model.validate())
        let myOperation = try XCTUnwrap(model.shape(for: "MyOperation"))
        let exampleTrait = try XCTUnwrap(myOperation.trait(type: ExamplesTrait.self))
        XCTAssertEqual(exampleTrait.value[0].input["tags"][1].string, "baz")
        XCTAssertTrue(myOperation.hasTrait(type: ReadonlyTrait.self))
    }

    func testProtocolDefinitionTrait() throws {
        let smithy = """
        namespace soto.example

        @protocolDefinition(noInlineDocumentSupport: true)
        @trait(selector: "service")
        structure jsonExample {}

        @jsonExample
        service WeatherService {
            version: "2017-02-11",
        }
        """
        let model = try Smithy().parse(smithy)
        XCTAssertNoThrow(try model.validate())
        let jsonExample = try XCTUnwrap(model.shape(for: "soto.example#jsonExample"))
        let trait = try XCTUnwrap(jsonExample.trait(type: ProtocolDefinitionTrait.self))
        XCTAssertEqual(trait.noInlineDocumentSupport, true)
    }

    func testMqttProtocolTraits() throws {
        let smithy = """
        use smithy.mqtt#subscribe
        use smithy.mqtt#topicLabel

        @subscribe("events/{id}")
        operation SubscribeForEvents {
            input: SubscribeForEventsInput,
            output: SubscribeForEventsOutput
        }

        structure SubscribeForEventsInput {
            @required
            @topicLabel
            id: String,
        }

        structure SubscribeForEventsOutput {
            events: EventStream,
        }

        @streaming
        union EventStream {
            message: Event,
        }

        structure Event {
            message: String,
        }
        """
        let model = try Smithy().parse(smithy)
        XCTAssertNoThrow(try model.validate())

    }
}
