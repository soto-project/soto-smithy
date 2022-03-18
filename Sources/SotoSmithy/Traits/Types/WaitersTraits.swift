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

/// Indicates that an operation has various named "waiters" that can be used to poll a resource until it enters a desired state.
public struct WaitableTrait: SingleValueTrait {
    public static let staticName: ShapeId = "smithy.waiters#waitable"
    public var selector: Selector { TypeSelector<OperationShape>() }
    /// Acceptors cause a waiter to transition into one of the following states
    public enum AcceptorState: String, Decodable {
        case success
        case failure
        case retry
    }

    public enum PathComparator: String, Decodable {
        case stringEquals
        case booleanEquals
        case allStringEquals
        case anyStringEquals
    }

    /// The output and inputOutput matchers test the result of a JMESPath expression against an expected value.
    /// These matchers are structures that support the following members.
    public struct PathMatcher: Decodable {
        public let path: String
        public let expected: String
        public let comparator: PathComparator
    }

    /// A matcher defines how an acceptor determines if it matches the current state of a resource. A matcher is a union
    /// where exactly one of the following members MUST be set.
    public enum Matcher: Decodable {
        case output(PathMatcher)
        case inputOutput(PathMatcher)
        case success(Bool)
        case errorType(String)

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let output = try container.decodeIfPresent(PathMatcher.self, forKey: .output) {
                self = .output(output)
            } else if let inputOutput = try container.decodeIfPresent(PathMatcher.self, forKey: .inputOutput) {
                self = .inputOutput(inputOutput)
            } else if let success = try container.decodeIfPresent(Bool.self, forKey: .success) {
                self = .success(success)
            } else if let errorType = try container.decodeIfPresent(String.self, forKey: .errorType) {
                self = .errorType(errorType)
            } else {
                throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Cannot find member"))
            }
        }

        private enum CodingKeys: String, CodingKey {
            case output
            case inputOutput
            case success
            case errorType
        }
    }

    /// Acceptors cause a waiter to transition into one of the following states
    public struct Acceptor: Decodable {
        public let state: AcceptorState
        public let matcher: Matcher
    }

    /// A waiter defines a set of acceptors that are used to check if a resource has entered into a desired state.
    public struct Waiter: Decodable {
        public let documentation: String?
        public let acceptors: [Acceptor]
        public let minDelay: Int?
        public let maxDelay: Int?
        public let deprecated: Bool?
        public let tags: [String]?
    }

    public var value: [String: Waiter]
    public init(value: [String: Waiter]) {
        self.value = value
    }
}
