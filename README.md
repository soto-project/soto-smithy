# Soto Smithy

Library for loading AWS [Smithy](https://awslabs.github.io/smithy/index.html) files and their JSON AST models. Smithy defines services and documentation for any protocol.

## Smithy IDL

Smithy models define a service as a collection of resources, operations and shapes. This library loads Smithy IDL and the isomorphic JSON abstract syntax tree (AST) representation.

For example the following Smithy IDL example represents a service TimeService with one operation GetServerTime which returns a structure GetServerTimeOutput that contains a timestamp. 
 
```smithy
namespace soto.example

service TimeService {
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
It can be represented in Smithy JSON AST as
```json
{
    "smithy": "1.0",
    "shapes": {
        "soto.example#TimeService": {
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

This library can be used for reading any Smithy files but was written specifically for parsing the AWS service Smithy files. There is an additional library SotoSmithyAWS that includes the traits required to load AWS service Smithy. If you want to use the AWS traits library you need to register these traits with SotoSmithy by calling the following before you load any files.

```swift
Smithy.registerAWSTraits()
```
