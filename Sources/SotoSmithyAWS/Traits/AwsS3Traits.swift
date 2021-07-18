//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2017-2021 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import SotoSmithy

public struct AwsS3UnwrappedXmlOutputTrait: StaticTrait {
    public static let staticName: ShapeId = "aws.customizations#s3UnwrappedXmlOutput"
    public var selector: Selector { TypeSelector<OperationShape>() }
}
