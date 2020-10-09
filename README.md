# Soto Smithy

Library for loading AWS [Smithy](https://awslabs.github.io/smithy/index.html) JSON AST models. Smithy defines and generates clients, services, and documentation for any protocol.

## Smithy IDL

Smithy models define a service as a collection of resources, operations and shapes. This library does not load Smithy IDL but the isomorphic JSON abstract syntax tree (AST) representation.

For example the following Smithy IDL example
```smithy
namespace soto.example

service MyService {
    version: "2020-10-01",
    operations: [GetServerTime],
}

operation GetServerTime {
    output: GetServerTimeOutput
}

structure GetServerTimeOutput {
    @required
    time: Timestamp
}
```
is represented in JSON AST as
```json
{
    "smithy": "1.0",
    "shapes": {
        "soto.example#MyService": {
            "type": "service",
            "version": "2020-10-01"
            "operations": [
                {
                    "target": "soto.example#GetServerTime"
                }
            ]
        },
        "soto.example#GetServerTime": {
            "type": "operation",
            "output": {
                "target": "soto.example#GetServerTimeOutput"
            }
        },
        "soto.example#GetServerTimeOutput": {
            "type": "structure",
            "members": {
                "time": {
                    "target": "smithy.api#Timestamp",
                    "traits": {
                        "smithy.api#required": {}
                    }
                }
            }
        }
    }
}
```

## Support

SotoSmithy supports all the standard shapes and traits defined in the [Smithy 1.0 spec](https://awslabs.github.io/smithy/1.0/spec/core/index.html). It supports a limited number of selectors including shape and shape with trait eg
```
string [trait|sensitive]
```

## SotoSmithyAWS

This library can be used for reading any Smithy AST but was written specifically for parsing the AWS service Smithy files. There is an additional library SotoSmithyAWS that includes the traits required to load AWS service Smithy AST. If you want to use the AWs traits library you need to register these traits with SotoSmithy by calling 

```swift
Smithy.registerAWSTraits()
```
before you load any files.
