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

@testable import SotoSmithy
import XCTest

class TokenizerTests: XCTestCase {
    func testTokens() throws {
        let string = "namespace soto.example"
        let tokens = try Tokenizer().tokenize(string)
        XCTAssertEqual(tokens.count, 2)
        XCTAssertEqual(tokens[0], .token("namespace"))
        XCTAssertEqual(tokens[1], .token("soto.example"))
    }

    func testGrammar() throws {
        let string = "@testTrait(value: 1)"
        let tokens = try Tokenizer().tokenize(string)
        XCTAssertEqual(tokens.count, 6)
        XCTAssertEqual(tokens[0], .token("@testTrait"))
        XCTAssertEqual(tokens[1], .grammar("("))
        XCTAssertEqual(tokens[2], .token("value"))
        XCTAssertEqual(tokens[3], .grammar(":"))
        XCTAssertEqual(tokens[4], .number(1))
        XCTAssertEqual(tokens[5], .grammar(")"))
    }
    
    func testString() throws {
        let string = "@testTrait(\"test string\")"
        let tokens = try Tokenizer().tokenize(string)
        XCTAssertEqual(tokens.count, 4)
        XCTAssertEqual(tokens[2], .string("test string"))
    }
    
    func testNewline() throws {
        let string = """
        namespace soto.example
        @testTrait("test string)
        """
        XCTAssertThrowsError(_ = try Tokenizer().tokenize(string)) { error in
            switch error {
            case let error as Tokenizer.Error where error.errorType == .unterminatedString:
                XCTAssertEqual(error.context.lineNumber, 2)
            default:
                XCTFail("\(error)")
            }
        }
    }
    
    func testEscapeCharacter() throws {
        let string = #"@testTrait("test \"string\"")"#
        let tokens = try Tokenizer().tokenize(string)
        XCTAssertEqual(tokens.count, 4)
        XCTAssertEqual(tokens[2], .string(#"test "string""#))
    }
    
    func testInvalidEscapeCharacter() throws {
        let string = #"@testTrait("test \string\"")"#
        XCTAssertThrowsError(_ = try Tokenizer().tokenize(string)) { error in
            switch error {
            case let error as Tokenizer.Error where error.errorType == .unrecognisedEscapeCharacter:
                XCTAssertEqual(error.context.line, #"@testTrait("test \string\"")"#)
                XCTAssertEqual(error.context.lineNumber, 1)
                XCTAssertEqual(error.context.columnNumber, 19)
            default:
                XCTFail("\(error)")
            }
        }
    }
    
    func testComment() throws {
        let string = """
        namespace soto.example
        // my string
        string MyString
        """
        let tokens = try Tokenizer().tokenize(string)
        XCTAssertEqual(tokens[3], .token("string"))
    }
    
    func testDocumentationComment() throws {
        let string = """
        namespace soto.example
        /// my string
        string MyString
        """
        let tokens = try Tokenizer().tokenize(string)
        XCTAssertEqual(tokens[3], .documentationComment("my string"))
    }
}
