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

/// Binds an operation to send a PUBLISH control packet via the MQTT protocol.
public struct MqttPublishTrait: SingleValueTrait {
    public static let staticName: ShapeId = "smithy.mqtt#publish"
    public var selector: Selector { TypeSelector<OperationShape>() }
    public var value: String
    public init(value: String) {
        self.value = value
    }
}

/// Binds an operation to send one or more SUBSCRIBE control packets via the MQTT protocol.
public struct MqttSubscribeTrait: SingleValueTrait {
    public static let staticName: ShapeId = "smithy.mqtt#subscribe"
    public var selector: Selector { TypeSelector<OperationShape>() }
    public var value: String
    public init(value: String) {
        self.value = value
    }
}

/// Binds a structure member to an MQTT topic label.
public struct MqttTopicLabelTrait: StaticTrait {
    public static let staticName: ShapeId = "smithy.mqtt#topicLabel"
    public var selector: Selector { AndSelector(TypeSelector<MemberShape>(), TraitSelector<RequiredTrait>()) }
    public init() {}
}

