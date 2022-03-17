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

/// Token parser used internal by Smithy.parse
struct TokenParser {
    let tokens: [Tokenizer.Token]
    var position: Int

    init(_ tokens: [Tokenizer.Token]) {
        self.tokens = tokens
        self.position = tokens.startIndex
    }

    func token() throws -> Tokenizer.Token {
        guard self.position != self.tokens.endIndex else { throw Smithy.ParserError.overflow }
        return self.tokens[self.position]
    }

    mutating func nextToken() throws -> Tokenizer.Token {
        guard self.position != self.tokens.endIndex else { throw Smithy.ParserError.overflow }
        let token = self.tokens[self.position]
        self.position += 1
        return token
    }

    mutating func advance() throws {
        guard self.position != self.tokens.endIndex else { throw Smithy.ParserError.overflow }
        self.position += 1
    }

    mutating func retreat() throws {
        guard self.position != self.tokens.startIndex else { throw Smithy.ParserError.overflow }
        self.position -= 1
    }

    mutating func expect(_ token: Tokenizer.Token.TokenType) throws {
        guard self.position != self.tokens.endIndex else { throw Smithy.ParserError.overflow }
        guard self.tokens[self.position] == token else { throw Smithy.ParserError.unexpectedToken(self.tokens[self.position]) }
        self.position += 1
    }

    mutating func skip(while token: Tokenizer.Token.TokenType) {
        while !self.reachedEnd() {
            let nextToken = self.tokens[self.position]
            self.position += 1
            if nextToken != token {
                self.position -= 1
                return
            }
        }
    }

    func reachedEnd() -> Bool {
        return self.position == self.tokens.endIndex
    }
}
