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

/// Shape representing a data blob
public class BlobShape: Shape {
    public static let type = "blob"
    public var traits: TraitList?
    public init(traits: TraitList? = nil) {
        self.traits = traits
    }
}

/// Shape representing a boolean value
public class BooleanShape: Shape {
    public static let type = "boolean"
    public var traits: TraitList?
    public init(traits: TraitList? = nil) {
        self.traits = traits
    }
}

/// Shape representing a string value
public class StringShape: Shape {
    public static let type = "string"
    public var traits: TraitList?
    public init(traits: TraitList? = nil) {
        self.traits = traits
    }
}

/// Shape representing an 8 bit value
public class ByteShape: Shape {
    public static let type = "byte"
    public var traits: TraitList?
    public init(traits: TraitList? = nil) {
        self.traits = traits
    }
}

/// Shape representing a short integer
public class ShortShape: Shape {
    public static let type = "short"
    public var traits: TraitList?
    public init(traits: TraitList? = nil) {
        self.traits = traits
    }
}

/// Shape representing a standard integer
public class IntegerShape: Shape {
    public static let type = "integer"
    public var traits: TraitList?
    public init(traits: TraitList? = nil) {
        self.traits = traits
    }
}

/// Shape representing a long integer
public class LongShape: Shape {
    public static let type = "long"
    public var traits: TraitList?
    public init(traits: TraitList? = nil) {
        self.traits = traits
    }
}

/// Shape representing a single precision floating point value
public class FloatShape: Shape {
    public static let type = "float"
    public var traits: TraitList?
    public init(traits: TraitList? = nil) {
        self.traits = traits
    }
}

/// Shape representing a double precision floating point value
public class DoubleShape: Shape {
    public static let type = "double"
    public var traits: TraitList?
    public init(traits: TraitList? = nil) {
        self.traits = traits
    }
}

/// Shape representing an arbitrary large integer
public class BigIntegerShape: Shape {
    public static let type = "bigInteger"
    public var traits: TraitList?
    public init(traits: TraitList? = nil) {
        self.traits = traits
    }
}

/// Shape representing an arbitrary large floating point value
public class BigDecimalShape: Shape {
    public static let type = "bigDecimal"
    public var traits: TraitList?
    public init(traits: TraitList? = nil) {
        self.traits = traits
    }
}

/// Shape representing a date value
public class TimestampShape: Shape {
    public static let type = "timestamp"
    public var traits: TraitList?
    public init(traits: TraitList? = nil) {
        self.traits = traits
    }
}

/// Shape representing protocol agnostic open content
public class DocumentShape: Shape {
    public static let type = "document"
    public var traits: TraitList?
    public init(traits: TraitList? = nil) {
        self.traits = traits
    }
}

/// Shape representing
public class UnitShape: Shape {
    public static let type = "unit"
    public var traits: TraitList?
    public init(traits: TraitList? = nil) {
        self.traits = traits
    }
}
