package asmb

import "core:fmt"
import "core:strings"
import "core:unicode"
import "core:strconv"

Lexer :: struct {
    src: []byte,
    tokens: [dynamic]Token,
    start: int,
    current: int,
}

lexer_new :: proc(src: []byte) -> Lexer {
    lexer: Lexer
    lexer.src = src
    return lexer
}

lexer_scan :: proc(lexer: ^Lexer) {
    for !lexer_end(lexer^) {
        lexer.start = lexer.current
        lexer_scan_token(lexer)
    }

    lexer_add(lexer, .EOF)
}

lexer_scan_token :: proc(lexer: ^Lexer) {
    char := lexer_advance(lexer)

    switch char {
    case ' ', '\r', '\t', '\n':
        // lexer_whitespace()
    case ';':
        lexer_comment(lexer)
    case ',':
        lexer_add(lexer, .Comma)
    case '$':
        lexer_add(lexer, .Dollar)
    case:
        if unicode.is_digit(char) {
            lexer_int(lexer)
        } else if unicode.is_alpha(char) {
            lexer_ident(lexer)
        } else {
            fmt.printfln("invalid character %c at %d", char, lexer.current)
        }
    }
}

lexer_int :: proc(lexer: ^Lexer) {
    for unicode.is_digit(lexer_peek(lexer^)) {
        lexer_advance(lexer)
    }

    str := string(lexer.src[lexer.start:lexer.current])
    value, ok := strconv.parse_int(str)
    
    if !ok {
        fmt.printfln("could not parse int at %d", lexer.start)
    }

    if value == 0 && unicode.to_lower(lexer_peek(lexer^)) == 'x' {
        lexer_advance(lexer)

        for is_hex(lexer_peek(lexer^)) {
            lexer_advance(lexer)
        }

        hstr := string(lexer.src[lexer.start:lexer.current])
        value, ok = strconv.parse_int(hstr)
        
        if !ok {
            fmt.printfln("could not parse hex int at %d", lexer.start)
        }
    }

    if value >= 0 && value < 16 {
        lexer_add(lexer, .Int4, u8(value))
    } else if value >= 0 && value < 256 {
        lexer_add(lexer, .Int8, u8(value))
    } else if value >= 0 && value < 65636 {
        lexer_add(lexer, .Int16, u16(value))
    } else {
        fmt.printfln("integer %d is out of range at %d", value, lexer.start)
    }
}

lexer_ident :: proc(lexer: ^Lexer) {
    for unicode.is_alpha(lexer_peek(lexer^)) {
        lexer_advance(lexer)
    }

    str := string(lexer.src[lexer.start:lexer.current])

    switch strings.to_lower(str) {
    case "cls":  lexer_add(lexer, .CLS)
    case "ret":  lexer_add(lexer, .RET)
    case "jmp":  lexer_add(lexer, .JMP)
    case "call": lexer_add(lexer, .CALL)
    case "seb":  lexer_add(lexer, .SEB)
    case "sneb": lexer_add(lexer, .SNEB)
    case "ser":  lexer_add(lexer, .SER)
    case "mvb":  lexer_add(lexer, .MVB)
    case "addb": lexer_add(lexer, .ADDB)
    case "mvr":  lexer_add(lexer, .MVR)
    case "and":  lexer_add(lexer, .AND)
    case "or":   lexer_add(lexer, .OR)
    case "xor":  lexer_add(lexer, .XOR)
    case "addr": lexer_add(lexer, .ADDR)
    case "sub":  lexer_add(lexer, .SUB)
    case "shr":  lexer_add(lexer, .SHR)
    case "subn": lexer_add(lexer, .SUBN)
    case "shl":  lexer_add(lexer, .SHL)
    case "sner": lexer_add(lexer, .SNER)
    case "mvi":  lexer_add(lexer, .MVI)
    case "jmpr": lexer_add(lexer, .JMPR)
    case "rnd":  lexer_add(lexer, .RND)
    case "drw":  lexer_add(lexer, .DRW)
    case "skp":  lexer_add(lexer, .SKP)
    case "sknp": lexer_add(lexer, .SKNP)
    case "mvrd": lexer_add(lexer, .MVRD)
    case "wait": lexer_add(lexer, .WAIT)
    case "mvdt": lexer_add(lexer, .MVDT)
    case "mvst": lexer_add(lexer, .MVST)
    case "addi": lexer_add(lexer, .ADDI)
    case "spr":  lexer_add(lexer, .SPR)
    case "bcd":  lexer_add(lexer, .BCD)
    case "save": lexer_add(lexer, .SAVE)
    case "load": lexer_add(lexer, .LOAD)
    case "data": lexer_add(lexer, .DATA)
    case "alias": lexer_add(lexer, .ALIAS)
    case "label": lexer_add(lexer, .LABEL)
    case: lexer_add(lexer, .Ident, str)
    }
}

lexer_comment :: proc(lexer: ^Lexer) {
    for lexer_peek(lexer^) != '\n' && !lexer_end(lexer^) {
        lexer_advance(lexer)
    }

    // lexer_add(lexer, .Comment)
}

lexer_peek :: proc(lexer: Lexer) -> rune {
    if lexer_end(lexer) {
        return 0
    }
    return rune(lexer.src[lexer.current])
}

lexer_advance :: proc(lexer: ^Lexer) -> rune {
    defer lexer.current += 1
    return rune(lexer.src[lexer.current])
}

lexer_add :: proc(lexer: ^Lexer, type: TokenType, value: TokenValue = nil) {
    span := Span{lexer.start, lexer.current}
    append(&lexer.tokens, Token{type, value, span})
}

lexer_end :: proc(lexer: Lexer) -> bool {
    return lexer.current >= len(lexer.src)
}

is_hex :: proc(c: rune) -> bool {
	return unicode.is_digit(c) || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')
}
