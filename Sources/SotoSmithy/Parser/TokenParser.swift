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
        position = tokens.startIndex
    }

    func token() throws -> Tokenizer.Token {
        guard position != tokens.endIndex else { throw Smithy.ParserError.overflow }
        return tokens[position]
    }

    mutating func nextToken() throws -> Tokenizer.Token {
        guard position != tokens.endIndex else { throw Smithy.ParserError.overflow }
        let token = tokens[position]
        position += 1
        return token
    }

    mutating func advance() throws {
        guard position != tokens.endIndex else { throw Smithy.ParserError.overflow }
        position += 1
    }

    mutating func retreat() throws {
        guard position != tokens.startIndex else { throw Smithy.ParserError.overflow }
        position -= 1
    }

    mutating func expect(_ token: Tokenizer.Token.TokenType) throws {
        guard position != tokens.endIndex else { throw Smithy.ParserError.overflow }
        guard tokens[position] == token else { throw Smithy.ParserError.unexpectedToken(tokens[position]) }
        position += 1
    }

    mutating func skip(while token: Tokenizer.Token.TokenType) {
        while !reachedEnd() {
            let nextToken = tokens[position]
            position += 1
            if nextToken != token {
                position -= 1
                return
            }
        }
    }

    func reachedEnd() -> Bool {
        return position == tokens.endIndex
    }
}
