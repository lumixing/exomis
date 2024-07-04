package asmb

import "core:fmt"
import "core:os"

Props :: struct {
    pc: u16,
    data: [dynamic]byte,
    alias: map[string]u16,
}

interp :: proc(stmts: []Stmt) -> []byte {
    props: Props
    props.pc = 0x200

    // label pass
    for stmt in stmts {
        switch s in stmt {
        case Instr:
            props.pc += 2
        case Meta:
            #partial switch v in s.value {
            case DataMeta:
                props.pc += u16(len(v.data))
            case LabelMeta:
                props.alias[v.name] = props.pc
            }
        }
    }

    props.pc = 0x200
    
    for stmt in stmts {
        switch s in stmt {
        case Instr:
            defer props.pc += 2
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
                case .JumpLabel:
                    value := get_alias(props, v.value.(string))
                    hi, lo := u16_hi_lo(value)
                    append(&props.data, ..[]u8{0x10 + hi, lo})
                case .MoveIRegInt:
                    hi, lo := u16_hi_lo(v.value.(u16))
                    append(&props.data, ..[]u8{0xA0 + hi, lo})
                case .MoveIRegAlias:
                    if value, ok := props.alias[v.value.(string)]; ok {
                        hi, lo := u16_hi_lo(value)
                        append(&props.data, ..[]u8{0xA0 + hi, lo})
                    } else {
                        fmt.println("alias does not exist!")
                    }
                }
            case BinaryInstr:
                switch v.type {
                case .MoveRegInt:
                    reg := reg_or_alias(props, v.first)
                    value := int8_or_alias(props, v.second)
                    append(&props.data, ..[]u8{0x60 + reg, value})
                case .AddRegInt:
                    reg := reg_or_alias(props, v.first)
                    value := int8_or_alias(props, v.second)
                    append(&props.data, ..[]u8{0x70 + reg, value})
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
                props.pc += u16(len(v.data))
            case AliasMeta:
                props.alias[v.name] = v.value.(u16)
            case LabelMeta:
                // props.alias[v.name] = props.pc
            }
        }
    }

    return props.data[:]
}

get_alias :: proc(props: Props, key: string) -> u16 {
    if value, ok := props.alias[key]; ok {
        return value
    } else {
        fmt.println("alias not found! expand err pls")
        os.exit(1)
    }
}

int8_or_alias :: proc(props: Props, value: Value) -> u8 {
    if v, ok := value.(u8); ok {
        return v
    }

    if v, ok := value.(string); ok {
        return u8_range(get_alias(props, v))
    }

    fmt.println("expected int8 value to be u8 or string!")
    os.exit(1)
}

reg_or_alias :: proc(props: Props, value: Value) -> u8 {
    if v, ok := value.(u8); ok {
        return reg_range(v)
    }

    if v, ok := value.(string); ok {
        return reg_range(get_alias(props, v))
    }

    fmt.println("expected reg value to be u8 or string!")
    os.exit(1)
}

reg_range :: proc(n: $T) -> u8 {
    if n >= 0 && n <= 15 {
        return u8(n)
    } else {
        fmt.println("bro is out of u4 range")
        os.exit(1)
    }
}

u8_range :: proc(n: $T) -> u8 {
    if n >= 0 && n <= 255 {
        return u8(n)
    } else {
        fmt.println("bro is out of u8 range")
        os.exit(1)
    }
}

u16_hi_lo :: proc(n: u16) -> (hi, lo: u8) {
    hi = u8(((n & 0xF00) >> 8))
    lo = u8(n & 0x0FF)
    return
}
