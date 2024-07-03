package asmb

import "core:fmt"
import "core:os"

main :: proc() {
    if len(os.args) == 2 {
        fmt.println("give an input and output path")
        os.exit(1)
    }

    input_path := os.args[1]
    input, input_ok := os.read_entire_file(input_path)

    if !input_ok {
        fmt.println("could not read input file")
        os.exit(1)
    }

    lexer := lexer_new(input)
    lexer_scan(&lexer)

    // for token in lexer.tokens {
    //     if int(token.type) >= 100 {
    //         fmt.print("\n", token.type)
    //     } else if token.value == nil {
    //         fmt.print("", token.type)
    //     } else {
    //         fmt.printf(" %v(%v)", token.type, token.value)
    //     }
    // }

    parser := parser_new(input_path, string(input), lexer.tokens[:])
    parser_parse(&parser)

    // for stmt in parser.stmts {
    //     fmt.println(stmt)
    // }

    data := interp(parser.stmts[:])
    fmt.printfln("%2X", data)

    os.write_entire_file("roms/myibm.ch8", data)
}
