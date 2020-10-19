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

/// Protocol for Trait in Smithy model
public protocol Trait {
    /// name of trait
    var traitName: String { get }
    /// Selector defining what shapes this trait can be attached to
    var selector: Selector { get }
    /// Validate this trait and whether it is attached to the correct model
    func validate(using model: Model, shape: Shape) throws
}

extension Trait {
    public var selector: Selector { return AllSelector() }
    public func validate(using model: Model, shape: Shape) throws {
        guard self.selector.select(using: model, shape: shape) else {
            throw Smithy.ValidationError(reason: "Trait \(traitName) cannot be applied to shape **")
        }
    }
}
