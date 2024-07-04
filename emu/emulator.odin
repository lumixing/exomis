package emu

import "core:fmt"
import "core:os"
import intr "base:intrinsics"
import "core:math"
import "core:math/rand"

WIDTH :: 64
HEIGHT :: 32
RAM_SIZE :: 4096
START_ADDR :: 0x200

FONTSET := []u8{
    0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
    0x20, 0x60, 0x20, 0x20, 0x70, // 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
    0x90, 0x90, 0xF0, 0x10, 0x10, // 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
    0xF0, 0x10, 0x20, 0x40, 0x40, // 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, // A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
    0xF0, 0x80, 0x80, 0x80, 0xF0, // C
    0xE0, 0x90, 0x90, 0x90, 0xE0, // D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
    0xF0, 0x80, 0xF0, 0x80, 0x80, // F
}

Emulator :: struct {
    pc: u16,
    ram: [4096]u8,
    screen: [WIDTH * HEIGHT]bool,
    v_reg: [16]u8,
    i_reg: u16,
    sp: u16,
    stack: [16]u16,
    keys: [16]bool,
    dt: u8,
    st: u8,
}

emu_new :: proc() -> Emulator {
    emu: Emulator
    emu.pc = 0x200

    for byte, i in FONTSET {
        emu.ram[i] = byte
    }
    
    return emu
}

emu_load :: proc(emu: ^Emulator, rom: []byte) {
    MAX_SIZE :: RAM_SIZE - 1 - START_ADDR
    if len(rom) > MAX_SIZE {
        fmt.printfln("could not load rom, too big! (%d over %d)", len(rom), MAX_SIZE)
        os.exit(1)
    }

    for byte, i in rom {
        emu.ram[START_ADDR + i] = byte
    }
}

emu_tick :: proc(emu: ^Emulator) {
    if emu.dt > 0 {
        emu.dt -= 1
    }

    if emu.st > 0 {
        if emu.st == 1 {
            // beep!
        }
        emu.st -= 1
    }
}

emu_execute :: proc(emu: ^Emulator) {
    hi := emu.ram[emu.pc]
    lo := emu.ram[emu.pc + 1]
    op := (u16(hi) << 8) | u16(lo)
    fmt.printfln("%4X", op)
    emu.pc += 2

    d1 := (op & 0xF000) >> 12
    x := (op & 0x0F00) >> 8
    y := (op & 0x00F0) >> 4
    n := (op & 0x000F)

    nnn := op & 0xFFF
    nn := u8(op) & 0xFF

    switch d1 {
    case 0x0:
        switch nn {
        case 0x00: // NOP
            return
        case 0xEE: // RET
            emu.sp -= 1
            emu.pc = emu.stack[emu.sp]
        case 0xE0: // CLS
            emu.screen = {}
        }
    case 0x1: // JMP
        emu.pc = nnn
    case 0x2: // CALL nnn
        emu.stack[emu.sp] = emu.pc
        emu.sp += 1
        emu.pc = nnn
    case 0x3: // SE x,nn
        if emu.v_reg[x] == nn {
            emu.pc += 2
        }
    case 0x4: // SNE x,nn
        if emu.v_reg[x] != nn {
            emu.pc += 2
        }
    case 0x5: // SE x,y
        if emu.v_reg[x] == emu.v_reg[y] && n == 0 {
            emu.pc += 2
        }
    case 0x6: // MOV x,nn
        emu.v_reg[x] = nn
    case 0x7: // ADD x,nn
        emu.v_reg[x] += nn
    case 0x8:
        switch n {
        case 0x0: // MOV x,y
            emu.v_reg[x] = emu.v_reg[y]
        case 0x1: // OR x,y
            emu.v_reg[x] |= emu.v_reg[y]
        case 0x2: // AND x,y
            emu.v_reg[x] &= emu.v_reg[y]
        case 0x3: // XOR x,y
            emu.v_reg[x] ~= emu.v_reg[y]
        case 0x4: // ADD x,y
            vx, carry := intr.overflow_add(emu.v_reg[x], emu.v_reg[y])
            emu.v_reg[x] = vx
            emu.v_reg[0xF] = u8(carry)
        case 0x5: // SUB x,y
            vx, carry := intr.overflow_sub(emu.v_reg[x], emu.v_reg[y])
            emu.v_reg[x] = vx
            emu.v_reg[0xF] = u8(!carry)
        case 0x6: // SHR x
            lsb := emu.v_reg[x] & 1
            emu.v_reg[x] >>= 1
            emu.v_reg[0xF] = lsb
        case 0x7: // SUBN x,y
            vx, carry := intr.overflow_sub(emu.v_reg[y], emu.v_reg[x])
            emu.v_reg[x] = vx
            emu.v_reg[0xF] = u8(!carry)
        case 0xE: // SHL x
            msb := (emu.v_reg[x] >> 7) & 1
            emu.v_reg[x] <<= 1
            emu.v_reg[0xF] = msb
        }
    case 0x9: // SNE x,y
        if emu.v_reg[x] != emu.v_reg[y] && n == 0{
            emu.pc += 2
        }
    case 0xA: // MOV i,nnn
        emu.i_reg = nnn
    case 0xB: // JMPR nnn
        emu.pc = nnn + u16(emu.v_reg[0])
    case 0xC: // RND x,nn
        emu.v_reg[x] = u8(rand.uint32()) & nn
    case 0xD: // DRW x,y,n
        cx := u16(emu.v_reg[x])
        cy := u16(emu.v_reg[y])
        flipped := false

        for ly in 0..<n {
            ly := u16(ly)
            addr := emu.i_reg + u16(ly)
            pixels := emu.ram[addr]

            for lx in 0..<8 {
                lx := u16(lx)
                if (pixels & (0b1000_0000 >> lx)) != 0 {
                    px := (cx + lx) % WIDTH
                    py := (cy + ly) % HEIGHT
                    lin := px + py * WIDTH

                    flipped |= emu.screen[lin]
                    emu.screen[lin] ~= true
                }
            }
        }

        emu.v_reg[0xF] = u8(flipped)
    case 0xE:
        switch nn {
        case 0x9E: // SKP x
            if emu.keys[emu.v_reg[x]] {
                emu.pc += 2
            }
        case 0xA1: // SKNP x
            if !emu.keys[emu.v_reg[x]] {
                emu.pc += 2
            }
        }
    case 0xF:
        switch nn {
        case 0x07: // MOV x,dt
            emu.v_reg[x] = emu.dt
        case 0x0A: // WAIT x,key
            pressed := false
            for key, i in emu.keys {
                if key {
                    emu.v_reg[x] = u8(i)
                    pressed = true
                    break
                }
            }
            if !pressed {
                emu.pc -= 2
            }
        case 0x15: // MOV dt,x
            emu.dt = emu.v_reg[x]
        case 0x18: // MOV st,x
            emu.st = emu.v_reg[x]
        case 0x1E: // ADD i,x
            emu.i_reg += u16(emu.v_reg[x])
        case 0x29: // SPR x
            emu.i_reg = u16(emu.v_reg[x]) * 5
        case 0x33: // BCD x
            vx := f32(emu.v_reg[x])
            hund := u8(math.floor(vx / 100))
            tens := u8(math.floor(f32(int(vx / 10) % 10))) // wtf???
            ones := u8(int(vx) % 10)

            i := emu.i_reg
            emu.ram[i] = hund
            emu.ram[i + 1] = tens
            emu.ram[i + 2] = ones
        case 0x55: // STORE x
            for idx in 0..=x {
                emu.ram[emu.i_reg + idx] = emu.v_reg[idx]
            }
        case 0x65: // LOAD x
            for idx in 0..=x {
                emu.v_reg[idx] = emu.ram[emu.i_reg + idx]
            }
        }
    case:
        fmt.printfln("invalid instruction: %4X", op)
    }
}
