package emu

import "core:os"
import "core:fmt"
import "core:flags"
import "core:unicode/utf8"
import rl "vendor:raylib"
import mu "vendor:microui"

RATE :: 500
SCALE :: 8
KEYS :: []rl.KeyboardKey{
    .X, .ONE, .TWO, .THREE,
    .Q, .W, .E, .A,
    .S, .D, .Z, .C,
    .FOUR, .R, .F, .V,
}
freeze: bool

state := struct {
	mu_ctx: mu.Context,
log_buf:         [1<<16]byte,
	log_buf_len:     int,
	log_buf_updated: bool,
	bg: mu.Color,
	
	atlas_texture: rl.Texture2D,
}{
	bg = {90, 95, 100, 255},
}

Args :: struct {
	input: os.Handle `args:"pos=0,required,file=r" usage:".ch8 rom file"`,
	rate: i32 `args:"pos=1" usage:"framerate (default=500)"`,
	freeze: bool `usage:"freeze on start (default=false)"`,
}

emu: Emulator

main :: proc() {
 	args: Args
 	args.rate = 500
 	// style: flags.Parsing_Style = .Odin
 	flags.parse_or_exit(&args, os.args, .Odin)
 	
 	freeze = args.freeze
    rom, rom_ok := os.read_entire_file(args.input)
    if !rom_ok {
        fmt.println("could not read rom! (invalid path?)")
        os.exit(1)
    }
    
    rl.SetTraceLogLevel(.WARNING)
    rl.InitWindow(1280, 720, "exomis")
    defer rl.CloseWindow()
    rl.SetTargetFPS(args.rate)

    emu = emu_new()
    emu_load(&emu, rom)

    timer: f32	
    
	pixels := make([][4]u8, mu.DEFAULT_ATLAS_WIDTH*mu.DEFAULT_ATLAS_HEIGHT)
	for alpha, i in mu.default_atlas_alpha {
		pixels[i] = {0xff, 0xff, 0xff, alpha}
	}
	defer delete(pixels)
		
	image := rl.Image{
		data = raw_data(pixels),
		width   = mu.DEFAULT_ATLAS_WIDTH,
		height  = mu.DEFAULT_ATLAS_HEIGHT,
		mipmaps = 1,
		format  = .UNCOMPRESSED_R8G8B8A8,
	}
	state.atlas_texture = rl.LoadTextureFromImage(image)
	defer rl.UnloadTexture(state.atlas_texture)
		
	ctx := &state.mu_ctx
	mu.init(ctx)
	
	ctx.text_width = mu.default_atlas_text_width
	ctx.text_height = mu.default_atlas_text_height
	
	main_loop: for !rl.WindowShouldClose() {
		if freeze {
			if rl.IsKeyPressed(.SPACE) {
            	emu_execute(&emu)
            }
        } else {
	        timer += rl.GetFrameTime()
	        if timer > 1 / RATE {
	            emu_execute(&emu)
	            emu_tick(&emu)
	            timer = 0
	        }
	    }

        for key, i in KEYS {
            if rl.IsKeyDown(key) {
                emu.keys[i] = true
            }
            if rl.IsKeyReleased(key) {
                emu.keys[i] = false
            }
        }
		
		{ // text input
			text_input: [512]byte = ---
			text_input_offset := 0
			for text_input_offset < len(text_input) {
				ch := rl.GetCharPressed()
				if ch == 0 {
					break
				}
				b, w := utf8.encode_rune(ch)
				copy(text_input[text_input_offset:], b[:w])
				text_input_offset += w
			}
			mu.input_text(ctx, string(text_input[:text_input_offset]))
		}
		
		// mouse coordinates
		mouse_pos := [2]i32{rl.GetMouseX(), rl.GetMouseY()}
		mu.input_mouse_move(ctx, mouse_pos.x, mouse_pos.y)
		mu.input_scroll(ctx, 0, i32(rl.GetMouseWheelMove() * -30))
		
		// mouse buttons
		@static buttons_to_key := [?]struct{
			rl_button: rl.MouseButton,
			mu_button: mu.Mouse,
		}{
			{.LEFT, .LEFT},
			{.RIGHT, .RIGHT},
			{.MIDDLE, .MIDDLE},
		}
		for button in buttons_to_key {
			if rl.IsMouseButtonPressed(button.rl_button) { 
				mu.input_mouse_down(ctx, mouse_pos.x, mouse_pos.y, button.mu_button)
			} else if rl.IsMouseButtonReleased(button.rl_button) { 
				mu.input_mouse_up(ctx, mouse_pos.x, mouse_pos.y, button.mu_button)
			}
			
		}
		
		// keyboard
		@static keys_to_check := [?]struct{
			rl_key: rl.KeyboardKey,
			mu_key: mu.Key,
		}{
			{.LEFT_SHIFT,    .SHIFT},
			{.RIGHT_SHIFT,   .SHIFT},
			{.LEFT_CONTROL,  .CTRL},
			{.RIGHT_CONTROL, .CTRL},
			{.LEFT_ALT,      .ALT},
			{.RIGHT_ALT,     .ALT},
			{.ENTER,         .RETURN},
			{.KP_ENTER,      .RETURN},
			{.BACKSPACE,     .BACKSPACE},
		}
		for key in keys_to_check {
			if rl.IsKeyPressed(key.rl_key) {
				mu.input_key_down(ctx, key.mu_key)
			} else if rl.IsKeyReleased(key.rl_key) {
				mu.input_key_up(ctx, key.mu_key)
			}
		}
		
		mu.begin(ctx)
		all_windows(ctx)
		mu.end(ctx)
		
		render(ctx)
	}
}

render :: proc(ctx: ^mu.Context) {
	render_texture :: proc(rect: mu.Rect, pos: [2]i32, color: mu.Color) {
		source := rl.Rectangle{
			f32(rect.x),
			f32(rect.y),
			f32(rect.w),
			f32(rect.h),
		}
		position := rl.Vector2{f32(pos.x), f32(pos.y)}
		
		rl.DrawTextureRec(state.atlas_texture, source, position, transmute(rl.Color)color)
	}
	
	rl.ClearBackground(transmute(rl.Color)state.bg)
	
	rl.BeginDrawing()
	defer rl.EndDrawing()
	
	rl.BeginScissorMode(0, 0, rl.GetScreenWidth(), rl.GetScreenHeight())
	// defer rl.EndScissorMode()
	
	command_backing: ^mu.Command
	for variant in mu.next_command_iterator(ctx, &command_backing) {
		switch cmd in variant {
		case ^mu.Command_Text:
			pos := [2]i32{cmd.pos.x, cmd.pos.y}
			for ch in cmd.str do if ch&0xc0 != 0x80 {
				r := min(int(ch), 127)
				rect := mu.default_atlas[mu.DEFAULT_ATLAS_FONT + r]
				render_texture(rect, pos, cmd.color)
				pos.x += rect.w
			}
		case ^mu.Command_Rect:
			rl.DrawRectangle(cmd.rect.x, cmd.rect.y, cmd.rect.w, cmd.rect.h, transmute(rl.Color)cmd.color)
		case ^mu.Command_Icon:
			rect := mu.default_atlas[cmd.id]
			x := cmd.rect.x + (cmd.rect.w - rect.w)/2
			y := cmd.rect.y + (cmd.rect.h - rect.h)/2
			render_texture(rect, {x, y}, cmd.color)
		case ^mu.Command_Clip:
			rl.EndScissorMode()
			rl.BeginScissorMode(cmd.rect.x, cmd.rect.y, cmd.rect.w, cmd.rect.h)
		case ^mu.Command_Jump: 
			unreachable()
		}
	}

    rl.EndScissorMode()

	rl.BeginScissorMode(screen_rect.x, screen_rect.y + 24, screen_rect.w, screen_rect.h - 24)
	defer rl.EndScissorMode()

    rl.ClearBackground(rl.BLACK)
	// rl.DrawText("drawn text!!!!!!!!!", screen_rect.x, screen_rect.y + 24, 20, rl.GREEN)
	for pixel, i in emu.screen {
        if !pixel do continue
        
        x := i % WIDTH
        y := i / WIDTH

        rl.DrawRectangle(i32(x) * SCALE + screen_rect.x, i32(y) * SCALE + screen_rect.y + 24, SCALE, SCALE, rl.WHITE)
    }
}

screen_rect: mu.Rect
v: mu.Real

all_windows :: proc(ctx: ^mu.Context) {
	@static opts := mu.Options{.NO_CLOSE, .NO_RESIZE}
	
    if mu.window(ctx, "screen", {8, 8, 64*8, 32*8+24}, opts) {
        win := mu.get_current_container(ctx)
        screen_rect = win.rect
    }

    if mu.window(ctx, "registers", {8, 8+32*8+24+8, 256-4, 256-32}, opts) {
    	mu.layout_row(ctx, {24, 24, 64, 24, 24, 32})
    	for b, i in emu.v_reg {
    		mu.text(ctx, fmt.tprintf("v%d:", i))
    		mu.text(ctx, fmt.tprintf("%d", b))
    		mu.text(ctx, fmt.tprintf("(0x%2X)", b))
    	}
    }
	
    if mu.window(ctx, "emulator", {8+256+8-4, 8+32*8+24+8, 256-4, 256-32}, opts) {
		mu.text(ctx, fmt.tprintf("pc: %d (0x%2X)", emu.pc, emu.pc))
		mu.text(ctx, fmt.tprintf("ireg: %d (0x%2X)", emu.i_reg, emu.i_reg))
        mu.button(ctx, "reset")
        if .SUBMIT in mu.button(ctx, "toggle freeze") {
        	freeze = !freeze
        }
    }

    if mu.window(ctx, "memory", {8+64*8+8, 8, 256+16, 512}, opts) {
    	// mu.layout_width(ctx, 1000)
		// mu.layout_row(ctx, {32,8,14,8,14,8,14,8,14,8,14,8,14,8,14,8,14,})
		mu.layout_row(ctx, {8,14,8,14, 8,14,8,14, 8,14,8,14, 8,14,8,14,})
		for b, i in emu.ram {
			// if i % 16 == 0 {
			// 	mu.text(ctx, fmt.tprintf("0x%3X", i))
			// }

			mu.text(ctx, fmt.tprintf("%2X", b))
		}
    }
}
