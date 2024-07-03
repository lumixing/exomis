package disasm

import "core:os"
import "core:fmt"

main :: proc() {
    if len(os.args) == 1 {
        fmt.println("provide an input path!")
        os.exit(1)
    }

    input_path := os.args[1]
    input, input_ok := os.read_entire_file(input_path)

    if !input_ok {
        fmt.println("could not read input file!")
        os.exit(1)
    }

    data_tagged: map[int]bool
    i_reg: u16
    
    for i := 0; i < len(input); i += 2 {
        hi := input[i]
        if i + 1 >= len(input) do break
        lo := input[i + 1]

        op := (u16(hi) << 8) | u16(lo)
        d1 := (op & 0xF000) >> 12
        x := (op & 0x0F00) >> 8
        y := (op & 0x00F0) >> 4
        n := (op & 0x000F)
        nnn := op & 0xFFF
        nn := u8(op) & 0xFF

        switch d1 {
        case 0x0:
            switch nnn {
            case 0x00E0, 0x0EE:
            case:
                data_tagged[i] = true
                data_tagged[i + 1] = true
            }
        case 0x5, 0x9:
            switch n {
            case 0:
            case:
                data_tagged[i] = true
                data_tagged[i + 1] = true
            }
        case 0x8:
            switch n {
            case 0x8, 0x9, 0xA, 0xB, 0xC, 0xD, 0xF:
                data_tagged[i] = true
                data_tagged[i + 1] = true
            }
        case 0xA:
            i_reg = nnn
        case 0xD:
            for i in 0..=n {
                data_tagged[int(i_reg) - 0x200 + int(i)] = true
            }
        case 0xE:
            switch nn {
            case 0x9E, 0xA1:
            case:
                data_tagged[i] = true
                data_tagged[i + 1] = true
            }
        case 0xF:
            switch nn {
            case 0x07, 0x0A, 0x15, 0x18, 0x1E, 0x29, 0x33, 0x55, 0x65:
            case:
                data_tagged[i] = true
                data_tagged[i + 1] = true
            }
        }
    }

    for b, i in input {
        // if i in data_tagged {
        //     fmt.print("$ ")            
        // }

        flag := ""
        if i % 2 == 0 && (b & 0xF0 == 0xD0 || b & 0xF0 == 0xA0) do flag = "\033[94m"
        if i in data_tagged do flag = "\033[92m"
        
        if i % 16 == 0 {
            fmt.printf("\n0x%3X ", 0x200 + i)
        }
        fmt.printf("%s%2X\e[0m ", flag, b)
        // fmt.printfln("0x%3X %s 0x%2X\e[0m", 0x200 + i, flag, b)
    }
}
