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

/// Protocol for Smithy Shape.
public protocol Shape: class, Codable {
    /// Shape type string
    static var type: String { get }
    
    /// List of traits attached to this shape
    var traits: TraitList? { get set }
    
    /// Validate this shape
    /// - Parameter model: The model the shape is part of
    func validate(using model: Model) throws
    
    /// Add a trait to one of this shapes members
    /// - Parameters:
    ///   - trait: Trait to add
    ///   - member: Member to add trait to
    func add(trait: Trait, to member: String) throws
    
    /// Remove a trait from a one of this shapes members
    /// - Parameters:
    ///   - trait: Trait type to remove
    ///   - member: Member to remove trait from
    func remove(trait: StaticTrait.Type, from member: String) throws
}

extension Shape {
    /// Default validate function which validates the traits attached to this shape
    /// - Parameter model: The model the shape is part of
    public func validate(using model: Model) throws {
        try validateTraits(using: model)
    }
    
    /// Get trait of type that is  attached to shape
    /// - Parameter type: Type of trait we are looking for
    /// - Returns: Trait if there is one attached
    public func trait<T: StaticTrait>(type: T.Type) -> T? {
        return traits?.trait(type: T.self)
    }
    
    /// Return if shape has a trait of type
    /// - Parameter type: Trait type
    /// - Returns: whether shape has trait
    public func hasTrait(type: StaticTrait.Type) -> Bool {
        return traits?.hasTrait(type: type) ?? false
    }

    /// Get trait with name that is attached to shape
    /// - Parameter named: Name of trait we are looking for
    /// - Returns: Trait if it exists
    public func trait(named: String) -> Trait? {
        return traits?.trait(named: named)
    }
    
    /// Add trait to shape
    /// - Parameter trait: Trait to add
    public func add(trait: Trait) {
        if traits?.add(trait: trait) == nil {
            self.traits = TraitList(traits: [trait])
        }
    }
    
    /// Remove trait of type from shape
    /// - Parameter trait: Trait type to remove
    public func remove(trait: StaticTrait.Type) {
        self.traits?.remove(trait: trait)
    }
    
    /// Remove trait of type from shape
    /// - Parameter trait: Trait type to remove
    public func removeTrait(named: String) {
        self.traits?.removeTrait(named: named)
    }
    
    /// Default implementation of adding trait to member. Throws an error. Shape which have members will override this
    /// - Throws: `MemberDoesNotExistError`
    public func add(trait: Trait, to member: String) throws {
        throw Smithy.MemberDoesNotExistError(name: member)
    }

    /// Default implementation of removing trait from member. Throws an error. Shape which have members will override this
    /// - Throws: `MemberDoesNotExistError`
    public func remove(trait: StaticTrait.Type, from member: String) throws {
        throw Smithy.MemberDoesNotExistError(name: member)
    }
    
    /// Selector used to find Shape of this type
    static public var typeSelector: Selector {
        return TypeSelector<Self>()
    }

    func validateTraits(using model: Model) throws {
        try traits?.validate(using: model, shape: self)
    }
}
