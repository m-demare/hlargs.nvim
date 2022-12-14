package main

import "fmt"

type str struct {
    arg1 string
}

func (s *str) method() string {
    return s.arg1
}

func f1(arg1 string, asd ...int) {
    s := str{
        arg1: arg1,
        asd: asd,
    }
    s.arg1 = "arg1"
}

func main() {
    var a = "world"
    fmt.Println("hello", a)

    go func(msg string) {
        fmt.Println(msg)
    }("going")
}

