package emu

import "core:fmt"
import "core:os"
import rl "vendor:raylib"

RATE :: 500
SCALE :: 8
KEYS :: []rl.KeyboardKey{
    .X, .ONE, .TWO, .THREE,
    .Q, .W, .E, .A,
    .S, .D, .Z, .C,
    .FOUR, .R, .F, .V,
}

main :: proc() {
    if len(os.args) == 1 {
        fmt.println("give a rom input file!")
        os.exit(1)
    }

    rom_path := os.args[1]
    rom, rom_ok := os.read_entire_file(rom_path)
    if !rom_ok {
        fmt.println("could not read rom! (invalid path?)")
        os.exit(1)
    }
        
    rl.SetTraceLogLevel(.WARNING)
    rl.InitWindow(WIDTH * SCALE, HEIGHT * SCALE, "exomis")
    defer rl.CloseWindow()
    rl.SetTargetFPS(RATE)

    emu := emu_new()
    emu_load(&emu, rom)

    timer: f32

    for !rl.WindowShouldClose() {
        // if rl.IsKeyPressed(.SPACE) {
        //     emu_execute(&emu)
        // }

        for key, i in KEYS {
            if rl.IsKeyDown(key) {
                emu.keys[i] = true
            }
            if rl.IsKeyReleased(key) {
                emu.keys[i] = false
            }
        }

        timer += rl.GetFrameTime()
        if timer > 1 / RATE {
            emu_execute(&emu)
            emu_tick(&emu)
            timer = 0
        }
        
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        for pixel, i in emu.screen {
            if !pixel do continue
            
            x := i % WIDTH
            y := i / WIDTH

            rl.DrawRectangle(i32(x) * SCALE, i32(y) * SCALE, SCALE, SCALE, rl.WHITE)
        }

        rl.DrawFPS(0, 0)
        
        rl.EndDrawing()
    }
}
