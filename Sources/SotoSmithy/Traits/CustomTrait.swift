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

public struct CustomTrait: Trait {
    public let shapeId: ShapeId
    public var selector: Selector { return ShapeSelector(self.shapeId, TraitSelector<TraitTrait>()) }
    public var name: String { return self.shapeId.description }
}

public struct TraitTrait: StaticTrait {
    public static var staticName = "smithy.api#trait"
    init() {
        print("SFSDF")
    }
}
