function fn(arg0)
  print(arg0, arg1)
  function fn2(arg1)
    local var = arg0 + arg1.arg0
  end
end

function fn2(mode)
  mode = hello
  local table = { mode = {} }
  table.mode[mode] = "world"
end
