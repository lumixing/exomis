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
}

UnaryInstr :: struct {
    type: UnaryInstrType,
    value: Value,
}

UnaryInstrType :: enum {
    JumpInt,
    JumpLabel,
    MoveIRegInt,
    MoveIRegAlias,
}

BinaryInstr :: struct {
    type: BinaryInstrType,
    first: Value,
    second: Value,
}

BinaryInstrType :: enum {
    MoveRegInt,
    AddRegInt,
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
