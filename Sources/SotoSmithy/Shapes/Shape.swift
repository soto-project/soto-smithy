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

public protocol Shape: Codable {
    static var type: String { get }
    var traits: TraitList? { get set }
    var shapeSelf: Shape { get }
    func validate(using model: Model) throws
    mutating func add(trait: Trait, to member: String) throws
    mutating func remove(trait: StaticTrait.Type, from member: String) throws
}

extension Shape {
    public static var type: String { return "_undefined_" }
    public var shapeSelf: Shape { return self }

    public func validate(using model: Model) throws {
        try traits?.validate(using: model, shape: self)
    }

    public func trait<T: StaticTrait>(type: T.Type) -> T? {
        return traits?.trait(type: T.self)
    }

    public mutating func add(trait: Trait) {
        if var traits = self.traits {
            traits.add(trait: trait)
        } else {
            self.traits = TraitList(traits: [trait])
        }
    }

    public mutating func remove(trait: StaticTrait.Type) {
        self.traits?.remove(trait: trait)
    }

    public mutating func add(trait: Trait, to member: String) throws {
        throw Smithy.MemberDoesNotExistError(name: member)
    }

    public mutating func remove(trait: StaticTrait.Type, from member: String) throws {
        throw Smithy.MemberDoesNotExistError(name: member)
    }
}

