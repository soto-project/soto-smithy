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

/// The suppress trait is used to suppress validation events(s) for a specific shape. Each value in the suppress
/// trait is a validation event ID to suppress for the shape.
public struct SuppressTrait: SingleValueTrait {
    public static let staticName = "smithy.api#suppress"
    public typealias Value = [String]
    public let value: Value
    public init(value: Value) {
        self.value = value
    }
}
