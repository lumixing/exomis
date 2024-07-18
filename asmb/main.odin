package asmb

import "core:os"
import "core:fmt"
import "core:flags"

Args :: struct {
	input:       os.Handle `args:"pos=0,required,file=r" usage:".asm input file"`,
	output:      os.Handle `args:"pos=1,required,file=wc" usage:".ch8 output file"`,
	show_data:   bool      `args:"name=data" usage:"show data at end"`,
	show_tokens: bool      `args:"name=token" usage:"show tokens at end"`,
	show_stmts:  bool      `args:"name=stmt" usage:"show statements at end"`,
}

main :: proc() {
	args: Args
	flags.parse_or_exit(&args, os.args)

	input, input_ok := os.read_entire_file(args.input)
	if !input_ok {
		fmt.println("could not read input asm! (invalid path?)")
		os.exit(1)
	}

	lexer := lexer_new(input)
	lexer_scan(&lexer)

	if args.show_tokens {
		for token in lexer.tokens {
			if int(token.type) >= 100 {
				fmt.print("\n", token.type)
			} else if token.value == nil {
				fmt.print("", token.type)
			} else {
				fmt.printf(" %v(%v)", token.type, token.value)
			}
		}
	}

	parser := parser_new(string(input), lexer.tokens[:])
	parser_parse(&parser)

	if args.show_stmts {
		for stmt in parser.stmts {
			fmt.println(stmt)
		}
	}

	data := interp(string(input), parser.stmts[:])

	if args.show_data {
		fmt.printfln("%2X", data)
	}

	_, output_err := os.write(args.output, data)

	if output_err != os.ERROR_NONE {
		fmt.println("could not write to output file")
		os.exit(1)
	}

	fmt.printfln("successfully wrote %d bytes", len(data))
}
