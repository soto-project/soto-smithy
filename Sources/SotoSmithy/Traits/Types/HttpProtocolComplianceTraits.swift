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
public struct HttpRequestTestsTrait: SingleValueTrait {
    public static let staticName: ShapeId = "smithy.test#httpRequestTests"
    public var selector: Selector { TypeSelector<OperationShape>() }
    public struct Test: Decodable {
        public let id: String
        public let `protocol`: ShapeId
        public let method: String
        public let uri: String
        public let authScheme: ShapeId?
        public let queryParams: [String]?
        public let forbidQueryParams: [String]?
        public let requireQueryParams: [String]?
        public let headers: [String: String]?
        public let forbidHeaders: [String: String]?
        public let requireHeaders: [String: String]?
        public let body: String?
        public let bodyMediaType: String?
        public let params: Document?
        public let vendorParams: Document?
        public let documentation: String?
    }

    public typealias Value = [Test]
    public var value: [Test]
    public init(value: Value) {
        self.value = value
    }

    public func validate(using model: Model, shape: Shape) throws {
        guard self.selector.select(using: model, shape: shape) else {
            throw Smithy.ValidationError(reason: "Trait \(traitName) cannot be applied to shape **")
        }
        try self.value.forEach {
            guard model.shape(for: $0.protocol) != nil else { throw Smithy.ValidationError(reason: "Member of ** references non-existent shape \($0.protocol)") }
            if let authScheme = $0.authScheme {
                guard model.shape(for: authScheme) != nil else { throw Smithy.ValidationError(reason: "Member of ** references non-existent shape \(authScheme)") }
            }
        }
    }
}

public struct HttpResponseTestsTrait: SingleValueTrait {
    public static let staticName: ShapeId = "smithy.test#httpResponseTests"
    public var selector: Selector { TypeSelector<OperationShape>() }
    public struct Test: Decodable {
        public let id: String
        public let `protocol`: ShapeId
        public let code: Int
        public let authScheme: ShapeId?
        public let headers: [String: String]?
        public let forbidHeaders: [String: String]?
        public let requireHeaders: [String: String]?
        public let body: String?
        public let bodyMediaType: String?
        public let params: Document?
        public let vendorParams: Document?
        public let documentation: String?
    }

    public typealias Value = [Test]
    public var value: [Test]
    public init(value: Value) {
        self.value = value
    }

    public func validate(using model: Model, shape: Shape) throws {
        guard self.selector.select(using: model, shape: shape) else {
            throw Smithy.ValidationError(reason: "Trait \(traitName) cannot be applied to shape **")
        }
        try self.value.forEach {
            guard model.shape(for: $0.protocol) != nil else { throw Smithy.ValidationError(reason: "Member of ** references non-existent shape \($0.protocol)") }
            if let authScheme = $0.authScheme {
                guard model.shape(for: authScheme) != nil else { throw Smithy.ValidationError(reason: "Member of ** references non-existent shape \(authScheme)") }
            }
        }
    }
}
