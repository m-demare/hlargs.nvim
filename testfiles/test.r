# Normal functions
fn1 <- function(arg1) return(arg1)

fn2 = function(arg1) return(arg1)  # can use `=` of `<-` as assignment operator

fn3 <- function(arg1) {
  arg1
}

fn4 = function(df, col) {
  print(df$col)
}

fn5 <- function (arg1) return    (arg1)  # arbitrary spaces between func def and parens

fn6 <- function(arg1, arg2 = 5) {
  return(abs(arg1) + abs(arg2))
}

fn6(5, arg2 = 8)

fn7 <- function(arg1, arg2 = 5) {
  subfn <- function(subarg1) {
    arg1 + subarg1
  }
  out <- abs(subfn(8)) + abs(arg2)
  out
}

fn8 <- function(f) {
  f(26)
}

fn9 <- function(l, i) {
  return(l[[i]])
}

# Lambdas
lam1 <- \(arg1) print(arg1)

lam2 <- \(arg1, arg2) {
  return(arg1 ^ arg2)
}
