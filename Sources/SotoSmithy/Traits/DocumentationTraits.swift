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

public struct DeprecatedTrait: StaticTrait {
    public static let staticName = "smithy.api#deprecated"
    public let message: String?
    public let since: String?
}

public struct DocumentationTrait: SingleValueTrait {
    public init(value: String) {
        self.value = value
    }

    public static let staticName = "smithy.api#documentation"
    public let value: String
}

public struct ExamplesTrait: SingleValueTrait {
    public static let staticName = "smithy.api#examples"
    public var selector: Selector { TypeSelector<OperationShape>() }
    public struct Example: Codable {
        public let title: String
        public let documentation: String?
        public let input: String
        public let output: String
    }

    public typealias Value = [Example]
    public let value: Value
    public init(value: Value) {
        self.value = value
    }
}

public struct ExternalDocumentationTrait: SingleValueTrait {
    public static let staticName = "smithy.api#externalDocumentation"
    public typealias Value = [String: String]
    public let value: Value
    public init(value: Value) {
        self.value = value
    }
}

public struct InternalTrait: StaticTrait {
    public static let staticName = "smithy.api#internal"
    public init() {}
}

public struct SensitiveTrait: StaticTrait {
    public static let staticName = "smithy.api#sensitive"
    public var selector: Selector { NotSelector(
        OrSelector(
            TypeSelector<OperationShape>(),
            TypeSelector<ServiceShape>(),
            TypeSelector<ResourceShape>()
        )
    ) }
    public init() {}
}

public struct SinceTrait: SingleValueTrait {
    public static let staticName = "smithy.api#since"
    public var value: String
    public init(value: String) {
        self.value = value
    }
}

public struct TagsTrait: SingleValueTrait {
    public static let staticName = "smithy.api#tags"
    public typealias Value = [String]
    public let value: Value
    public init(value: Value) {
        self.value = value
    }
}

public struct TitleTrait: SingleValueTrait {
    public static let staticName = "smithy.api#title"
    public var selector: Selector { OrSelector(TypeSelector<ServiceShape>(), TypeSelector<ResourceShape>()) }
    public var value: String
    public init(value: String) {
        self.value = value
    }
}

public struct UnstableTrait: StaticTrait {
    public static let staticName = "smithy.api#unstable"
    public init() {}
}
