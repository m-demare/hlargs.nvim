{
  case1 = x: x + 1;

  case2 = x: y: x + y;

  case3 = { a, b }: a + b;

  case4 = { a, b ? 0 }: a + b;

  case5 = { a, b, ... }: a + b;

  case6 = args@{ a, b, ... }: a + b + args.c;

  case7 = { a, b, ... }@args: a + b + args.c;

  case8 = let f = x: x + 1; in f 1;

  case9 = let f = x: x.a; in f { a = 1; };

  case10 =
    let
      f = x: x.a;
      v = { a = 1; };
    in f v;

  case11 = (x: x + 1) 1;

  case12 =
    let
      f = x: x + 1;
      a = 1;
    in [ (f a) ];

  case13 = x: (y: x + y);

  case14 = arg: arg.arg;

  case15 =
    { pkgs ? import <nixpkgs> {} }:
    let
      message = "hello world";
    in
    pkgs.mkShell {
      buildInputs = with pkgs; [ cowsay ];
      shellHook = ''
        cowsay ${message}
      '';
    };
}
