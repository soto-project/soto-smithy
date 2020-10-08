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

import SotoSmithy
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
        let model = try JSONDecoder().decode(Model.self, from: Data(json.utf8))
        try model.validate()
        XCTAssertEqual(try model.select(from: "string").count, 5) // this includes the prelude string type
        XCTAssertEqual(try model.select(from: "union").count, 1)
        XCTAssertEqual(try model.select(from: "integer").count, 3)
    }
}
