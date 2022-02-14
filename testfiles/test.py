class Class:
    def __init__(self, arg1, arg2):
        self.arg1 = arg1
        self.arg2 = arg2

        def function2(arg3):  # inner function
            return arg2


var = 10


def fn(arg4):
    global var
    Class(arg4, lambda x: x + arg4 + var)


def fn_typed(arg5: dict[int, str]) -> None:
    if arg5 == var:
        fn_splat_list("", "", "")
    else:
        fn_splat_dict(arg8=var, param=arg5, arg5=arg5)


def fn_splat_list(arg6, *arg7) -> None:
    if arg7 == [var]:
        Class(arg6, lambda *args: args == [var, 15])


def fn_typed_splat_list(arg6: int, *arg7: list[str]) -> None:
    if arg7 == []:
        Class(arg6, lambda *args: args == [var, 25])


def fn_splat_dict(arg8, **arg9) -> None:
    if arg9 == {}:
        Class(arg8, lambda **kwargs: kwargs == {var: "var"})


def fn_typed_splat_dict(arg10: int, **arg11: dict[int, str]) -> None:
    if arg11 == {}:
        Class(arg10, lambda **kwargs: kwargs == {var: "var"})
