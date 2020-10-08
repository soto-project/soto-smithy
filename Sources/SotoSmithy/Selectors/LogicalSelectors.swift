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

public struct AllSelector: Selector {
    public func select(using model: Model, shape: Shape) -> Bool {
        return true
    }
}

public struct NotSelector: Selector {
    let selector: Selector
    public init(_ selector: Selector) {
        self.selector = selector
    }

    public func select(using model: Model, shape: Shape) -> Bool {
        return !self.selector.select(using: model, shape: shape)
    }
}

public struct AndSelector: Selector {
    let selectors: [Selector]
    public init(_ selectors: Selector...) {
        self.selectors = selectors
    }

    public init(_ selectors: [Selector]) {
        self.selectors = selectors
    }

    public func select(using model: Model, shape: Shape) -> Bool {
        for selector in self.selectors {
            if selector.select(using: model, shape: shape) == false {
                return false
            }
        }
        return true
    }
}

public struct OrSelector: Selector {
    let selectors: [Selector]

    public init(_ selectors: Selector...) {
        self.selectors = selectors
    }

    public init(_ selectors: [Selector]) {
        self.selectors = selectors
    }

    public func select(using model: Model, shape: Shape) -> Bool {
        for selector in self.selectors {
            if selector.select(using: model, shape: shape) == true {
                return true
            }
        }
        return false
    }
}
