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
        
            append(&parser.stmts, Meta{.Data, DataMeta{data[:]}})
        case .ALIAS:
            name := parser_expect_current(parser, .Ident)
            parser_expect_current(parser, .Comma)
            value := parser_expect_current(parser, .Int16)
            
            append(&parser.stmts, Meta{.Alias, AliasMeta{name.(string), value.(u16)}})
        case:
            fmt.println("unknown meta")
        }
    case .CLS:
        append(&parser.stmts, Instr{.Nullary, NullaryInstr{.Clear}})
    case .JMP:
        value := parser_expect_current(parser, .Int16)
        append(&parser.stmts, Instr{.Unary, UnaryInstr{.JumpInt, value.(u16)}})
    case .MVI:
        value, ok := parser_expect_current(parser, .Int16, true)
        if ok {
            append(&parser.stmts, Instr{.Unary, UnaryInstr{.MoveIRegInt, value.(u16)}})
        } else {
            value = parser_expect_current(parser, .Ident)
            append(&parser.stmts, Instr{.Unary, UnaryInstr{.MoveIRegAlias, value.(string)}})
        }
    case .MVB:
        reg := parser_expect_register(parser)
        parser_expect_current(parser, .Comma)
        value := parser_expect_int(parser, .Int8)
        append(&parser.stmts, Instr{.Binary, BinaryInstr{.MoveRegInt, reg, value}})
    case .ADDB:
        reg := parser_expect_register(parser)
        parser_expect_current(parser, .Comma)
        value := parser_expect_int(parser, .Int8)
        append(&parser.stmts, Instr{.Binary, BinaryInstr{.AddRegInt, reg, value}})
    case .DRW:
        regx := parser_expect_current(parser, .Int4)
        parser_expect_current(parser, .Comma)
        regy := parser_expect_current(parser, .Int4)
        parser_expect_current(parser, .Comma)
        height := parser_expect_current(parser, .Int4)
        
        append(&parser.stmts, Instr{.Ternary, TernaryInstr{.Draw, regx.(u8), regy.(u8), height.(u8)}})
    case .EOF:
    case:
        fmt.println("unexpected token", token)
    }
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

parser_add_instr :: proc(parser: ^Parser, instr: Instr) {
    append(&parser.stmts, instr)
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
        line, col := get_line_and_col(parser.src, token.span.lo)
        fmt.printfln("error at %d:%d: expected %v but got %v", line, col, expect_type, token.type)
        os.exit(1)
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
