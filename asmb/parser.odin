package asmb

import "core:fmt"
import "core:os"

Parser :: struct {
    path: string,
    src: string,
    tokens: []Token,
    stmts: [dynamic]Stmt,
    start: int,
    current: int,
}

parser_new :: proc(path, src: string, tokens: []Token) -> Parser {
    return Parser{path, src, tokens, {}, 0, 0}
}

parser_parse :: proc(parser: ^Parser) {
    for !parser_end(parser^) {
        parser.start = parser.current
        parser_parse_stmt(parser)
    }
}

parser_add :: proc(parser: ^Parser, type: StmtType, token: Token) {
    append(&parser.stmts, Stmt{type, token.span})
}

parser_parse_stmt :: proc(parser: ^Parser) {
    token := parser_advance(parser)

    #partial switch token.type {
    case .Dollar:
        #partial switch parser_advance(parser).type {
        case .DATA:
            data: [dynamic]u8
            for parser_expect(parser, parser.tokens[parser.current], .Int8, true) != nil {
                append(&data, parser.tokens[parser.current].value.(u8))
                parser_advance(parser)
                parser_expect_current(parser, .Comma)
            }
            // append(&parser.stmts, Stmt{Meta(DataMeta{data[:]}), token.span})
            parser_add(parser, Meta(DataMeta{data[:]}), token)
        case .ALIAS:
            name := parser_expect_current(parser, .Ident)
            parser_expect_current(parser, .Comma)
            value := parser_expect_current(parser, .Int16)
            // append(&parser.stmts, Stmt{Meta(AliasMeta{name.(string), value.(u16)}), token.span})
            parser_add(parser, Meta(AliasMeta{name.(string), value.(u16)}), token)
        case .LABEL:
            name := parser_expect_current(parser, .Ident)
            // append(&parser.stmts, Stmt{Meta(LabelMeta{name.(string)}), token.span})
            parser_add(parser, Meta(LabelMeta{name.(string)}), token)
        case:
            fmt.println("unknown meta")
        }
    case .CLS:
        // append(&parser.stmts, Stmt{Instr{.Nullary, NullaryInstr{.Clear}}, token.span})
        parser_add(parser, Instr{.Nullary, NullaryInstr{.Clear}}, token)
    case .JMP:
        if value, ok := parser_expect_current(parser, .Int16, true); ok {
            parser_add(parser, Instr{.Unary, UnaryInstr{.JumpInt, value.(u16)}}, token)
        } else {
            value := parser_expect_current(parser, .Ident)
            parser_add(parser, Instr{.Unary, UnaryInstr{.JumpLabel, value.(string)}}, token)
        }
    case .MVI:
        if value, ok := parser_expect_current(parser, .Int16, true); ok {
            parser_add(parser, Instr{.Unary, UnaryInstr{.MoveIRegInt, value.(u16)}}, token)
        } else {
            value := parser_expect_current(parser, .Ident)
            parser_add(parser, Instr{.Unary, UnaryInstr{.MoveIRegAlias, value.(string)}}, token)
        }
    case .MVB:
        reg := parser_expect_register(parser)
        parser_expect_current(parser, .Comma)
        value := parser_expect_int(parser, .Int8)
        parser_add(parser, Instr{.Binary, BinaryInstr{.MoveRegInt, reg, value}}, token)
    case .ADDB:
        reg := parser_expect_register(parser)
        parser_expect_current(parser, .Comma)
        value := parser_expect_int(parser, .Int8)
        parser_add(parser, Instr{.Binary, BinaryInstr{.AddRegInt, reg, value}}, token)
    case .DRW:
        regx := parser_expect_current(parser, .Int4)
        parser_expect_current(parser, .Comma)
        regy := parser_expect_current(parser, .Int4)
        parser_expect_current(parser, .Comma)
        height := parser_expect_current(parser, .Int4)
        parser_add(parser, Instr{.Ternary, TernaryInstr{.Draw, regx.(u8), regy.(u8), height.(u8)}}, token)
    case .EOF:
    case:
        error(parser.src, token.span, "unexpected %s", token.type)
    }
}

error :: proc(src: string, span: Span, msg: string, args: ..any) -> ! {
    line, col := get_line_and_col(src, span.lo)
    fmt.printf("error at %d:%d: ", line, col)
    fmt.printfln(msg, ..args)
    os.exit(1)
}

parser_expect_int :: proc(parser: ^Parser, type: TokenType) -> Value {
    value, ok := parser_expect_current(parser, .Int8, true)
    
    if !ok {
        value = parser_expect_current(parser, .Ident)
    }

    return as_value(value)
}

parser_expect_register :: proc(parser: ^Parser) -> Value {
    reg, ok := parser_expect_current(parser, .Int4, true)
    
    if !ok {
        reg = parser_expect_current(parser, .Ident)
    }

    return as_value(reg)
}

as_value :: proc(value: TokenValue) -> Value {
    switch v in value {
    case u8: return v
    case u16: return v
    case string: return v
    case: return nil
    }
}

parser_expect_current :: proc(parser: ^Parser, expect_type: TokenType, silent := false) -> (TokenValue, bool) #optional_ok {
    value, ok := parser_expect(parser, parser.tokens[parser.current], expect_type, silent)
    if !silent || ok {
        parser_advance(parser)
    }
    return value, ok
}

parser_expect :: proc(parser: ^Parser, token: Token, expect_type: TokenType, silent := false) -> (TokenValue, bool) #optional_ok {
    if token.type == expect_type {
        return token.value, true
    } else if expect_type == .Int16 && (token.type == .Int4 || token.type == .Int8) {
        return u16(token.value.(u8)), true
    } else if expect_type == .Int8 && token.type == .Int4 {
        return token.value, true
    } else if !silent {
        error(parser.src, token.span, "expected %s but got %s", expect_type, token.type)
    }

    return nil, false
}

parser_advance :: proc(parser: ^Parser) -> Token {
    defer parser.current += 1
    return parser.tokens[parser.current]
}

parser_end :: proc(parser: Parser) -> bool {
    return parser.current >= len(parser.tokens)
}

get_line_and_col :: proc(src: string, lo: int) -> (line, col: int) {
	line = 1
	col = 1
	for i in 0..<lo {
		if src[i] == '\n' {
			line += 1
			col = 1
		} else {
			col += 1
		}
	}
	return line, col
}
