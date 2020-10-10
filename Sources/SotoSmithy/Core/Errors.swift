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

extension Smithy {
    public struct ValidationError: Error {
        public let reason: String
    }

    public struct ShapeDoesNotExistError: Error {
        public let id: ShapeId
    }

    public struct MemberDoesNotExistError: Error {
        public let name: String
    }

    public struct UnrecognisedSelectorError: Error {
        public let value: String
    }
}
