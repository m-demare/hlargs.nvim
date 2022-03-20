
fn main() {
    println!("Hello World!");
    let lambda = |i: i32| -> i32 { i + 1 };
}

fn is_divisible_by(lhs: u32, rhs: u32) -> bool {
    if rhs == 0 {
        return false;
    }

    lhs % rhs == 0
}

fn fizzbuzz(n: u32) -> () {
    if is_divisible_by(n, 15) {
        println!("fizzbuzz");
    } else if is_divisible_by(n, 3) {
        println!("fizz");
    } else if is_divisible_by(n, 5) {
        println!("buzz");
    } else {
        println!("{}", n);
    }
}

struct Point {
    x: f64,
    y: f64,
    arg: u32
}

impl Point {
    fn new(x: f64, y: f64, arg: Point) -> Point {
        // TODO this is a bit of an edge case, but for some reason,
        // the second `arg` is both a `field_identifier` and an `identifier`
        // It may have to do with the fact that println is a macro? It
        // doesn't happen with the Point constructor
        println!("{}", arg.arg);
        Point { x: x, y: y, arg: arg.arg}
    }
}

fn fizzbuzz_to(n: u32) {
    for n in 1..=n {
        fizzbuzz(n);
    }
}

