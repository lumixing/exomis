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
    case "mvi":  lexer_add(lexer, .MVI)
    case "mvb":  lexer_add(lexer, .MVB)
    case "drw":  lexer_add(lexer, .DRW)
    case "addb": lexer_add(lexer, .ADDB)
    case "jmp":  lexer_add(lexer, .JMP)
    case "data": lexer_add(lexer, .DATA)
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
