package hexdiff

import "core:os"
import "core:fmt"

main :: proc() {
    if len(os.args) == 2 {
        fmt.println("provide 2 input files")
        os.exit(1)
    }

    first_path := os.args[1]
    second_path := os.args[2]

    first, first_ok := os.read_entire_file(first_path)
    if !first_ok {
        fmt.println("could not read first file")
        os.exit(1)
    }

    second, second_ok := os.read_entire_file(second_path)
    if !second_ok {
        fmt.println("could not read second file")
        os.exit(1)
    }

    big := first
    big_path := first_path
    small := second
    small_path := second_path
    
    if len(first) < len(second) {
        big = second
        big_path = second_path
        small = first
        small_path = first_path
    }

    fmt.printf("%s (%d bytes)", big_path, len(big))
    for b, i in big {
        if i % 16 == 0 {
            fmt.printf("\n0x%3X: ", 0x200 + i)
        }
    
        color: string
        if i < len(small) {
            if b != small[i] {
                color = "\u001b[31m"
            }
        } else {
            color = "\u001b[35m"
        }
        space := i % 2 == 1 ? " " : ""
        fmt.printf("%s%2X\e[0m%s", color, b, space)
    }

    fmt.printf("\n\n")
    fmt.printf("%s (%d bytes)", small_path, len(small))
    
    for b, i in small {
        if i % 16 == 0 {
            fmt.printf("\n0x%3X: ", 0x200 + i)
        }

        color: string
        if b != big[i] {
            color = "\u001b[31m"
        }
        space := i % 2 == 1 ? " " : ""
        fmt.printf("%s%2X\e[0m%s", color, b, space)
    }
}
