//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2017-2020 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// traits used by the Soto code generator.

import SotoSmithy

struct SotoPatchEnumTrait: Trait {
    static let name = "soto.patch#enum"
    let remove: [String]
    let add: [EnumTrait.EnumDefinition]
}

struct SotoPatchNameTrait: Trait {
    static let name = "soto.patch#name"
    let name: String
}