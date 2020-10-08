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

public struct TypeSelector<S: Shape>: Selector {
    public init() {}
    public func select(using model: Model, shape: Shape) -> Bool {
        return type(of: shape) == S.self
    }
}

public struct NumberSelector: Selector {
    public init() {}
    public func select(using model: Model, shape: Shape) -> Bool {
        return
            shape is ByteShape ||
            shape is ShortShape ||
            shape is IntegerShape ||
            shape is LongShape ||
            shape is FloatShape ||
            shape is DoubleShape ||
            shape is BigDecimalShape ||
            shape is BigIntegerShape
    }
}

public struct SimpleTypeSelector: Selector {
    public init() {}
    public func select(using model: Model, shape: Shape) -> Bool {
        return
            shape is BlobShape ||
            shape is StringShape ||
            shape is BooleanShape ||
            shape is ByteShape ||
            shape is ShortShape ||
            shape is IntegerShape ||
            shape is LongShape ||
            shape is FloatShape ||
            shape is DoubleShape ||
            shape is BigDecimalShape ||
            shape is BigIntegerShape ||
            shape is TimestampShape ||
            shape is DocumentShape
    }
}

public struct CollectionSelector: Selector {
    public init() {}
    public func select(using model: Model, shape: Shape) -> Bool {
        return shape is SetShape || shape is ListShape
    }
}

public struct TargetSelector: Selector {
    let selector: Selector
    public init(_ selector: Selector) {
        self.selector = selector
    }

    public func select(using model: Model, shape: Shape) -> Bool {
        guard let member = shape as? MemberShape else { return false }
        guard let memberShape = model.shape(for: member.target) else { return false }
        return self.selector.select(using: model, shape: memberShape)
    }
}

public struct OrTargetSelector: Selector {
    let selector: Selector
    public init(_ selector: Selector) {
        self.selector = selector
    }

    public func select(using model: Model, shape: Shape) -> Bool {
        if self.selector.select(using: model, shape: shape) {
            return true
        }
        guard let member = shape as? MemberShape else { return false }
        guard let memberShape = model.shape(for: member.target) else { return false }
        return self.selector.select(using: model, shape: memberShape)
    }
}

public struct TraitSelector<T: StaticTrait>: Selector {
    public init() {}
    public func select(using model: Model, shape: Shape) -> Bool {
        return shape.trait(type: T.self) != nil
    }
}

public struct TraitNameSelector: Selector {
    let name: String

    public init(_ name: String) {
        self.name = name
    }

    public func select(using model: Model, shape: Shape) -> Bool {
        return shape.trait(named: name) != nil
    }
}

