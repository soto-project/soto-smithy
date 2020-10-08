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

public struct BoxTrait: StaticTrait {
    public static let staticName = "smithy.api#box"
    public static let selector: Selector = OrTargetSelector(
        OrSelector(
            TypeSelector<BooleanShape>(),
            TypeSelector<ByteShape>(),
            TypeSelector<ShortShape>(),
            TypeSelector<IntegerShape>(),
            TypeSelector<LongShape>(),
            TypeSelector<FloatShape>(),
            TypeSelector<DoubleShape>()
        )
    )
    public init() {}
}

public struct ErrorTrait: SingleValueTrait {
    public static let staticName = "smithy.api#error"
    public static let selector: Selector = TypeSelector<StructureShape>()
    public enum ErrorType: String, Codable {
        case client
        case server
    }
    public typealias Value = ErrorType
    public let value: Value
    public init(value: Value) {
        self.value = value
    }
}

