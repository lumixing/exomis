package asmb

Props :: struct {
    pc: u16,
    data: [dynamic]byte,
}

interp :: proc(stmts: []Stmt) -> []byte {
    props: Props
    
    for stmt in stmts {
        switch s in stmt {
        case Instr:
            props.pc += 2
            switch v in s.value {
            case NullaryInstr:
                switch v.type {
                case .Clear:
                    append(&props.data, ..[]u8{0x00, 0xE0})
                }
            case UnaryInstr:
                switch v.type {
                case .JumpInt:
                    hi, lo := u16_hi_lo(v.value.(u16))
                    append(&props.data, ..[]u8{0x10 + hi, lo})
                case .MoveIRegInt:
                    hi, lo := u16_hi_lo(v.value.(u16))
                    append(&props.data, ..[]u8{0xA0 + hi, lo})
                }
            case BinaryInstr:
                switch v.type {
                case .MoveRegInt:
                    append(&props.data, ..[]u8{0x60 + v.first.(u8), v.second.(u8)})
                case .AddRegInt:
                    append(&props.data, ..[]u8{0x70 + v.first.(u8), v.second.(u8)})
                }
            case TernaryInstr:
                switch v.type {
                case .Draw:
                    hi := 0xD0 + v.first.(u8)
                    lo := (v.second.(u8) << 4) + v.third.(u8)
                    append(&props.data, ..[]u8{hi, lo})
                }
            }
        case Meta:
            switch v in s.value {
            case DataMeta:
                append(&props.data, ..v.data)
            }
        }
    }

    return props.data[:]
}

u16_hi_lo :: proc(n: u16) -> (hi, lo: u8) {
    hi = u8(((n & 0xF00) >> 8))
    lo = u8(n & 0x0FF)
    return
}
