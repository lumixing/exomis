package asmb

Stmt :: struct {
    type: StmtType,
    span: Span,
}

StmtType :: union {
    Instr,
    Meta,
}

Instr :: struct {
    type: InstrType,
    value: union {
        NullaryInstr,
        UnaryInstr,
        BinaryInstr,
        TernaryInstr,
    },
}

InstrType :: enum {
    Nullary,
    Unary,
    Binary,
    Ternary,
}

Value :: union {
    u8,
    u16,
    string,
}

NullaryInstr :: struct {
    type: NullaryInstrType,
}

NullaryInstrType :: enum {
    Clear,
    Return,
}

UnaryInstr :: struct {
    type: UnaryInstrType,
    value: Value,
}

UnaryInstrType :: enum {
    JumpInt,
    JumpLabel,
    CallInt,
    CallLabel,
    ShiftRight,
    ShiftLeft,
    MoveIRegInt,
    MoveIRegAlias,
}

BinaryInstr :: struct {
    type: BinaryInstrType,
    first: Value,
    second: Value,
}

BinaryInstrType :: enum {
    SkipEqualInt,
    SkipNotEqualInt,
    SkipEqualReg,
    MoveRegInt,
    AddRegInt,
    And,
    Or,
    Xor,
    AddRegReg,
    Sub,
    SubReverse,
    SkipNotEqualReg,
}

TernaryInstr :: struct {
    type: TernaryInstrType,
    first: Value,
    second: Value,
    third: Value,
}

TernaryInstrType :: enum {
    Draw,
}

Meta :: union {
    DataMeta,
    AliasMeta,
    LabelMeta,
}

DataMeta :: struct {
    data: []u8,
}

AliasMeta :: struct {
    name: string,
    value: Value,
}

LabelMeta :: struct {
    name: string,
}
