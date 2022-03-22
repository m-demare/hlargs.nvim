function! Func(arg0, arg1)
    echo a:arg1 + a:arg0
    echo b:arg1 + w:arg1 + t:arg1 + g:arg1 + l:arg1 + s:arg1 + v:arg1 + a:arg1
    let AddArg0 = {a,b -> a:arg0 + b}
    echo Add(1, 2)
endfunction

