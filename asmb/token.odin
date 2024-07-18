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
	ALIAS,
	LABEL,
	Dollar = 100,
	
	CLS,
	RET,
	JMP,
	CALL,
	SEB,
	SNEB,
	SER,
	MVB,
	ADDB,
	MVR,
	AND,
	OR,
	XOR,
	ADDR,
	SUB,
	SHR,
	SUBN,
	SHL,
	SNER,
	MVI,
	JMPR,
	RND,
	DRW,
	SKP,
	SKNP,
	MVRD,
	WAIT,
	MVDT,
	MVST,
	ADDI,
	SPR,
	BCD,
	SAVE,
	LOAD,
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
