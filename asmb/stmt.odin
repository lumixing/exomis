package asmb

Stmt :: union {
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

Meta :: struct {
    type: MetaType,
    value: union {
        DataMeta,
        AliasMeta,
        LabelMeta,
    },
}

MetaType :: enum {
    Data,
    Alias,
    Label,
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
