package asmb

Token :: struct {
    type: TokenType,
    value: TokenValue,
    span: Span,
}

TokenType :: enum {
    Whitespace,
    Comment,
    EOF,

    Comma,

    Ident,
    Int4,
    Int8,
    Int16,
    
    DATA,
    Dollar = 100,
    
    CLS,
    MVI,
    MVB,
    DRW,
    ADDB,
    JMP,
}

TokenValue :: union {
    string,
    u8,
    u16,
}

Span :: struct {
    lo: int,
    hi: int,
}
