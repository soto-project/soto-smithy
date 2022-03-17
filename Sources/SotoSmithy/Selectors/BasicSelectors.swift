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

/// Return true if shape is of type
public struct TypeSelector<S: Shape>: Selector {
    public init() {}
    public func select(using model: Model, shape: Shape) -> Bool {
        return type(of: shape) == S.self
    }
}

/// Return true is shape is a number type
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

/// Return true if shape is a simple type
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

/// Return true if shape is either a list or a set
public struct CollectionSelector: Selector {
    public init() {}
    public func select(using model: Model, shape: Shape) -> Bool {
        return shape is CollectionShape
    }
}

/// Return true is member target matches selector
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

/// Return true if member or member target matches selector
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

/// Return true is shape has a trait
public struct TraitSelector<T: StaticTrait>: Selector {
    public init() {}
    public func select(using model: Model, shape: Shape) -> Bool {
        return shape.trait(type: T.self) != nil
    }
}

/// Return true if shape has a trait with name
public struct TraitNameSelector: Selector {
    let name: ShapeId

    public init(_ name: ShapeId) {
        self.name = name
    }

    public func select(using model: Model, shape: Shape) -> Bool {
        return shape.trait(named: self.name) != nil
    }
}
