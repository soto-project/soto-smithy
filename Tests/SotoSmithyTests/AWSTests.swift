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

import SotoSmithy
import SotoSmithyAWS
import XCTest

class AWSTraitTests: XCTestCase {
    func testJson(_ json: String) {
        Smithy.registerAWSTraits()
        var model: Model?
        XCTAssertNoThrow(model = try Smithy().decodeAST(from: Data(json.utf8)))
        XCTAssertNoThrow(try model?.validate())
    }

    func testIAMConditionKeysTrait() {
        testJson("""
        {
            "smithy": "1.0",
            "shapes": {
                "smithy.example#MyService": {
                    "type": "service",
                    "version": "2017-02-11",
                    "resources": [
                        {
                            "target": "smithy.example#MyResource"
                        }
                    ],
                    "traits": {
                        "aws.api#service": {
                            "sdkId": "My Value",
                            "arnNamespace": "myservice"
                        },
                        "aws.iam#defineConditionKeys": {
                            "otherservice:Bar": {
                                "type": "String"
                            }
                        }
                    }
                },
                "smithy.example#MyResource": {
                    "type": "resource",
                    "identifiers": {
                        "foo": {
                            "target": "smithy.api#String"
                        }
                    },
                    "operations": [
                        {
                            "target": "smithy.example#MyOperation"
                        }
                    ],
                    "traits": {
                        "aws.iam#conditionKeys": [
                            "otherservice:Bar"
                        ]
                    }
                },
                "smithy.example#MyOperation": {
                    "type": "operation",
                    "traits": {
                        "aws.iam#conditionKeys": [
                            "aws:region"
                        ]
                    }
                }
            }
        }
        """)
    }

    func testIAMDefineConditionKeysTrait() {
        testJson("""
        {
            "smithy": "1.0",
            "shapes": {
                "smithy.example#MyService": {
                    "type": "service",
                    "version": "2017-02-11",
                    "resources": [
                        {
                            "target": "smithy.example#MyResource"
                        }
                    ],
                    "traits": {
                        "aws.api#service": {
                            "sdkId": "My Value",
                            "arnNamespace": "myservice"
                        },
                        "aws.iam#defineConditionKeys": {
                            "otherservice:Bar": {
                                "type": "String",
                                "documentation": "The Bar string",
                                "externalDocumentation": "http://example.com"
                            }
                        }
                    }
                }
            }
        }
        """)
    }

    func testApiGatewayIntegrationTrait() {
        testJson("""
        {
            "smithy": "1.0",
            "shapes": {
                "smithy.example#Weather": {
                    "type": "service",
                    "version": "2018-03-17",
                    "traits": {
                        "aws.protocols#restJson1": {},
                        "aws.auth#sigv4": {
                            "name": "weather"
                        },
                        "aws.apigateway#integration": {
                            "type": "aws",
                            "uri": "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:012345678901:function:HelloWorld/invocations",
                            "httpMethod": "POST",
                            "credentials": "arn:aws:iam::012345678901:role/apigateway-invoke-lambda-exec-role",
                            "requestTemplates": {
                                "application/json": "#set ($root=$input.path('$')) { \\"stage\\": \\"$root.name\\", \\"user-id\\": \\"$root.key\\" }",
                                "application/xml": "#set ($root=$input.path('$')) <stage>$root.name</stage> "
                            },
                            "requestParameters": {
                                "integration.request.path.stage": "method.request.querystring.version",
                                "integration.request.querystring.provider": "method.request.querystring.vendor"
                            },
                            "cacheNamespace": "cache namespace",
                            "cacheKeyParameters": [],
                            "responses": {
                                "202": {
                                    "statusCode": "200",
                                    "responseParameters": {
                                        "method.response.header.requestId": "integration.response.header.cid"
                                    },
                                    "responseTemplates": {
                                        "application/json": "#set ($root=$input.path('$')) { \\"stage\\": \\"$root.name\\", \\"user-id\\": \\"$root.key\\" }",
                                        "application/xml": "#set ($root=$input.path('$')) <stage>$root.name</stage> "
                                    }
                                },
                                "302": {
                                    "statusCode": "302",
                                    "responseParameters": {
                                        "method.response.header.Location": "integration.response.body.redirect.url"
                                    }
                                },
                                "default": {
                                    "statusCode": "400",
                                    "responseParameters": {
                                        "method.response.header.test-method-response-header": "'static value'"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        """)
    }
}
